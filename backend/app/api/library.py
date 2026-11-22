import asyncio
import dataclasses
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, HTTPException, Query, Request, status
from fastapi.responses import FileResponse, Response, StreamingResponse
from sqlalchemy import func, or_, select

from app.api import diagnostics
from app.api.catalog import _track as catalog_track
from app.api.requests import _out as request_out
from app.deps import DB, AdminUser, CurrentUser
from app.i18n import language, translate
from app.models import (
    Album,
    Artist,
    PlayEvent,
    Playlist,
    SavedAlbum,
    Track,
    TrackMixPoints,
)
from app.schemas import (
    AlbumDetail,
    AlbumOut,
    ArtistDetail,
    ArtistOut,
    CreditsOut,
    DownloadRequestDetail,
    HomeOut,
    LyricsHit,
    LyricsOut,
    MissingTracksOut,
    Page,
    RedownloadIn,
    SearchResult,
    TrackOut,
)
from app.services import (
    covers,
    credits,
    mixpoints,
    ringtone,
    spectrum,
    transcode,
    vocals,
)
from app.services import search as library_search
from app.services.deezer import DeezerError, deezer
from app.services.downloads import create_redownload
from app.services.lyrics import get_lyrics
from app.services.matching import match_tracks, name_key
from app.services.mixes import mix_search_terms
from app.services.views import (
    album_options,
    albums_out,
    artists_out,
    playlists_out,
    track_options,
    tracks_out,
)

router = APIRouter(prefix="/api", tags=["library"])


def _track_order():
    return (Track.disc_no.nulls_first(), Track.track_no.nulls_last(), Track.title)


@router.get("/home", response_model=HomeOut)
async def home(user: CurrentUser, db: DB, request: Request) -> HomeOut:
    recent_album_ids = (
        await db.execute(
            select(Track.album_id, func.max(PlayEvent.played_at).label("last"))
            .join(PlayEvent, PlayEvent.track_id == Track.id)
            .where(PlayEvent.user_id == user.id)
            .group_by(Track.album_id)
            .order_by(func.max(PlayEvent.played_at).desc())
            .limit(12)
        )
    ).all()
    ids = [r[0] for r in recent_album_ids]
    by_id = {a.id: a for a in await db.scalars(select(Album).options(*album_options()).where(Album.id.in_(ids)))}
    recently_played = [by_id[i] for i in ids if i in by_id]

    recently_added = list(
        await db.scalars(select(Album).options(*album_options()).order_by(Album.created_at.desc()).limit(12))
    )

    playlists = list(
        await db.scalars(
            select(Playlist)
            .where(Playlist.owner_id == user.id, Playlist.kind == "user")
            .order_by(Playlist.updated_at.desc())
            .limit(12)
        )
    )

    since = datetime.now(UTC) - timedelta(days=30)
    top_ids = [
        r[0]
        for r in (
            await db.execute(
                select(PlayEvent.track_id)
                .where(PlayEvent.user_id == user.id, PlayEvent.played_at >= since)
                .group_by(PlayEvent.track_id)
                .order_by(func.count().desc())
                .limit(10)
            )
        ).all()
    ]
    tracks_by_id = {
        t.id: t for t in await db.scalars(select(Track).options(*track_options()).where(Track.id.in_(top_ids)))
    }

    return HomeOut(
        recently_played=await albums_out(db, recently_played),
        recently_added=await albums_out(db, recently_added),
        playlists=await playlists_out(db, playlists, user.id, language(request)),
        most_played=await tracks_out(db, user, [tracks_by_id[i] for i in top_ids if i in tracks_by_id]),
    )


# --- artists ----------------------------------------------------------------


@router.get("/artists", response_model=Page[ArtistOut])
async def list_artists(
    user: CurrentUser,
    db: DB,
    request: Request,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500),
) -> Page[ArtistOut]:
    total = await db.scalar(select(func.count()).select_from(Artist)) or 0
    rows = await db.scalars(
        select(Artist).order_by(func.coalesce(Artist.sort_name, Artist.name)).offset(offset).limit(limit)
    )
    return Page(items=await artists_out(db, list(rows), language(request)), total=total, offset=offset, limit=limit)


