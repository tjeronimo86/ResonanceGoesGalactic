"""Library search for artists, albums and songs.

Every word of the query has to appear somewhere: for a song in its title, artists or album ("bohemian queen"), for an
album in its title or artist. Accents, case and punctuation do not matter ("motorhead" finds "Motörhead", "acdc" finds
"AC/DC", "dont stop" finds "Don't Stop"), and joining words such as "by", "feat." or "&" may be left out or added
("Bohemian Rhapsody by Queen", "Simon and Garfunkel" for "Simon & Garfunkel"). Results are ranked by how well they match
(the exact title first, then titles starting with the query, then the rest). When nothing matches at all, near spellings
are tried ("metalica", "bohemian rapsody").

Also: German umlauts written out ("mueller" for "Müller" and the other way round), a genre, year or decade among the
words ("rock 1985", "queen 70s", "80er"), Latin spellings of other scripts ("kino" for "Кино", "tokyo jihen" for
"東京事変", stored by app.transliterate), and lines of the songs' lyrics ("is this the real life").
"""

import asyncio
import logging
import re
from collections.abc import Callable, Sequence
from itertools import pairwise

from sqlalchemy import (
    ColumnElement,
    CompoundSelect,
    Select,
    and_,
    case,
    func,
    intersect,
    literal,
    literal_column,
    or_,
    select,
    union,
    update,
)
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionLocal
from app.models import Album, Artist, Track
from app.models.library import TrackLyrics, compact_text, search_fold
from app.services.views import album_options, track_options
from app.transliterate import fold, latin

log = logging.getLogger(__name__)

# Words that join a title and an artist or two artists. Not required to match, but kept in the ranking.
_JOINERS = frozenset(
    {
        "by",
        "von",
        "feat",
        "ft",
        "featuring",
        "with",
        "mit",
        "and",
        "und",
        "x",
        "vs",
        "versus",
        "presents",
        "pres",
    }
)
# Trigram indexes need words of 3 letters; shorter ones cannot be told apart from typos either. A query of only short
# words ("a", "u2", "ac dc") matches titles and names that start with it, through the prefix indexes.
_SHORT = 3


_UMLAUTS = str.maketrans({"ä": "ae", "ö": "oe", "ü": "ue"})


def words(query: str) -> list[str]:
    """The words of the query that have to match: those with letters or digits, joining words only if alone."""
    found = [word for word in query.split() if fold(word)]
    required = [word for word in found if fold(word) not in _JOINERS]
    return required or found


def _compact(value: str) -> ColumnElement[str]:
    return compact_text(literal(value))


# A searchable field: its stored search key (Track.title_search, ...) and the text it is made from (Track.title).
type Field = tuple[ColumnElement[str], ColumnElement[str]]
_ARTIST: Field = (Artist.name_search, Artist.name)
_ALBUM: Field = (Album.title_search, Album.title)
_TITLE: Field = (Track.title_search, Track.title)
_CREDIT: Field = (Track.credit_search, Track.artist_credit)


def _plain(key: ColumnElement[str]) -> ColumnElement[str]:
    """The compact form of the text: a search key starts with it (umlauts written out may follow after a space)."""
    return func.split_part(key, " ", 1)


def _contains(key: ColumnElement[str], word: str) -> ColumnElement[bool]:
    """`word` appears in the key; keys have umlauts in both spellings, and a word typed with umlauts is also looked
    for written out ("müller" finds "Mueller")."""
    needles = dict.fromkeys([word, word.lower().translate(_UMLAUTS)])
    return or_(*(key.contains(_compact(needle)) for needle in needles))


def _near(column: ColumnElement[str], word: str) -> ColumnElement[bool]:
    """`word` is close to a word of `column` (pg_trgm's word similarity, by default at least 0.6)."""
    return search_fold(literal(word)).op("<%")(search_fold(column))


def _word_match(fields: Sequence[Field], word: str, fuzzy: bool) -> ColumnElement[bool]:
    matches = [_contains(key, word) for key, _ in fields]
    if fuzzy and len(fold(word)) >= _SHORT:
        matches += [_near(source, word) for _, source in fields]
    return or_(*matches)


