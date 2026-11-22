import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    ColumnElement,
    Computed,
    DateTime,
    Float,
    ForeignKey,
    Index,
    LargeBinary,
    String,
    Text,
    event,
    false,
    func,
    inspect,
    literal_column,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, TSVECTOR
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base
from app.transliterate import latin

# search_fold(): lower case without accents ("Motörhead" -> "motorhead", "Straße" -> "strasse"). unaccent() itself is
# only STABLE (its dictionary could change); this IMMUTABLE wrapper with a fixed dictionary can be indexed.
# search_key(): what words are searched in, letters and digits only; text with German umlauts in both spellings
# ("Müller" -> "muller mueller"), so that "muller", "mueller" and "müller" all find it.
SEARCH_FOLD_DDL = (
    "CREATE EXTENSION IF NOT EXISTS unaccent",
    (
        "CREATE OR REPLACE FUNCTION search_fold(text) RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT "
        "AS $$ SELECT lower(public.unaccent('public.unaccent'::regdictionary, $1)) $$"
    ),
    (
        "CREATE OR REPLACE FUNCTION search_key(text) RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS $$ "
        "SELECT CASE WHEN a = b THEN a ELSE a || ' ' || b END FROM (SELECT "
        "regexp_replace(public.search_fold($1), '[^[:alnum:]]+', '', 'g') AS a, "
        "regexp_replace(public.search_fold(replace(replace(replace(lower($1), 'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue')), "
        "'[^[:alnum:]]+', '', 'g') AS b) AS forms $$"
    ),
)


LYRICS_VECTOR = (
    "to_tsvector('simple'::regconfig, public.search_fold(coalesce(plain, "
    "regexp_replace(synced, '\\[[^]]*\\]', ' ', 'g'))))"
)


def search_fold(column: ColumnElement[str]) -> ColumnElement[str]:
    return func.search_fold(column, type_=Text)


def search_key(column: ColumnElement[str]) -> ColumnElement[str]:
    return func.search_key(column, type_=Text)


def compact_text(column: ColumnElement[str]) -> ColumnElement[str]:
    """Letters and digits only, without accents (search queries; stored text has its *_search columns)."""
    return func.regexp_replace(
        search_fold(column), literal_column("'[^[:alnum:]]+'"), literal_column("''"), literal_column("'g'"), type_=Text
    )


def _search_key(source: str):
    """search_key() of a column, stored: searching compares stored text instead of folding every row again."""
    return mapped_column(Text, Computed(f"search_key({source})", persisted=True), deferred=True)


def _key_indexes(table: str, key: str, prefix: bool = True) -> list[Index]:
    """Trigram index for words anywhere in a stored key; sorted, for queries too short for trigrams, which match at the
    start (the key starts with the plain compact form)."""
    indexes = [Index(f"ix_{table}_{key}_trgm", key, postgresql_using="gin", postgresql_ops={key: "gin_trgm_ops"})]
    if prefix:
        indexes.append(Index(f"ix_{table}_{key}_prefix", key, postgresql_ops={key: "text_pattern_ops"}))
    return indexes


def _fold_index(table: str, column: str) -> Index:
    """Trigram index on the folded text, for near spellings (word similarity needs the spaces between words)."""
    return Index(f"ix_{table}_{column}_trgm", text(f"search_fold({column}) gin_trgm_ops"), postgresql_using="gin")


class Artist(Base):
    __tablename__ = "artists"
    __table_args__ = (
        _fold_index("artists", "name"),
        *_key_indexes("artists", "name_search"),
        *_key_indexes("artists", "search_latin", prefix=False),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(512))
    # For search: the name as search_key(), and its Latin spellings when it is in another script (compact, see
    # app.transliterate; "" when there are none).
    name_search: Mapped[str | None] = _search_key("name")
    search_latin: Mapped[str | None] = mapped_column(String(2048), deferred=True)
    # Lower-cased name used for matching when no MusicBrainz ID is available.
    name_key: Mapped[str] = mapped_column(String(512), unique=True)
    sort_name: Mapped[str | None] = mapped_column(String(512))
    mb_artist_id: Mapped[str | None] = mapped_column(String(36), index=True)
    image_path: Mapped[str | None] = mapped_column(Text)
    bio_de: Mapped[str | None] = mapped_column(Text)
    bio_en: Mapped[str | None] = mapped_column(Text)
    info_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Last.fm's top tags for the artist ({"deep house": 100, "house": 79, ...}); genre mixes check songs against them.
    lastfm_tags: Mapped[dict | None] = mapped_column(JSONB)
    lastfm_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    albums: Mapped[list["Album"]] = relationship(back_populates="artist")