@router.get("/artists/{artist_id}", response_model=ArtistDetail)
async def get_artist(artist_id: uuid.UUID, user: CurrentUser, db: DB, request: Request) -> ArtistDetail:
    artist = await db.get(Artist, artist_id)
    if artist is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Artist not found")
    albums = list(
        await db.scalars(
            select(Album)
            .options(*album_options())
            .where(Album.artist_id == artist_id)
            .order_by(Album.year.desc().nulls_last(), Album.title)
        )
    )
    # "Popular" = most played by everyone on this server; fall back to album order.
    plays = func.count(PlayEvent.id)
    top = list(
        await db.scalars(
            select(Track)
            .options(*track_options())
            .outerjoin(PlayEvent, PlayEvent.track_id == Track.id)
            .where(Track.artist_id == artist_id)
            .group_by(Track.id)
            .order_by(plays.desc(), Track.title)
            .limit(10)
        )
    )
    detail = ArtistDetail.model_validate((await artists_out(db, [artist], language(request)))[0].model_dump())
    detail.albums = await albums_out(db, albums)
    detail.top_tracks = await tracks_out(db, user, top)
    return detail


@router.get("/artists/{artist_id}/image")
async def artist_image(
    artist_id: uuid.UUID, user: CurrentUser, db: DB, size: int | None = Query(None, ge=32, le=2000)
) -> Response:
    artist = await db.get(Artist, artist_id)
    path = (
        await asyncio.to_thread(covers.resized, artist.image_path.removeprefix("covers/"), size)
        if artist and artist.image_path
        else None
    )
    if path is None:
        raise HTTPException(404, "Kein Künstlerbild")
    return FileResponse(path, media_type="image/jpeg", headers={"Cache-Control": "private, max-age=604800"})


# --- albums -----------------------------------------------------------------


@router.get("/albums", response_model=Page[AlbumOut])
async def list_albums(
    user: CurrentUser,
    db: DB,
    sort: Literal["recent", "title", "year", "artist"] = "recent",
    saved: bool = False,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=500),
) -> Page[AlbumOut]:
    query = select(Album).options(*album_options())
    count_query = select(func.count()).select_from(Album)
    if saved:
        query = query.join(SavedAlbum, SavedAlbum.album_id == Album.id).where(SavedAlbum.user_id == user.id)
        count_query = count_query.join(SavedAlbum, SavedAlbum.album_id == Album.id).where(SavedAlbum.user_id == user.id)
    order = {
        "recent": (Album.created_at.desc(),),
        "title": (Album.title,),
        "year": (Album.year.desc().nulls_last(), Album.title),
        "artist": (Artist.name, Album.year),
    }[sort]
    if sort == "artist":
        query = query.join(Artist, Artist.id == Album.artist_id)
    rows = await db.scalars(query.order_by(*order).offset(offset).limit(limit))
    total = await db.scalar(count_query) or 0
    return Page(items=await albums_out(db, list(rows)), total=total, offset=offset, limit=limit)


@router.get("/albums/{album_id}", response_model=AlbumDetail)
async def get_album(album_id: uuid.UUID, user: CurrentUser, db: DB) -> AlbumDetail:
    album = await db.scalar(select(Album).options(*album_options()).where(Album.id == album_id))
    if album is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Album not found")
    tracks = list(
        await db.scalars(
            select(Track).options(*track_options()).where(Track.album_id == album_id).order_by(*_track_order())
        )
    )
    detail = AlbumDetail.model_validate((await albums_out(db, [album]))[0].model_dump())
    detail.tracks = await tracks_out(db, user, tracks)
    detail.duration = sum(t.duration for t in tracks)
    detail.saved = (
        await db.scalar(select(SavedAlbum.id).where(SavedAlbum.user_id == user.id, SavedAlbum.album_id == album_id))
    ) is not None
    return detail


async def _catalog_album_id(db: DB, album_id: uuid.UUID) -> tuple[Album, str]:
    """Find the catalog (Deezer) album matching a library album."""
    album = await db.scalar(select(Album).options(*album_options()).where(Album.id == album_id))
    if album is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Nicht gefunden")
    try:
        results = await deezer.search_albums(f"{album.artist.name} {album.title}", 10)
    except DeezerError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Katalog nicht erreichbar") from e
    candidates = [result for result in results if name_key(result["artist"]["name"]) == album.artist.name_key]
    for result in candidates:
        if name_key(result["title"]) == album.title_key:
            return album, str(result["id"])
    for result in candidates:
        title_key = name_key(result["title"])
        if title_key.startswith(album.title_key) or album.title_key.startswith(title_key):
            return album, str(result["id"])
    raise HTTPException(status.HTTP_404_NOT_FOUND, "Album nicht im Katalog gefunden")


