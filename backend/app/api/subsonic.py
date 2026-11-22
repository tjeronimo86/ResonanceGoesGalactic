import logging
import uuid
from typing import Any

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import Response
from pydantic import ValidationError
from sqlalchemy import delete, func, or_, select

from app.api import library, me
from app.api import playlists as playlist_api
from app.deps import DB
from app.i18n import language, translate
from app.models import (
    Album,
    Artist,
    Job,
    PlayEvent,
    Playlist,
    PlaylistEntry,
    SavedAlbum,
    Track,
    TrackLike,
    User,
)
from app.schemas import AddTracksIn, PlayEventIn, PlaylistIn, PlaylistPatch
from app.services import search, transcode
from app.services import subsonic as ss
from app.services.lyrics import get_lyrics
from app.services.views import album_options, track_options

router = APIRouter(prefix="/rest", tags=["subsonic"])
log = logging.getLogger(__name__)


def _directories(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [{**row, "title": row["name"], "parent": row["artistId"], "isDir": True} for row in rows]


async def _track(db: DB, value: str) -> Track:
    track = await db.scalar(select(Track).options(*track_options()).where(Track.id == ss.parse_id(value)))
    if track is None:
        raise ss.SubsonicError(70, "Titel nicht gefunden")
    return track


async def _album(db: DB, value: str) -> Album:
    album = await db.scalar(select(Album).options(*album_options()).where(Album.id == ss.parse_id(value)))
    if album is None:
        raise ss.SubsonicError(70, "Album nicht gefunden")
    return album


async def _artist_albums(db: DB, artist_id: uuid.UUID) -> list[Album]:
    return list(
        await db.scalars(
            select(Album)
            .options(*album_options())
            .where(Album.artist_id == artist_id)
            .order_by(Album.year.desc().nulls_last(), Album.title, Album.id)
        )
    )


async def _album_tracks(db: DB, album_id: uuid.UUID) -> list[Track]:
    return list(
        await db.scalars(
            select(Track)
            .options(*track_options())
            .where(Track.album_id == album_id)
            .order_by(*library._track_order(), Track.id)
        )
    )


async def _visible_playlist(db: DB, user: User, value: str, *, owned: bool = False) -> Playlist:
    playlist_id = ss.parse_id(value)
    if owned:
        candidate = await db.get(Playlist, playlist_id)
        if candidate is not None and candidate.kind != "mix" and candidate.owner_id != user.id:
            raise ss.SubsonicError(50, "Nicht deine Playlist")
    playlist = await playlist_api._get_visible(db, user, playlist_id)
    if playlist.kind == "mix":
        raise ss.SubsonicError(70, "Playlist nicht gefunden")
    if owned:
        return await playlist_api._get_owned(db, user, playlist_id)
    return playlist


async def _playlist_detail(db: DB, user: User, playlist: Playlist) -> dict[str, Any]:
    result = (await ss.playlists(db, user, [playlist]))[0]
    tracks = list(
        await db.scalars(
            select(Track)
            .join(PlaylistEntry, PlaylistEntry.track_id == Track.id)
            .options(*track_options())
            .where(PlaylistEntry.playlist_id == playlist.id)
            .order_by(PlaylistEntry.position, PlaylistEntry.id)
        )
    )
    result["entry"] = await ss.songs(db, user, tracks)
    return {"playlist": result}


async def _validate_songs(db: DB, ids: list[uuid.UUID]) -> None:
    if ids:
        AddTracksIn(track_ids=ids)
        known = set(await db.scalars(select(Track.id).where(Track.id.in_(ids))))
        if known != set(ids):
            raise ss.SubsonicError(70, "Titel nicht gefunden")


async def _album_list(db: DB, user: User, params: ss.Params, legacy: bool) -> dict[str, Any]:
    kind = params.require("type")
    query = select(Album).options(*album_options())
    if kind in {"highest", "frequent", "recent"}:
        plays = (
            select(Track.album_id, func.count().label("count"), func.max(PlayEvent.played_at).label("last"))
            .join(PlayEvent, PlayEvent.track_id == Track.id)
            .where(PlayEvent.user_id == user.id)
            .group_by(Track.album_id)
            .subquery()
        )
        query = query.join(plays, plays.c.album_id == Album.id)
        order = plays.c.last.desc() if kind == "recent" else plays.c.count.desc()
    elif kind == "random":
        order = func.random()
    elif kind == "newest":
        order = Album.created_at.desc()
    elif kind == "alphabeticalByName":
        order = func.lower(Album.title)
    elif kind == "alphabeticalByArtist":
        query = query.join(Artist, Artist.id == Album.artist_id)
        order = func.lower(Artist.name)
    elif kind == "starred":
        query = query.join(SavedAlbum, SavedAlbum.album_id == Album.id).where(SavedAlbum.user_id == user.id)
        order = SavedAlbum.created_at.desc()
    elif kind == "byYear":
        params.require("fromYear")
        params.require("toYear")
        start, end = params.integer("fromYear", 0), params.integer("toYear", 0)
        query = query.where(Album.year.between(min(start, end), max(start, end)))
        order = Album.year if start <= end else Album.year.desc()
    elif kind == "byGenre":
        query = query.where(func.lower(Album.genre) == params.require("genre").lower())
        order = Album.title
    else:
        raise ss.SubsonicError(0, "Unbekannter Albumlistentyp")
    rows = list(
        await db.scalars(
            query.order_by(order, Album.title, Album.id)
            .offset(params.integer("offset", 0))
            .limit(params.integer("size", 10, 500))
        )
    )
    result = await ss.albums(db, user, rows)
    return {"albumList" if legacy else "albumList2": {"album": _directories(result) if legacy else result}}


async def _search(db: DB, user: User, params: ss.Params, legacy: bool) -> dict[str, Any]:
    if not params.has("query"):
        raise ss.SubsonicError(10, "Parameter fehlt: query")
    query = params.get("query").strip()
    if query == '""':
        query = ""
    artists = await search.artists(db, query, params.integer("artistCount", 20), params.integer("artistOffset", 0))
    albums = await search.albums(db, query, params.integer("albumCount", 20), params.integer("albumOffset", 0))
    tracks = await search.tracks(db, query, params.integer("songCount", 20), params.integer("songOffset", 0))
    album_rows = await ss.albums(db, user, albums)
    return {
        "searchResult2" if legacy else "searchResult3": {
            "artist": await ss.artists(db, artists),
            "album": _directories(album_rows) if legacy else album_rows,
            "song": await ss.songs(db, user, tracks),
        }
    }


async def _playlist_change(db: DB, user: User, params: ss.Params, create: bool) -> dict[str, Any]:
    song_ids = params.ids("songId" if create else "songIdToAdd")
    await _validate_songs(db, song_ids)
    if create and not params.has("playlistId"):
        body = PlaylistIn(name=params.require("name"))
        created = await playlist_api.create_playlist(body, user, db)
        playlist = await _visible_playlist(db, user, str(created.id), owned=True)
    else:
        playlist = await _visible_playlist(db, user, params.require("playlistId"), owned=True)
    if create:
        await db.execute(delete(PlaylistEntry).where(PlaylistEntry.playlist_id == playlist.id))
    else:
        patch: dict[str, Any] = {}
        for param, field in (("name", "name"), ("comment", "description")):
            if params.has(param):
                patch[field] = params.get(param)
        if params.has("public"):
            patch["is_public"] = params.boolean("public")
        body = PlaylistPatch(**patch)
        entries = list(
            await db.scalars(
                select(PlaylistEntry)
                .where(PlaylistEntry.playlist_id == playlist.id)
                .order_by(PlaylistEntry.position, PlaylistEntry.id)
            )
        )
        try:
            indices = {int(value) for value in params.all("songIndexToRemove")}
        except ValueError as exc:
            raise ss.SubsonicError(0, "Ungültiger Songindex") from exc
        if any(index < 0 or index >= len(entries) for index in indices):
            raise ss.SubsonicError(0, "Ungültiger Songindex")
        # Validate removals before the shared API commits metadata changes.
        if patch:
            await playlist_api.update_playlist(playlist.id, body, user, db)
        await db.execute(delete(PlaylistEntry).where(PlaylistEntry.id.in_([entries[index].id for index in indices])))
    playlist.updated_at = func.now()
    if song_ids:
        await playlist_api.add_tracks(playlist.id, AddTracksIn(track_ids=song_ids), user, db)
    else:
        await db.commit()
    await db.refresh(playlist)
    return await _playlist_detail(db, user, playlist) if create else {}


async def _annotation(db: DB, user: User, params: ss.Params, star: bool) -> dict[str, Any]:
    if not any(params.has(name) for name in ("id", "albumId", "artistId")):
        raise ss.SubsonicError(10, "Parameter fehlt: id oder albumId")
    track_ids, album_ids = set(params.ids("id")), set(params.ids("albumId"))
    tracks = list(await db.scalars(select(Track).where(Track.id.in_(track_ids))))
    known_albums = set(await db.scalars(select(Album.id).where(Album.id.in_(album_ids))))
    if {track.id for track in tracks} != track_ids or known_albums != album_ids:
        raise ss.SubsonicError(70, "Titel oder Album nicht gefunden")
    if star:
        liked = set(
            await db.scalars(
                select(TrackLike.track_id).where(TrackLike.user_id == user.id, TrackLike.track_id.in_(track_ids))
            )
        )
        saved = set(
            await db.scalars(
                select(SavedAlbum.album_id).where(SavedAlbum.user_id == user.id, SavedAlbum.album_id.in_(album_ids))
            )
        )
        db.add_all([TrackLike(user_id=user.id, track_id=track_id) for track_id in track_ids - liked])
        db.add_all([SavedAlbum(user_id=user.id, album_id=album_id) for album_id in album_ids - saved])
        for track in tracks:
            track.is_temporary = False
    else:
        await db.execute(delete(TrackLike).where(TrackLike.user_id == user.id, TrackLike.track_id.in_(track_ids)))
        await db.execute(delete(SavedAlbum).where(SavedAlbum.user_id == user.id, SavedAlbum.album_id.in_(album_ids)))
    await db.commit()
    return {}


async def _media(db: DB, user: User, params: ss.Params, endpoint: str, request: Request) -> Response:
    value = params.require("id")
    if endpoint == "getCoverArt":
        object_id = ss.parse_id(value)
        album = await db.get(Album, object_id)
        if album is None:
            track = await db.get(Track, object_id)
            if track is not None:
                album = await db.get(Album, track.album_id)
            else:
                playlist = await _visible_playlist(db, user, value)
                if playlist.cover_file is not None:
                    size = max(32, min(params.integer("size", 300), 2000)) if params.has("size") else None
                    return await playlist_api.playlist_cover(playlist.id, user, db, size)
                album = await db.scalar(
                    select(Album)
                    .join(Track, Track.album_id == Album.id)
                    .join(PlaylistEntry, PlaylistEntry.track_id == Track.id)
                    .where(PlaylistEntry.playlist_id == playlist.id)
                    .order_by(PlaylistEntry.position, PlaylistEntry.id)
                    .limit(1)
                )
        if album is None:
            raise ss.SubsonicError(70, "Cover nicht gefunden")
        size = max(32, min(params.integer("size", 300), 2000)) if params.has("size") else None
        return await library.album_cover(album.id, user, db, size)
    track = await _track(db, value)
    if not transcode.resolve_path(track.path).is_file():
        raise ss.SubsonicError(70, "Audiodatei nicht gefunden")
    fmt = "raw" if endpoint == "download" else params.get("format", "raw")
    bitrate = params.integer("maxBitRate", 0)
    if fmt == "raw":
        if endpoint == "stream" and not params.has("format") and bitrate and (track.bitrate or 0) > bitrate:
            fmt = "mp3"
        else:
            bitrate = 0
    elif fmt not in transcode.FORMAT_MEDIA_TYPES:
        # Only formats supported by the existing transcode service can be requested.
        raise ss.SubsonicError(0, "Audioformat nicht unterstützt")
    return await library.stream_track(
        track.id, user, db, request, format=fmt, bitrate=max(32, min(bitrate, 320)) if bitrate else None
    )


async def _dispatch(
    endpoint: str, db: DB, user: User, params: ss.Params, request: Request
) -> dict[str, Any] | Response:
    if endpoint in {"ping", "setRating", "savePlayQueue"}:
        return {}
    if endpoint == "getLicense":
        return {"license": {"valid": True}}
    if endpoint == "getOpenSubsonicExtensions":
        return {
            "openSubsonicExtensions": [
                {"name": name, "versions": [1]} for name in ("formPost", "songLyrics", "apiKeyAuthentication")
            ]
        }
    if endpoint == "getMusicFolders":
        return {"musicFolders": {"musicFolder": [{"id": "1", "name": "Resonance"}]}}
    if endpoint == "getUser":
        username = params.require("username")
        if username.lower() != user.username.lower() and not user.is_admin:
            raise ss.SubsonicError(50, "Nicht berechtigt")
        target = await db.scalar(select(User).where(func.lower(User.username) == username.lower()))
        if target is None:
            raise ss.SubsonicError(70, "Benutzer nicht gefunden")
        return {
            "user": {
                "username": target.username,
                "streamRole": True,
                "downloadRole": True,
                "playlistRole": True,
                "coverArtRole": True,
                "adminRole": target.is_admin,
                "settingsRole": False,
                "uploadRole": False,
                "scrobblingEnabled": False,
                "podcastRole": False,
                "commentRole": False,
                "jukeboxRole": False,
                "shareRole": False,
                "videoConversionRole": False,
            }
        }
    if endpoint == "getScanStatus":
        job = await db.scalar(select(Job).where(Job.kind == "library_scan").order_by(Job.created_at.desc()).limit(1))
        return {
            "scanStatus": {
                "scanning": job is not None and job.status in {"queued", "running"},
                "count": await db.scalar(select(func.count()).select_from(Track)) or 0,
            }
        }
    if endpoint in {"getArtists", "getIndexes"}:
        rows = list(
            await db.scalars(
                select(Artist).order_by(func.lower(func.coalesce(Artist.sort_name, Artist.name)), Artist.id)
            )
        )
        values = await ss.artists(db, rows)
        groups: dict[str, list[dict[str, Any]]] = {}
        for artist, value in zip(rows, values, strict=True):
            letter = (artist.sort_name or artist.name).strip()[:1].upper() or "#"
            groups.setdefault(letter, []).append(value)
        return {
            "artists" if endpoint == "getArtists" else "indexes": {
                "ignoredArticles": "The El La Los Las Le Les Die Der Das",
                "index": [{"name": name, "artist": group} for name, group in groups.items()],
            }
        }
    if endpoint == "getArtist":
        artist = await db.get(Artist, ss.parse_id(params.require("id")))
        if artist is None:
            raise ss.SubsonicError(70, "Künstler nicht gefunden")
        result = (await ss.artists(db, [artist]))[0]
        result["album"] = await ss.albums(db, user, await _artist_albums(db, artist.id))
        return {"artist": result}
    if endpoint == "getAlbum":
        album = await _album(db, params.require("id"))
        result = (await ss.albums(db, user, [album]))[0]
        result["song"] = await ss.songs(db, user, await _album_tracks(db, album.id))
        return {"album": result}
    if endpoint == "getSong":
        return {"song": (await ss.songs(db, user, [await _track(db, params.require("id"))]))[0]}
    if endpoint == "getMusicDirectory":
        value = params.require("id")
        artist = await db.get(Artist, ss.parse_id(value))
        if artist is not None:
            return {
                "directory": {
                    "id": str(artist.id),
                    "name": artist.name,
                    "child": _directories(await ss.albums(db, user, await _artist_albums(db, artist.id))),
                }
            }
        album = await _album(db, value)
        return {
            "directory": {
                "id": str(album.id),
                "parent": str(album.artist_id),
                "name": album.title,
                "child": await ss.songs(db, user, await _album_tracks(db, album.id)),
            }
        }
    if endpoint == "getGenres":
        genre = func.coalesce(Track.genre, Album.genre)
        rows = await db.execute(
            select(genre, func.count(), func.count(func.distinct(Track.album_id)))
            .join(Album, Album.id == Track.album_id)
            .where(genre.is_not(None), genre != "")
            .group_by(genre)
            .order_by(genre)
        )
        return {
            "genres": {
                "genre": [{"value": name, "songCount": songs, "albumCount": albums} for name, songs, albums in rows]
            }
        }
    if endpoint in {"getAlbumList", "getAlbumList2"}:
        return await _album_list(db, user, params, endpoint == "getAlbumList")
    if endpoint in {"getRandomSongs", "getSongsByGenre"}:
        query = select(Track).options(*track_options()).join(Album, Album.id == Track.album_id)
        if endpoint == "getSongsByGenre":
            params.require("genre")
        if params.has("genre"):
            query = query.where(func.lower(func.coalesce(Track.genre, Album.genre)) == params.get("genre").lower())
        if params.has("fromYear"):
            query = query.where(Track.year >= params.integer("fromYear", 0))
        if params.has("toYear"):
            query = query.where(Track.year <= params.integer("toYear", 0))
        random = endpoint == "getRandomSongs"
        query = query.order_by(func.random() if random else Track.title, Track.id)
        rows = list(
            await db.scalars(
                query.offset(params.integer("offset", 0)).limit(params.integer("size" if random else "count", 10, 500))
            )
        )
        return {"randomSongs" if random else "songsByGenre": {"song": await ss.songs(db, user, rows)}}
    if endpoint in {"getStarred", "getStarred2"}:
        tracks = list(
            await db.scalars(
                select(Track)
                .join(TrackLike, TrackLike.track_id == Track.id)
                .where(TrackLike.user_id == user.id)
                .options(*track_options())
                .order_by(TrackLike.created_at.desc())
            )
        )
        albums = list(
            await db.scalars(
                select(Album)
                .join(SavedAlbum, SavedAlbum.album_id == Album.id)
                .where(SavedAlbum.user_id == user.id)
                .options(*album_options())
                .order_by(SavedAlbum.created_at.desc())
            )
        )
        album_rows = await ss.albums(db, user, albums)
        legacy = endpoint == "getStarred"
        return {
            "starred" if legacy else "starred2": {
                "artist": [],
                "album": _directories(album_rows) if legacy else album_rows,
                "song": await ss.songs(db, user, tracks),
            }
        }
    if endpoint in {"getTopSongs", "getSimilarSongs", "getSimilarSongs2"}:
        query = select(Track).options(*track_options())
        if endpoint == "getTopSongs":
            query = (
                query.join(Artist, Artist.id == Track.artist_id)
                .outerjoin(PlayEvent, PlayEvent.track_id == Track.id)
                .where(func.lower(Artist.name) == params.require("artist").lower())
                .group_by(Track.id)
                .order_by(func.count(PlayEvent.id).desc(), Track.title, Track.id)
            )
            key = "topSongs"
        else:
            object_id = ss.parse_id(params.require("id"))
            track = await db.get(Track, object_id)
            album = await db.get(Album, object_id) if track is None else None
            artist_id = track.artist_id if track else album.artist_id if album else object_id
            if track is None and album is None and await db.get(Artist, object_id) is None:
                raise ss.SubsonicError(70, "Nicht gefunden")
            query = query.where(Track.artist_id == artist_id, Track.id != object_id)
            if album is not None:
                query = query.where(Track.album_id != album.id)
            query = query.order_by(func.random())
            key = "similarSongs2" if endpoint.endswith("2") else "similarSongs"
        tracks = list(await db.scalars(query.limit(params.integer("count", 50))))
        return {key: {"song": await ss.songs(db, user, tracks)}}
    if endpoint in {"search2", "search3"}:
        return await _search(db, user, params, endpoint == "search2")
    if endpoint == "getPlaylists":
        visible = await playlist_api.list_playlists(user, db, request)
        ids = [playlist.id for playlist in visible if playlist.kind != "mix"]
        rows = list(await db.scalars(select(Playlist).where(Playlist.id.in_(ids)).order_by(Playlist.updated_at.desc())))
        return {"playlists": {"playlist": await ss.playlists(db, user, rows)}}
    if endpoint == "getPlaylist":
        return await _playlist_detail(db, user, await _visible_playlist(db, user, params.require("id")))
    if endpoint in {"createPlaylist", "updatePlaylist"}:
        return await _playlist_change(db, user, params, endpoint == "createPlaylist")
    if endpoint == "deletePlaylist":
        playlist = await _visible_playlist(db, user, params.require("id"), owned=True)
        await playlist_api.delete_playlist(playlist.id, user, db)
        return {}
    if endpoint in {"star", "unstar"}:
        return await _annotation(db, user, params, endpoint == "star")
    if endpoint == "scrobble":
        params.require("id")
        if params.boolean("submission", True):
            ids = params.ids("id")
            tracks = {track.id: track for track in await db.scalars(select(Track).where(Track.id.in_(ids)))}
            if set(ids) != set(tracks):
                raise ss.SubsonicError(70, "Titel nicht gefunden")
            for track_id in ids:
                await me.report_play(
                    PlayEventIn(track_id=track_id, seconds_played=tracks[track_id].duration, context="subsonic"),
                    user,
                    db,
                )
        return {}
    if endpoint in {"stream", "download", "getCoverArt"}:
        return await _media(db, user, params, endpoint, request)
    if endpoint == "getLyricsBySongId":
        track = await _track(db, params.require("id"))
        lyrics = await get_lyrics(db, track)
        return {
            "lyricsList": {
                "structuredLyrics": [
                    {
                        "synced": lyrics.synced,
                        "lang": "xxx",
                        "displayArtist": track.artist_credit,
                        "displayTitle": track.title,
                        "line": [
                            {**({"start": line.time_ms} if line.time_ms is not None else {}), "value": line.text}
                            for line in lyrics.lines
                        ],
                    }
                ]
                if lyrics.lines
                else []
            }
        }
    if endpoint == "getLyrics":
        artist, title = params.require("artist"), params.require("title")
        track = await db.scalar(
            select(Track)
            .options(*track_options())
            .join(Artist, Artist.id == Track.artist_id)
            .where(
                Track.title.ilike(f"%{title}%"),
                or_(Track.artist_credit.ilike(f"%{artist}%"), Artist.name.ilike(f"%{artist}%")),
            )
            .order_by(
                (func.lower(Track.title) == title.lower()).desc(),
                (func.lower(Track.artist_credit) == artist.lower()).desc(),
                Track.id,
            )
            .limit(1)
        )
        if track is None:
            return {"lyrics": {}}
        lyrics = await get_lyrics(db, track)
        return {
            "lyrics": {
                "artist": track.artist_credit,
                "title": track.title,
                "value": "\n".join(line.text for line in lyrics.lines),
            }
        }
    if endpoint == "getNowPlaying":
        return {"nowPlaying": {"entry": []}}
    if endpoint == "getPlayQueue":
        return {"playQueue": {"entry": []}}
    raise ss.SubsonicError(0, "Nicht unterstützt")


@router.api_route("/{endpoint}", methods=["GET", "POST"])
async def subsonic(endpoint: str, request: Request, db: DB) -> Response:
    params = ss.Params(list(request.query_params.multi_items()))
    error = None
    try:
        params = await ss.Params.read(request)
        user = await ss.authenticate(db, params)
        result = await _dispatch(endpoint.removesuffix(".view"), db, user, params, request)
        if isinstance(result, Response):
            return result
        return ss.response(params, request.app.version, result)
    except ss.SubsonicError as exc:
        error = exc
    except HTTPException as exc:
        code = {401: 40, 403: 50, 404: 70, 410: 70}.get(exc.status_code, 0)
        error = ss.SubsonicError(
            code,
            {40: "Benutzername oder Passwort falsch", 50: "Nicht berechtigt", 70: "Nicht gefunden"}.get(
                code, "Ungültige Anfrage"
            ),
        )
    except (ValidationError, ValueError) as exc:
        error = ss.SubsonicError(0, "Ungültige Parameter")
        log.debug("Invalid Subsonic parameters: %s", exc)
    except Exception:
        log.exception("Subsonic request failed: %s", endpoint)
        error = ss.SubsonicError(0, "Interner Fehler")
    error.message = translate(error.message, language(request))
    return ss.response(params, request.app.version, {}, error)