class Album(Base):
    __tablename__ = "albums"
    __table_args__ = (
        Index("ix_albums_artist_key", "artist_id", "title_key", unique=True),
        _fold_index("albums", "title"),
        *_key_indexes("albums", "title_search"),
        *_key_indexes("albums", "genre_search", prefix=False),
        *_key_indexes("albums", "search_latin", prefix=False),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(512))
    title_key: Mapped[str] = mapped_column(String(512))
    artist_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("artists.id", ondelete="CASCADE"), index=True)
    search_latin: Mapped[str | None] = mapped_column(String(2048), deferred=True)
    year: Mapped[int | None] = mapped_column(index=True)
    genre: Mapped[str | None] = mapped_column(String(256))
    title_search: Mapped[str | None] = _search_key("title")
    genre_search: Mapped[str | None] = _search_key("genre")
    mb_release_id: Mapped[str | None] = mapped_column(String(36), index=True)
    # Cached, normalised cover image (relative to the cover cache dir).
    cover_file: Mapped[str | None] = mapped_column(String(128))

    @property
    def cover_key(self) -> str | None:
        """Short version of the cover (its content hash), for clients' caches."""
        return self.cover_file[:12] if self.cover_file else None

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    artist: Mapped[Artist] = relationship(back_populates="albums")
    tracks: Mapped[list["Track"]] = relationship(back_populates="album")


class Track(Base):
    __tablename__ = "tracks"
    # text_pattern_ops also serves equality; LIKE 'prefix%' needs it unless the database uses the C collation.
    __table_args__ = (
        Index("ix_tracks_lower_title", text("lower(title) text_pattern_ops")),
        _fold_index("tracks", "title"),
        _fold_index("tracks", "artist_credit"),
        *_key_indexes("tracks", "title_search"),
        *_key_indexes("tracks", "credit_search"),
        *_key_indexes("tracks", "genre_search", prefix=False),
        *_key_indexes("tracks", "search_latin", prefix=False),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    path: Mapped[str] = mapped_column(Text, unique=True)
    title: Mapped[str] = mapped_column(String(512))
    album_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("albums.id", ondelete="CASCADE"), index=True)
    artist_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("artists.id", ondelete="CASCADE"), index=True)
    # Full credited artist string as tagged, e.g. "A feat. B".
    artist_credit: Mapped[str] = mapped_column(String(1024))
    # Latin spelling of title and artists in another script, for search (app.transliterate; "" when there is none).
    search_latin: Mapped[str | None] = mapped_column(String(2048), deferred=True)
    track_no: Mapped[int | None]
    disc_no: Mapped[int | None]
    duration: Mapped[float] = mapped_column(Float, default=0)
    year: Mapped[int | None] = mapped_column(index=True)
    genre: Mapped[str | None] = mapped_column(String(256))
    title_search: Mapped[str | None] = _search_key("title")
    credit_search: Mapped[str | None] = _search_key("artist_credit")
    genre_search: Mapped[str | None] = _search_key("genre")
    codec: Mapped[str | None] = mapped_column(String(32))
    bitrate: Mapped[int | None]
    sample_rate: Mapped[int | None]
    size: Mapped[int] = mapped_column(BigInteger, default=0)
    mtime: Mapped[float] = mapped_column(Float, default=0)
    mb_recording_id: Mapped[str | None] = mapped_column(String(36), index=True)
    isrc: Mapped[str | None] = mapped_column(String(16), index=True)
    replaygain_track_gain: Mapped[float | None]
    replaygain_album_gain: Mapped[float | None]
    # Radio auto-downloads are temporary until liked / added to a playlist (phase 5).
    is_temporary: Mapped[bool] = mapped_column(default=False)
    reviewed: Mapped[bool] = mapped_column(default=False, server_default=false())
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    album: Mapped[Album] = relationship(back_populates="tracks")
    artist: Mapped[Artist] = relationship()