@router.get("/library/albums/{album_id}/catalog")
async def album_catalog(album_id: uuid.UUID, user: CurrentUser, db: DB) -> dict[str, str]:
    _, catalog_id = await _catalog_album_id(db, album_id)
    return {"catalog_id": catalog_id}


@router.get("/library/albums/{album_id}/missing", response_model=MissingTracksOut)
async def album_missing(album_id: uuid.UUID, user: CurrentUser, db: DB) -> MissingTracksOut:
    """Songs of the matching catalog album that are not in the library (shown greyed out on the album page).

    A catalog song counts as present if it matches any library track (ISRC / artist + title) or if the library
    album already has a song at the same disc/track position (tag variants like "Remastered")."""
    album, catalog_id = await _catalog_album_id(db, album_id)
    try:
        data, raw = await asyncio.gather(deezer.album(catalog_id), deezer.album_tracks(catalog_id))
    except DeezerError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Katalog nicht erreichbar") from e
    tracks = [catalog_track(t, data) for t in raw]
    await match_tracks(db, tracks)
    taken = set((await db.execute(select(Track.disc_no, Track.track_no).where(Track.album_id == album.id))).all())
    missing = [
        t
        for t in tracks
        if t.library_id is None and (t.disc_no or 1, t.track_no) not in {(d or 1, n) for d, n in taken}
    ]
    return MissingTracksOut(catalog_id=catalog_id, tracks=missing)


@router.get("/albums/{album_id}/cover")
async def album_cover(
    album_id: uuid.UUID,
    user: CurrentUser,
    db: DB,
    size: int | None = Query(None, ge=32, le=2000),
) -> Response:
    album = await db.get(Album, album_id)
    if album is None or album.cover_file is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No cover")
    path = await asyncio.to_thread(covers.resized, album.cover_file, size)
    if path is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No cover")
    return FileResponse(path, media_type="image/jpeg", headers={"Cache-Control": "private, max-age=604800"})


# --- tracks -----------------------------------------------------------------


@router.get("/tracks/{track_id}", response_model=TrackOut)
async def get_track(track_id: uuid.UUID, user: CurrentUser, db: DB) -> TrackOut:
    track = await db.scalar(select(Track).options(*track_options()).where(Track.id == track_id))
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Track not found")
    return (await tracks_out(db, user, [track]))[0]


@router.post("/tracks/{track_id}/redownload", response_model=DownloadRequestDetail, status_code=201)
async def redownload(
    track_id: uuid.UUID, body: RedownloadIn, user: CurrentUser, db: DB, request: Request
) -> DownloadRequestDetail:
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(404, "Song nicht gefunden")
    return request_out(await create_redownload(db, user, track, body.youtube_url), language(request))


@router.get("/tracks/{track_id}/lyrics", response_model=LyricsOut)
async def track_lyrics(track_id: uuid.UUID, user: CurrentUser, db: DB, response: Response) -> LyricsOut:
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Titel nicht gefunden")
    response.headers["Cache-Control"] = "private, max-age=3600"
    return await get_lyrics(db, track)


@router.get("/tracks/{track_id}/credits", response_model=CreditsOut)
async def track_credits(track_id: uuid.UUID, user: CurrentUser, db: DB) -> CreditsOut:
    """Who sang, wrote and produced the song (tags and MusicBrainz; looked up once, then cached)."""
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Track not found")
    return await credits.credits(db, track)


@router.get("/tracks/{track_id}/stream")
async def stream_track(
    track_id: uuid.UUID,
    user: CurrentUser,
    db: DB,
    request: Request,
    format: Literal["auto", "raw", "opus", "mp3"] = "auto",
    bitrate: int | None = Query(None, ge=32, le=320),
    # Only answer with the finished file (with its length): the Samsung TV stops partway through a stream without one.
    complete: bool = False,
) -> Response:
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Track not found")
    path = transcode.resolve_path(track.path)
    if not path.is_file():
        raise HTTPException(status.HTTP_410_GONE, "File missing on disk")
    if format == "auto":
        # Pass through what clients can play; WMA/APE/AIFF/ALAC/... become high-bitrate Opus.
        if track.codec in transcode.NATIVE_CODECS:
            format = "raw"
        else:
            format, bitrate = "opus", bitrate or 256
    if format == "raw":
        if request.headers.get("range"):
            diagnostics.note(user.username, "stream", track=str(track_id), format="raw", range=request.headers["range"])
        # FileResponse handles HTTP Range requests, which players need for seeking.
        return FileResponse(path, media_type=transcode.media_type(path))
    if request.headers.get("range") or complete:
        diagnostics.note(
            user.username, "stream", track=str(track_id), format=format, complete=complete,
            range=request.headers.get("range"), cached=transcode.cache_path(path, format, bitrate or 160).is_file(),
            agent=request.headers.get("user-agent", "")[:80],
        )  # fmt: skip
    target, job = transcode.start(path, format, bitrate or 160)
    media = transcode.FORMAT_MEDIA_TYPES[format]
    if job is not None:
        range_header = request.headers.get("range", "")
        if not complete and (not range_header or range_header.replace(" ", "") in {"bytes=0-", "bytes=0"}):
            # Starts right away; the length is unknown until the transcode is done.
            return StreamingResponse(transcode.follow(target, job), media_type=media, headers={"Accept-Ranges": "bytes"})
        await job  # a resume/seek needs byte positions: answer it from the finished file
    return FileResponse(target, media_type=media)