def _rank(title_key: ColumnElement[str], other_key: ColumnElement[str] | None, query: str) -> ColumnElement[int]:
    """How well the whole query matches: as the title, as title and artist together, at the start, anywhere."""
    title = _plain(title_key)
    other = None if other_key is None else _plain(other_key)
    variants = {fold(query), "".join(fold(word) for word in words(query))}
    ranks = []
    for variant in variants:
        q = _compact(variant) if variant else literal("")
        both = [] if other is None else [func.concat(other, title), func.concat(title, other)]
        whens = [(title == q, 100)]
        whens += [(or_(*(b == q for b in both)), 95)] if both else []
        whens += [(title.startswith(q), 70)]
        whens += [(or_(*(b.startswith(q) for b in both)), 65)] if both else []
        whens += [(title.contains(q), 50)]
        if other is not None:
            whens += [(other == q, 40), (other.contains(q), 30)]
        ranks.append(case(*whens, else_=0))
    return func.greatest(*ranks) if len(ranks) > 1 else ranks[0]


def _word_starts(fields: Sequence[tuple[ColumnElement[str], int]], query: str) -> ColumnElement[int]:
    """Points for each query word that starts a word of a field, by the best field: the compact matching also finds
    words across word boundaries ("the" in "Night Heart"), which this ranks below real words. A word counts once,
    so "Killer Queen" by Queen does not outrank "Bohemian Rhapsody" by Queen for "bohemian queen". Only for ordering,
    so lower() instead of folding every row: accented words just miss these points."""
    points = [
        case(
            *((func.lower(column).regexp_match(literal(rf"\m{fold(word)}")), weight) for column, weight in fields),
            else_=0,
        )
        for word in words(query)
    ]
    return sum(points[1:], points[0]) if points else literal(0)


def _punctuation_only(column: ColumnElement[str], query: str) -> ColumnElement[bool]:
    """A query without letters or digits, e.g. the band "!!!", matches as written."""
    return search_fold(column).contains(search_fold(literal(query.strip())))


_YEAR = re.compile(r"(19|20)\d\d")
_DECADE = re.compile(r"(19|20)?(\d)0(s|er)")


def years(word: str) -> tuple[int, int] | None:
    """A year ("1985") or a decade ("1980s", "80s", "80's", "80er", "2000er") as a range of years."""
    folded = fold(word)
    if _YEAR.fullmatch(folded):
        return int(folded), int(folded)
    if match := _DECADE.fullmatch(folded):
        century, decade = match[1], int(match[2])
        start = int(century) * 100 + decade * 10 if century else (1900 if decade >= 3 else 2000) + decade * 10
        return start, start + 9
    return None


def _tags(year: ColumnElement[int], genre_key: ColumnElement[str], word: str) -> ColumnElement[bool]:
    """The word names the year or decade or is part of the genre."""
    span = years(word)
    return year.between(*span) if span else _contains(genre_key, word)


# Per word the ids matching in each field, united; across words intersected. Each part can use its own index; one OR
# over columns of different tables (or a subquery) would make Postgres read every song instead.
def _track_ids(word: str, fuzzy: bool) -> CompoundSelect:
    return union(
        select(Track.id).where(_word_match([_TITLE], word, fuzzy)),
        select(Track.id).where(_word_match([_CREDIT], word, fuzzy)),
        select(Track.id).where(_contains(Track.search_latin, word)),
        select(Track.id).where(_tags(Track.year, Track.genre_search, word)),
        select(Track.id).join(Album, Album.id == Track.album_id).where(_word_match([_ALBUM], word, fuzzy)),
    )


def _album_ids(word: str, fuzzy: bool) -> CompoundSelect:
    return union(
        select(Album.id).where(_word_match([_ALBUM], word, fuzzy)),
        select(Album.id).where(_contains(Album.search_latin, word)),
        select(Album.id).where(_tags(Album.year, Album.genre_search, word)),
        select(Album.id)
        .join(Artist, Artist.id == Album.artist_id)
        .where(or_(_word_match([_ARTIST], word, fuzzy), _contains(Artist.search_latin, word))),
    )


def _long(found: list[str]) -> list[str]:
    return [word for word in found if len(fold(word)) >= _SHORT]


def _matching(found: list[str], ids: Callable[[str], CompoundSelect]) -> CompoundSelect:
    """Ids matching every long word (through the indexes); short words then only filter those rows."""
    long = _long(found)
    return ids(long[0]) if len(long) == 1 else intersect(*(ids(word) for word in long))


