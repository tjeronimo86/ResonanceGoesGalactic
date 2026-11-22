from collections.abc import AsyncIterator

import httpx
import pytest
from sqlalchemy import select, update

from app.db import Base, SessionLocal, engine
from app.models import Album, Artist, Track
from app.models.library import TrackLyrics
from app.services import search
from tests.conftest import auth, register

# (title, artist credit, album, album artist)
_SONGS = [
    ("Bohemian Rhapsody", "Queen", "A Night at the Opera", "Queen"),
    ("Love of My Life", "Queen", "A Night at the Opera", "Queen"),
    ("Don't Stop Me Now", "Queen", "Jazz", "Queen"),
    # "bohemian queen" matches it too, through its album.
    ("Killer Queen", "Queen", "Bohemian Rhapsody (The Original Soundtrack)", "Queen"),
    ("Halo", "Beyoncé", "I Am... Sasha Fierce", "Beyoncé"),
    ("Ace of Spades", "Motörhead", "Ace of Spades", "Motörhead"),
    ("Back in Black", "AC/DC", "Back in Black", "AC/DC"),
    ("The Boxer", "Simon & Garfunkel", "Bridge over Troubled Water", "Simon & Garfunkel"),
    ("Master of Puppets", "Metallica", "Master of Puppets", "Metallica"),
    ("Must Be the Moon", "!!!", "Myth Takes", "!!!"),
    ("Lovely Day", "Bill Withers", "Menagerie", "Bill Withers"),
    ("Love", "Keyshia Cole", "Just Like You", "Keyshia Cole"),
    ("Stand By Me", "Ben E. King", "Don't Play That Song!", "Ben E. King"),
    ("Bad Romance", "Lady Gaga feat. Nobody", "The Fame Monster", "Lady Gaga"),
    # "hothearts" contains "the" across a word boundary.
    ("Hot Heart Love", "Somebody", "Untitled", "Somebody"),
    ("The Love Cats (Live in Paris)", "The Cure", "Japanese Whispers", "The Cure"),
    # Umlauts, written out in either the library or the query.
    ("Männer", "Herbert Grönemeyer", "4630 Bochum", "Herbert Grönemeyer"),
    ("Schoene Gruesse", "Die Aerzte", "Jazz ist anders", "Die Aerzte"),
    # Other scripts.
    ("Группа крови", "Кино", "Группа крови", "Кино"),
    ("群青日和", "東京事変", "教育", "東京事変"),
]
# Genre and year of some songs and their albums.
_TAGS = {"Bohemian Rhapsody": ("Rock", 1975), "Back in Black": ("Hard Rock", 1980), "Halo": ("Pop", 2008)}
_LYRICS = {
    "Bohemian Rhapsody": ("Is this the real life?\nIs this just fantasy?\nCaught in a landslide", None),
    "Halo": (None, "[00:12.00]Remember those walls I built\n[00:15.50]Well, baby, they're tumbling down"),
}


@pytest.fixture
async def library() -> AsyncIterator[None]:
    assert engine.url.database.startswith("app_test")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    async with SessionLocal() as db:
        artists: dict[str, Artist] = {}
        albums: dict[str, Album] = {}
        for i, (title, credit, album_title, album_artist) in enumerate(_SONGS):
            artist = artists.get(album_artist)
            if artist is None:
                artist = artists[album_artist] = Artist(name=album_artist, name_key=f"artist-{len(artists)}")
                db.add(artist)
                await db.flush()
            album = albums.get(album_title)
            if album is None:
                album = albums[album_title] = Album(title=album_title, title_key=f"album-{i}", artist_id=artist.id)
                db.add(album)
                await db.flush()
            genre, year = _TAGS.get(title, (None, None))
            if genre:
                album.genre, album.year = genre, year
            track = Track(
                path=f"{i}.flac",
                title=title,
                album_id=album.id,
                artist_id=artist.id,
                artist_credit=credit,
                duration=200,
                size=1024,
                genre=genre,
                year=year,
            )
            db.add(track)
            await db.flush()
            if title in _LYRICS:
                plain, synced = _LYRICS[title]
                db.add(TrackLyrics(track_id=track.id, plain=plain, synced=synced, source="lrclib"))
        await db.commit()
    yield


async def _titles(query: str) -> list[str]:
    async with SessionLocal() as db:
        return [track.title for track in await search.tracks(db, query, 20)]


async def _artists(query: str) -> list[str]:
    async with SessionLocal() as db:
        return [artist.name for artist in await search.artists(db, query, 20)]


async def _albums(query: str) -> list[str]:
    async with SessionLocal() as db:
        return [album.title for album in await search.albums(db, query, 20)]