@router.post("/tracks/{track_id}/stream/prepare", status_code=204)
async def prepare_stream(
    track_id: uuid.UUID,
    user: CurrentUser,
    db: DB,
    format: Literal["opus", "mp3"] = "mp3",
    bitrate: int = Query(160, ge=32, le=320),
) -> None:
    """Starts a transcode ahead of time (the next song in the queue), so a later complete=true stream needs no wait."""
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Track not found")
    path = transcode.resolve_path(track.path)
    if path.is_file():
        transcode.start(path, format, bitrate)


async def _track_file(db: DB, track_id: uuid.UUID) -> tuple[Track, Path]:
    track = await db.get(Track, track_id)
    if track is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Track not found")
    path = transcode.resolve_path(track.path)
    if not path.is_file():
        raise HTTPException(status.HTTP_410_GONE, "File missing on disk")
    return track, path


@router.get("/tracks/{track_id}/ringtone/suggestion")
async def ringtone_suggestion(
    track_id: uuid.UUID, user: CurrentUser, db: DB, length: float = Query(30, ge=5, le=60)
) -> dict[str, float | list[float]]:
    """Where a ringtone of `length` seconds should start: the song's loudest stretch, usually its chorus. With the
    song's loudness per second (0..1) for the picker's waveform."""
    track, path = await _track_file(db, track_id)
    start, levels = await ringtone.suggest(path, length)
    return {"start": min(start, max(0.0, track.duration - length)), "duration": track.duration, "levels": levels}


@router.get("/tracks/{track_id}/ringtone")
async def ringtone_file(
    track_id: uuid.UUID,
    user: CurrentUser,
    db: DB,
    start: float = Query(0, ge=0),
    length: float = Query(30, ge=5, le=60),
) -> Response:
    """The cut as MP3 with fades, for saving as ringtone, notification or alarm sound (and for the preview)."""
    track, path = await _track_file(db, track_id)
    if start >= track.duration:
        raise HTTPException(422, "Start liegt hinter dem Songende")
    try:
        data = await ringtone.cut(path, start, min(length, track.duration - start))
    except RuntimeError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Klingelton konnte nicht erstellt werden") from e
    return Response(data, media_type="audio/mpeg", headers={"Cache-Control": "private, max-age=3600"})


# --- AutoMix ----------------------------------------------------------------


@router.get("/mixpoints/status")
async def get_mixpoint_status(admin: AdminUser, db: DB) -> dict[str, int | dict]:
    total, analyzed, failed = (await db.execute(
        select(
            func.count(Track.id),
            func.count(TrackMixPoints.track_id).filter(
                TrackMixPoints.failed.is_(False), TrackMixPoints.mtime == Track.mtime
            ),
            func.count(TrackMixPoints.track_id).filter(TrackMixPoints.failed.is_(True)),
        )
        .outerjoin(
            TrackMixPoints, (TrackMixPoints.track_id == Track.id) & (TrackMixPoints.version == mixpoints.VERSION)
        )
        .where(Track.is_temporary.is_(False))
    )).one()
    return {"total": total, "analyzed": analyzed, "failed": failed, "vocals": await vocals.status(db)}