def _starts(key: ColumnElement[str], query: str) -> ColumnElement[bool]:
    return key.startswith(_compact(query))


def artist_query(query: str, fuzzy: bool = False) -> Select[tuple[Artist]]:
    found = words(query)
    if query.strip() and not found:
        where = _punctuation_only(Artist.name, query)
    elif found and not _long(found):
        where = _starts(Artist.name_search, query)
    elif found:
        where = and_(
            *(or_(_word_match([_ARTIST], word, fuzzy), _contains(Artist.search_latin, word)) for word in found)
        )
        if not fuzzy and len(found) > 1:
            # "queen bohemian rhapsody" also shows Queen: the artist's whole name is part of the query.
            name = _plain(Artist.name_search)
            where = or_(where, and_(func.length(name) >= 3, _compact(query).contains(name)))
    else:
        where = literal(True)
    rank = _rank(Artist.name_search, None, query)
    if fuzzy:
        rank = func.word_similarity(search_fold(literal(query)), search_fold(Artist.name))
    starts = _word_starts([(Artist.name, 1)], query)
    return (
        select(Artist)
        .where(where)
        .order_by(rank.desc(), starts.desc(), func.length(Artist.name), Artist.name, Artist.id)
    )


def album_query(query: str, fuzzy: bool = False) -> Select[tuple[Album]]:
    found = words(query)
    stmt = select(Album).options(*album_options()).join(Artist, Album.artist_id == Artist.id)
    if query.strip() and not found:
        stmt = stmt.where(_punctuation_only(Album.title, query))
    elif found and not _long(found):
        stmt = stmt.where(
            Album.id.in_(
                union(
                    select(Album.id).where(_starts(Album.title_search, query)),
                    select(Album.id)
                    .join(Artist, Artist.id == Album.artist_id)
                    .where(_starts(Artist.name_search, query)),
                )
            )
        )
    elif found:
        stmt = stmt.where(Album.id.in_(_matching(found, lambda word: _album_ids(word, fuzzy))))
        for word in found:
            if word not in _long(found):
                stmt = stmt.where(or_(_contains(Album.title_search, word), _contains(Artist.name_search, word)))
    rank = _rank(Album.title_search, Artist.name_search, query)
    if fuzzy:
        rank = func.word_similarity(search_fold(literal(query)), search_fold(Album.title + " " + Artist.name))
    starts = _word_starts([(Album.title, 2), (Artist.name, 1)], query)
    return stmt.order_by(rank.desc(), starts.desc(), func.length(Album.title), Album.title, Album.id)


def track_query(query: str, fuzzy: bool = False) -> Select[tuple[Track]]:
    found = words(query)
    stmt = select(Track).options(*track_options())
    if query.strip() and not found:
        stmt = stmt.where(or_(_punctuation_only(Track.title, query), _punctuation_only(Track.artist_credit, query)))
    elif found and not _long(found):
        stmt = stmt.where(
            Track.id.in_(
                union(
                    select(Track.id).where(_starts(Track.title_search, query)),
                    select(Track.id).where(_starts(Track.credit_search, query)),
                    select(Track.id).join(Album, Album.id == Track.album_id).where(_starts(Album.title_search, query)),
                )
            )
        )
    elif found:
        stmt = stmt.where(Track.id.in_(_matching(found, lambda word: _track_ids(word, fuzzy))))
        for word in found:
            if word not in _long(found):
                on_album = select(Album.id).where(_contains(Album.title_search, word))
                stmt = stmt.where(
                    or_(
                        _contains(Track.title_search, word),
                        _contains(Track.credit_search, word),
                        Track.album_id.in_(on_album),
                    )
                )
    rank = _rank(Track.title_search, Track.credit_search, query)
    if fuzzy:
        rank = func.word_similarity(search_fold(literal(query)), search_fold(Track.title + " " + Track.artist_credit))
    starts = _word_starts([(Track.title, 2), (Track.artist_credit, 1)], query)
    return stmt.order_by(rank.desc(), starts.desc(), func.length(Track.title), Track.title, Track.id)


