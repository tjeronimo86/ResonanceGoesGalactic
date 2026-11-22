import asyncio
import uuid
from io import BytesIO

import pytest
from PIL import Image
from sqlalchemy import func, literal_column, select

from app.db import engine
from app.models.library import TrackLyrics
from app.services import covers, search


async def _plan(query) -> str:
    sql = str(query.compile(dialect=engine.dialect, compile_kwargs={"literal_binds": True}))
    async with engine.begin() as conn:
        # The table is empty here: without these the planner may just walk any index.
        await conn.exec_driver_sql("SET LOCAL enable_seqscan = off")
        await conn.exec_driver_sql("SET LOCAL enable_indexscan = off")
        return "\n".join(row[0] for row in await conn.exec_driver_sql("EXPLAIN " + sql))


@pytest.mark.parametrize("fuzzy", [False, True])
async def test_track_search_uses_every_trigram_index(fuzzy: bool) -> None:
    plan = await _plan(search.track_query("ab12 cdef", fuzzy=fuzzy))
    indexes = ["ix_tracks_title_search_trgm", "ix_tracks_credit_search_trgm", "ix_albums_title_search_trgm"]
    indexes += ["ix_tracks_search_latin_trgm", "ix_tracks_genre_search_trgm"]
    if fuzzy:
        indexes += ["ix_tracks_title_trgm", "ix_tracks_artist_credit_trgm", "ix_albums_title_trgm"]
    for index in indexes:
        assert index in plan, plan


async def test_year_and_lyrics_search_use_their_indexes() -> None:
    assert "ix_tracks_year" in await _plan(search.track_query("1985 cdef"))
    phrase = func.phraseto_tsquery(literal_column("'simple'::regconfig"), "is this the real life")
    plan = await _plan(select(TrackLyrics.track_id).where(TrackLyrics.search_vector.op("@@")(phrase)))
    assert "ix_track_lyrics_search_vector" in plan, plan


async def test_short_track_search_uses_the_prefix_indexes() -> None:
    plan = await _plan(search.track_query("u2"))
    for index in ("ix_tracks_title_search_prefix", "ix_tracks_credit_search_prefix", "ix_albums_title_search_prefix"):
        assert index in plan, plan


async def test_concurrent_resizes_leave_one_complete_file() -> None:
    image = BytesIO()
    Image.effect_noise((800, 800), uuid.uuid4().int % 90 + 10).convert("RGB").save(image, "PNG")
    name = covers.store(image.getvalue())

    paths = await asyncio.gather(*(asyncio.to_thread(covers.resized, name, 64) for _ in range(8)))

    assert len(set(paths)) == 1
    with Image.open(paths[0]) as resized:
        resized.load()
        assert max(resized.size) == 64
    assert not list(paths[0].parent.glob("*.part"))