@router.get("/mixpoints/keys")
async def get_mixpoint_keys(user: CurrentUser, db: DB, ids: str = Query(max_length=18500)) -> dict[str, dict | None]:
    """Stored musical keys and tempos; never triggers analysis."""
    values = ids.split(",")
    if len(values) > 500:
        raise HTTPException(422, "Ungültige Parameter")
    try:
        track_ids = list(dict.fromkeys(uuid.UUID(value) for value in values))
    except ValueError as e:
        raise HTTPException(422, "Ungültige Song-ID") from e
    rows = {row.track_id: row for row in await db.scalars(
        select(TrackMixPoints).where(
            TrackMixPoints.track_id.in_(track_ids), TrackMixPoints.version >= mixpoints.KEYS_SINCE
        )
    )}
    return {
        str(id): {"key": rows[id].key, "bpm": rows[id].bpm, "energy": rows[id].energy} if id in rows else None
        for id in track_ids
    }


@router.post("/tracks/{id}/stems")
async def prepare_stem(id: uuid.UUID, user: CurrentUser, db: DB) -> dict:
    """The song's start without its voice, for the desktop's vocal swap: ready, pending (separating) or
    unavailable (the song analysis is off)."""
    track = await db.get(Track, id)
    if track is None:
        raise HTTPException(404, "Nicht gefunden")
    state = await vocals.request_stem(db, track)
    result = {"state": state, "seconds": min(vocals.STEM_SECONDS, track.duration or 0)}
    if state == "failed" and user.is_admin:
        result["error"] = vocals.stem_error(id)
    return result


@router.get("/tracks/{id}/stems/intro")
async def get_stem(id: uuid.UUID, user: CurrentUser, db: DB) -> FileResponse:
    track = await db.get(Track, id)
    path = None if track is None else vocals.stem_path(track)
    if path is None or not path.exists():
        raise HTTPException(404, "Nicht gefunden")
    return FileResponse(path, media_type="audio/ogg", headers={"Cache-Control": "private, max-age=86400"})


@router.get("/mixpoints")
async def get_mixpoints(user: CurrentUser, db: DB, ids: str = Query(max_length=400)) -> dict[str, dict | None]:
    """Tempo, mix points and lyric-based vocal bounds for AutoMix (null when a track cannot be analyzed)."""
    try:
        track_ids = list(dict.fromkeys(uuid.UUID(value) for value in ids.split(",") if value))[:10]
    except ValueError as e:
        raise HTTPException(422, "Ungültige Song-ID") from e
    points = await mixpoints.for_tracks(db, track_ids)
    return {str(id): None if p is None else dataclasses.asdict(p) for id, p in points.items()}


@router.get("/tracks/{id}/spectrum")
async def get_spectrum(id: uuid.UUID, user: CurrentUser, db: DB) -> Response:
    """Frequency bands per frame for the visualizer (binary, see `services/spectrum.py`)."""
    data = await spectrum.for_track(db, id)
    if data is None:
        raise HTTPException(404, "Nicht gefunden")
    return Response(data, media_type="application/octet-stream", headers={"Cache-Control": "private, max-age=86400"})


# --- search -----------------------------------------------------------------


@router.get("/search", response_model=SearchResult)
async def search(
    user: CurrentUser,
    db: DB,
    request: Request,
    q: str = Query(min_length=1, max_length=200),
    limit: int = Query(20, ge=1, le=100),
) -> SearchResult:
    artists = await library_search.artists(db, q, limit)
    albums = await library_search.albums(db, q, limit)
    tracks = await library_search.tracks(db, q, limit)
    lyrics_hits = await library_search.lyrics(db, q, min(limit, 10))
    # Own playlists and mixes (also by their translated name or e.g. "80s"), plus other users' public playlists.
    lang = language(request)
    needle = q.strip().casefold()
    wanted = [library_search.fold(word) for word in library_search.words(q)]
    candidates = await db.scalars(
        select(Playlist)
        .where(or_(Playlist.owner_id == user.id, (Playlist.is_public) & (Playlist.kind == "user")))
        .order_by(Playlist.kind != "mix", Playlist.name)
    )
    playlists = [
        playlist
        for playlist in candidates
        if any(
            needle in text.casefold() or (wanted and all(word in library_search.fold(text) for word in wanted))
            for text in (playlist.name, translate(playlist.name, lang), *mix_search_terms(playlist.mix_key))
        )
    ][:limit]
    return SearchResult(
        artists=await artists_out(db, artists, lang),
        albums=await albums_out(db, albums),
        tracks=await tracks_out(db, user, tracks),
        playlists=await playlists_out(db, playlists, user.id, lang),
        lyrics=[
            LyricsHit(track=track, line=line)
            for track, line in zip(
                await tracks_out(db, user, [track for track, _ in lyrics_hits]),
                (line for _, line in lyrics_hits),
                strict=True,
            )
        ],
    )