class TrackLyrics(Base):
    __tablename__ = "track_lyrics"

    track_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)
    synced: Mapped[str | None] = mapped_column(Text)
    plain: Mapped[str | None] = mapped_column(Text)
    instrumental: Mapped[bool] = mapped_column(default=False)
    source: Mapped[str] = mapped_column(String(16))
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    # Words of the lyrics for searching them (without timestamps, accents and case); stored so that phrase matches
    # are checked without reading every song's lyrics again.
    search_vector: Mapped[str | None] = mapped_column(TSVECTOR, Computed(LYRICS_VECTOR, persisted=True), deferred=True)

    __table_args__ = (Index("ix_track_lyrics_search_vector", "search_vector", postgresql_using="gin"),)


class TrackCredits(Base):
    """Who wrote, produced and played a song: from its tags and MusicBrainz, fetched when first asked for."""

    __tablename__ = "track_credits"

    track_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)
    data: Mapped[dict] = mapped_column(JSONB)
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class TrackFingerprint(Base):
    __tablename__ = "track_fingerprints"

    track_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)
    mtime: Mapped[float] = mapped_column(Float)
    fingerprint: Mapped[bytes | None] = mapped_column(LargeBinary)
    failed: Mapped[bool] = mapped_column(default=False, server_default=false())


class TrackMixPoints(Base):
    """AutoMix analysis of a track's file (tempo and where to mix in and out)."""

    __tablename__ = "track_mixpoints"

    track_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)
    version: Mapped[int]
    # The file's mtime when analyzed; a changed file is analyzed again.
    mtime: Mapped[float] = mapped_column(Float)
    failed: Mapped[bool] = mapped_column(default=False, server_default=false())
    bpm: Mapped[float | None] = mapped_column(Float)
    key: Mapped[str | None] = mapped_column(String(3))
    key_confidence: Mapped[float | None] = mapped_column(Float)
    mix_in: Mapped[float | None] = mapped_column(Float)
    mix_out: Mapped[float | None] = mapped_column(Float)
    end: Mapped[float | None] = mapped_column(Float)
    intro_end: Mapped[float | None] = mapped_column(Float)
    downbeat: Mapped[float | None] = mapped_column(Float)
    phrases: Mapped[list | None] = mapped_column(JSONB)
    energy: Mapped[float | None] = mapped_column(Float)
    analyzed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class TrackVocals(Base):
    """Where a track's voice starts and ends, from a stem separation of its intro and outro (optional song analysis
    for AutoMix). Without a voice in a part, the bound is the edge of the analyzed window."""

    __tablename__ = "track_vocals"

    track_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)
    version: Mapped[int]
    mtime: Mapped[float] = mapped_column(Float)
    failed: Mapped[bool] = mapped_column(default=False, server_default=false())
    vocals_in: Mapped[float | None] = mapped_column(Float)
    vocals_out: Mapped[float | None] = mapped_column(Float)
    # Why the analysis failed (the worker's message), for admins.
    error: Mapped[str | None] = mapped_column(String(500))
    analyzed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


def _latin_on_change(model: type, *fields: str) -> None:
    """Keeps search_latin in step with the fields it is spelled from; "" marks text that needs none."""

    def refresh(_mapper, _connection, target) -> None:
        state = inspect(target)
        if state.persistent and not any(state.attrs[field].history.has_changes() for field in fields):
            return
        target.search_latin = latin(" ".join(getattr(target, field) or "" for field in fields))

    event.listen(model, "before_insert", refresh)
    event.listen(model, "before_update", refresh)


_latin_on_change(Artist, "name")
_latin_on_change(Album, "title")
_latin_on_change(Track, "title", "artist_credit")