async def _find[T](db: AsyncSession, build, query: str, limit: int, offset: int) -> list[T]:
    rows = list(await db.scalars(build(query).offset(offset).limit(limit)))
    if rows or offset or not _long(words(query)):
        return rows
    return list(await db.scalars(build(query, fuzzy=True).limit(limit)))


async def artists(db: AsyncSession, query: str, limit: int, offset: int = 0) -> list[Artist]:
    return await _find(db, artist_query, query, limit, offset)


async def albums(db: AsyncSession, query: str, limit: int, offset: int = 0) -> list[Album]:
    return await _find(db, album_query, query, limit, offset)


async def tracks(db: AsyncSession, query: str, limit: int, offset: int = 0) -> list[Track]:
    return await _find(db, track_query, query, limit, offset)


# --- lyrics -------------------------------------------------------------------------------------------------------

_STAMP = re.compile(r"\[[^\]]*\]|<\d+:\d{2}(?:\.\d+)?>")
# A line of lyrics needs a few words: single words are in too many songs to tell anything.
LYRICS_MIN_WORDS = 2


def _lyrics_line(text: str, query: str) -> str:
    """The line (or two, when the phrase runs over a line break) the query was found in."""
    wanted = [fold(word) for word in query.split() if fold(word)]
    phrase = "".join(wanted)
    lines = [line for raw in text.splitlines() if (line := _STAMP.sub("", raw).strip())]
    for line in lines:
        if phrase in fold(line):
            return line
    for line, following in pairwise(lines):
        if phrase in fold(line + following):
            return f"{line} / {following}"
    return max(lines, key=lambda line: sum(word in fold(line) for word in wanted), default="")


async def lyrics(db: AsyncSession, query: str, limit: int = 10) -> list[tuple[Track, str]]:
    """Songs whose cached lyrics contain the query as a phrase, with the line it is in."""
    if len([word for word in query.split() if fold(word)]) < LYRICS_MIN_WORDS:
        return []
    phrase = func.phraseto_tsquery(literal_column("'simple'::regconfig"), search_fold(literal(query)))
    vector = TrackLyrics.search_vector
    rows = await db.execute(
        select(Track, TrackLyrics.plain, TrackLyrics.synced)
        .join(TrackLyrics, TrackLyrics.track_id == Track.id)
        .options(*track_options())
        .where(vector.op("@@")(phrase), Track.is_temporary.is_(False))
        .order_by(func.ts_rank_cd(vector, phrase).desc(), Track.title, Track.id)
        .limit(limit)
    )
    return [(track, _lyrics_line(plain or synced or "", query)) for track, plain, synced in rows]


# --- Latin spellings of existing names ------------------------------------------------------------------------------

_task: asyncio.Task | None = None
_BATCH = 500


async def backfill_latin() -> int:
    """Fills search_latin for names and titles stored before it existed (new ones get it when saved)."""
    done = 0
    for model, fields in ((Artist, ("name",)), (Album, ("title",)), (Track, ("title", "artist_credit"))):
        columns = [getattr(model, field) for field in fields]
        while True:
            async with SessionLocal() as db:
                rows = (
                    await db.execute(
                        select(model.id, *columns)
                        .where(
                            model.search_latin.is_(None),
                            # Only text with characters beyond ASCII can be in another script.
                            or_(*(column.regexp_match(r"[^\x01-\x7f]") for column in columns)),
                        )
                        .limit(_BATCH)
                    )
                ).all()
                if not rows:
                    break
                texts = [" ".join(value or "" for value in row[1:]) for row in rows]
                spelled = await asyncio.to_thread(lambda texts=texts: [latin(text) for text in texts])
                await db.execute(
                    update(model),
                    [{"id": row[0], "search_latin": value or ""} for row, value in zip(rows, spelled, strict=True)],
                )
                await db.commit()
                done += len(rows)
    return done


async def _backfill() -> None:
    try:
        if count := await backfill_latin():
            log.info("Search: Latin spellings checked for %d names and titles", count)
    except Exception:
        log.exception("Search: filling in Latin spellings failed")


async def start() -> None:
    global _task
    if _task is None or _task.done():
        _task = asyncio.create_task(_backfill())


async def stop() -> None:
    global _task
    if _task is not None:
        _task.cancel()
        await asyncio.gather(_task, return_exceptions=True)
        _task = None