@pytest.mark.parametrize(
    ("query", "first"),
    [
        # Song and artist together, in either order and with joining words or punctuation in between.
        ("bohemian queen", "Bohemian Rhapsody"),
        ("queen bohemian rhapsody", "Bohemian Rhapsody"),
        ("Bohemian Rhapsody by Queen", "Bohemian Rhapsody"),
        ("bohemian rhapsody - queen", "Bohemian Rhapsody"),
        ("Queen – Bohemian Rhapsody", "Bohemian Rhapsody"),
        # Song and album.
        ("love of my life night at the opera", "Love of My Life"),
        # Accents, case and punctuation.
        ("beyonce halo", "Halo"),
        ("MOTORHEAD", "Ace of Spades"),
        ("acdc back in black", "Back in Black"),
        ("ac dc", "Back in Black"),
        ("dont stop me now", "Don't Stop Me Now"),
        ("simon and garfunkel boxer", "The Boxer"),
        ("lady gaga ft nobody", "Bad Romance"),
        # A joining word that is part of the title.
        ("stand by me", "Stand By Me"),
        # The exact title before titles that only start with it.
        ("love", "Love"),
        # Real words before letters that only run across word boundaries.
        ("love the", "The Love Cats (Live in Paris)"),
        # Only short words: titles and names starting with them.
        ("ha", "Halo"),
        # Near spellings when nothing matches as written.
        ("bohemian rapsody", "Bohemian Rhapsody"),
        ("metalica", "Master of Puppets"),
        # A band without letters.
        ("!!!", "Must Be the Moon"),
        # Umlauts written out, in the query or in the library.
        ("groenemeyer maenner", "Männer"),
        ("gronemeyer manner", "Männer"),
        ("schöne grüße ärzte", "Schoene Gruesse"),
        # Genre, year and decade among the words.
        ("queen 1975", "Bohemian Rhapsody"),
        ("hard rock 80s", "Back in Black"),
        ("acdc 80er", "Back in Black"),
        ("2008 pop", "Halo"),
        # Latin spellings of other scripts.
        ("gruppa krovi kino", "Группа крови"),
        ("tokyo jihen", "群青日和"),
    ],
)
async def test_tracks(library: None, query: str, first: str) -> None:
    titles = await _titles(query)
    assert titles and titles[0] == first, titles


async def test_ranking_and_nothing_found(library: None) -> None:
    assert (await _titles("love"))[:3] == ["Love", "Lovely Day", "Love of My Life"]
    assert set(await _titles("queen")) == {
        "Love of My Life",
        "Don't Stop Me Now",
        "Bohemian Rhapsody",
        "Killer Queen",
    }
    assert await _titles("xyzzy qwertz") == []
    assert await _artists("xyzzy qwertz") == []


async def test_artists_and_albums(library: None) -> None:
    assert await _artists("motorhead") == ["Motörhead"]
    assert await _artists("simon and garfunkel") == ["Simon & Garfunkel"]
    assert await _artists("metalica") == ["Metallica"]
    assert await _artists("!!!") == ["!!!"]
    # The artist's whole name in a longer query.
    assert "Queen" in await _artists("queen bohemian rhapsody")
    assert await _albums("opera queen") == ["A Night at the Opera"]
    assert await _albums("queen") == ["Jazz", "A Night at the Opera", "Bohemian Rhapsody (The Original Soundtrack)"]
    assert await _albums("sasha fierce beyonce") == ["I Am... Sasha Fierce"]


async def test_api(library: None, client: httpx.AsyncClient) -> None:
    headers = auth((await register(client, "searcher"))["token"])
    r = await client.get("/api/search", params={"q": "halo beyonce"}, headers=headers)
    assert r.status_code == 200
    assert [track["title"] for track in r.json()["tracks"]] == ["Halo"]
    r = await client.get("/api/search", params={"q": "is this just fantasy"}, headers=headers)
    assert [(hit["track"]["title"], hit["line"]) for hit in r.json()["lyrics"]] == [
        ("Bohemian Rhapsody", "Is this just fantasy?")
    ]


async def test_tags_and_scripts(library: None) -> None:
    assert await _titles("rock 1975") == ["Bohemian Rhapsody"]
    assert set(await _titles("rock")) == {"Bohemian Rhapsody", "Back in Black"}
    assert await _titles("queen 1980") == []
    assert await _albums("rock 70s") == ["A Night at the Opera"]
    assert await _artists("kino") == ["Кино"]
    assert await _artists("toukyou jihen") == ["東京事変"]
    assert await _albums("kino") == ["Группа крови"]


@pytest.mark.parametrize(
    ("years", "span"),
    [
        ("1985", (1985, 1985)),
        ("80s", (1980, 1989)),
        ("80's", (1980, 1989)),
        ("80er", (1980, 1989)),
        ("1990s", (1990, 1999)),
        ("00er", (2000, 2009)),
        ("2010s", (2010, 2019)),
        ("80", None),
        ("rock", None),
    ],
)
def test_years(years: str, span: tuple[int, int] | None) -> None:
    assert search.years(years) == span


async def test_lyrics(library: None) -> None:
    async with SessionLocal() as db:
        hits = await search.lyrics(db, "is this the real life")
        assert [(track.title, line) for track, line in hits] == [("Bohemian Rhapsody", "Is this the real life?")]
        # Over a line break, from synced lyrics without their timestamps, accents and punctuation aside.
        hits = await search.lyrics(db, "I built well baby")
        assert [(track.title, line) for track, line in hits] == [
            ("Halo", "Remember those walls I built / Well, baby, they're tumbling down")
        ]
        assert await search.lyrics(db, "real is this life") == []
        assert await search.lyrics(db, "landslide") == [], "single words are in too many songs"


async def test_latin_spellings_of_names_stored_before(library: None) -> None:
    async with SessionLocal() as db:
        artist = await db.scalar(select(Artist).where(Artist.name == "Кино"))
        assert artist is not None
        await db.execute(update(Artist).values(search_latin=None))
        await db.commit()
    assert "Кино" not in await _artists("kino")
    assert await search.backfill_latin() >= 2
    assert await search.backfill_latin() == 0
    assert await _artists("kino") == ["Кино"]
