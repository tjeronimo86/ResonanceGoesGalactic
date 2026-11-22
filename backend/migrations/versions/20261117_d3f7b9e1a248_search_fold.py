"""search: without accents and with umlauts written out, Latin spellings of other scripts, genres and years, lyrics

"motorhead" finds "Motörhead", "mueller" finds "Müller", "kino" finds "Кино" (search_latin, filled by the server in the
background for existing names), "rock 1985" filters by genre and year, and lines of cached lyrics are searchable.

Revision ID: d3f7b9e1a248
Revises: b6d2f8a4c917
Create Date: 2026-11-17
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "d3f7b9e1a248"
down_revision: str | Sequence[str] | None = "b6d2f8a4c917"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# As app.models.library.SEARCH_FOLD_DDL and LYRICS_VECTOR at the time of writing.
_FUNCTIONS = (
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
_LYRICS_VECTOR = (
    "to_tsvector('simple'::regconfig, public.search_fold(coalesce(plain, "
    r"regexp_replace(synced, '\[[^]]*\]', ' ', 'g'))))"
)
_COLUMNS = (("artists", "name"), ("albums", "title"), ("tracks", "title"), ("tracks", "artist_credit"))
# Stored search keys: (table, key column, source column, with a prefix index for short queries).
_KEYS = (
    ("artists", "name_search", "name", True),
    ("albums", "title_search", "title", True),
    ("albums", "genre_search", "genre", False),
    ("tracks", "title_search", "title", True),
    ("tracks", "credit_search", "artist_credit", True),
    ("tracks", "genre_search", "genre", False),
)
_LATIN = ("artists", "albums", "tracks")


def _trigram(name: str, table: str, expression: str) -> None:
    op.create_index(name, table, [sa.text(f"{expression} gin_trgm_ops")], postgresql_using="gin")


def upgrade() -> None:
    for statement in _FUNCTIONS:
        op.execute(statement)
    for table, column in _COLUMNS:
        op.drop_index(f"ix_{table}_{column}_compact_trgm", table_name=table)
        op.drop_index(f"ix_{table}_{column}_trgm", table_name=table)
        # Near spellings compare words, so this one keeps the spaces.
        _trigram(f"ix_{table}_{column}_trgm", table, f"search_fold({column})")
    for table, key, source, prefix in _KEYS:
        op.add_column(table, sa.Column(key, sa.Text(), sa.Computed(f"search_key({source})", persisted=True)))
        _trigram(f"ix_{table}_{key}_trgm", table, key)
        if prefix:
            # Queries too short for trigrams ("a", "u2") match at the start.
            op.create_index(f"ix_{table}_{key}_prefix", table, [sa.text(f"{key} text_pattern_ops")])
    for table in _LATIN:
        # Filled by the server in the background (app.services.search.backfill_latin) and whenever a name is saved.
        op.add_column(table, sa.Column("search_latin", sa.String(2048), nullable=True))
        _trigram(f"ix_{table}_search_latin_trgm", table, "search_latin")
    for table in ("albums", "tracks"):
        op.create_index(f"ix_{table}_year", table, ["year"])
    op.add_column(
        "track_lyrics",
        sa.Column("search_vector", postgresql.TSVECTOR(), sa.Computed(_LYRICS_VECTOR, persisted=True), nullable=True),
    )
    op.create_index("ix_track_lyrics_search_vector", "track_lyrics", ["search_vector"], postgresql_using="gin")


def downgrade() -> None:
    op.drop_index("ix_track_lyrics_search_vector", table_name="track_lyrics")
    op.drop_column("track_lyrics", "search_vector")
    for table in ("albums", "tracks"):
        op.drop_index(f"ix_{table}_year", table_name=table)
    for table in _LATIN:
        op.drop_index(f"ix_{table}_search_latin_trgm", table_name=table)
        op.drop_column(table, "search_latin")
    for table, key, _source, prefix in _KEYS:
        if prefix:
            op.drop_index(f"ix_{table}_{key}_prefix", table_name=table)
        op.drop_index(f"ix_{table}_{key}_trgm", table_name=table)
        op.drop_column(table, key)
    for table, column in _COLUMNS:
        op.drop_index(f"ix_{table}_{column}_trgm", table_name=table)
        _trigram(f"ix_{table}_{column}_trgm", table, column)
        _trigram(
            f"ix_{table}_{column}_compact_trgm", table, rf"regexp_replace(lower({column}), '[^[\:alnum\:]]+', '', 'g')"
        )
    op.execute("DROP FUNCTION search_key(text)")
    op.execute("DROP FUNCTION search_fold(text)")
