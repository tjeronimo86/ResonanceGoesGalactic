import asyncio
import shutil
import uuid
import wave
from datetime import UTC, datetime, timedelta
from pathlib import Path

import numpy as np
import pytest
from sqlalchemy import select

from app.db import Base, SessionLocal, engine
from app.models import Album, Artist, Track, TrackLyrics, TrackMixPoints
from app.services import mixpoints
from tests.conftest import MUSIC_DIR, auth, register

RATE = 22050


@pytest.mark.parametrize("synced, duration, expected", [
    ("[00:10.250]First\n[00:13.750]Second\n[00:18.250]Last", 40, (10.25, 22.25)),
    ("[00:01]♪\n[00:02]…\n[00:10]First\n[00:11] \n[00:14]Second\n[00:16]♪ …\n[00:18]Last\n[00:30]", 40, (10, 22)),
    ("[00:10]First\n[00:11]Second\n[00:12]Last", 40, (10, 14)),
    ("[00:10]First\n[00:20]Second\n[00:30]Last", 40, (10, 36)),
    ("[00:10]First\n[00:14]Second\n[00:18]Third\n[00:30]Last", 50, (10, 34)),
    ("[00:10]First\n[00:14]Second\n[00:18]Third\n[00:38]Last", 40, (10, 40)),
    ("[offset:500]\n[00:18]Last\n[00:10][00:14]Repeated", 40, (9.5, 21.5)),
])
def test_vocal_bounds_estimate_last_line_from_median_gap(synced, duration, expected) -> None:
    assert mixpoints._vocal_bounds(synced, duration) == expected


@pytest.mark.parametrize("synced, instrumental", [
    (None, False),
    ("", False),
    ("First\nSecond\nLast", False),
    ("[00:10]First\n[00:14]Second", False),
    ("[00:01]♪\n[00:02]…\n[00:10]First\n[00:14]Second\n[00:18]♪ …\n[00:30] ", False),
    ("[00:10]First\n[00:14]Second\n[00:18]Last", True),
])
def test_vocal_bounds_require_at_least_three_synced_vocal_lines(synced, instrumental) -> None:
    assert mixpoints._vocal_bounds(synced, 40, instrumental=instrumental) == (None, None)


def beat_track(path: Path, *, bpm: float, seconds: float, lead: float = 0.0, tail: float = 0.0) -> Path:
    """Kick-like clicks on every beat plus a quiet hum, with optional leading/trailing silence."""
    t = np.arange(int(RATE * seconds)) / RATE
    audio = 0.05 * np.sin(2 * np.pi * 220 * t)
    period = 60 / bpm
    for start in np.arange(0, seconds, period):
        index = int(start * RATE)
        length = min(int(0.08 * RATE), len(audio) - index)
        envelope = np.exp(-np.arange(length) / (0.015 * RATE))
        audio[index : index + length] += 0.8 * envelope * np.sin(2 * np.pi * 60 * np.arange(length) / RATE)
    audio = np.concatenate([np.zeros(int(lead * RATE)), audio, np.zeros(int(tail * RATE))])
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((np.clip(audio, -1, 1) * 32767).astype("<i2").tobytes())
    return path


@pytest.mark.parametrize("bpm", [96.0, 124.0, 170.0])
def test_analyze_finds_tempo_and_beat_aligned_points(tmp_path: Path, bpm: float) -> None:
    points = mixpoints.analyze(beat_track(tmp_path / "beat.wav", bpm=bpm, seconds=90, lead=2.0, tail=3.0))
    assert points.bpm == pytest.approx(bpm, rel=0.02)
    period = 60 / bpm
    # The first beat after the silence, and a fade-out point on a beat before the audible end.
    assert points.mix_in == pytest.approx(2.0, abs=0.06)
    assert points.end == pytest.approx(92.0, abs=0.2)
    assert 70 < points.mix_out < points.end - 4
    phase = ((points.mix_out - 2.0) / period) % 1
    assert min(phase, 1 - phase) < 0.08
    # On a 16-beat phrase boundary counted from the first beat.
    phrase = ((points.mix_out - points.mix_in) / (16 * period)) % 1
    assert min(phrase, 1 - phrase) < 0.02


def test_analyze_finds_where_a_quiet_intro_ends(tmp_path: Path) -> None:
    bpm, bars = 120.0, 8
    path = beat_track(tmp_path / "intro.wav", bpm=bpm, seconds=90, lead=1.0)
    # The first eight bars at a quarter of the level (an intro), then the full song.
    with wave.open(str(path)) as source:
        audio = np.frombuffer(source.readframes(source.getnframes()), "<i2").astype(np.float64)
    intro = int((1.0 + bars * 4 * 60 / bpm) * RATE)
    audio[:intro] *= 0.25
    # One loud hit in the intro (a cymbal, a shout) does not end it.
    hit = int(1.5 * RATE)
    audio[hit : hit + RATE // 4] = 0.9 * 32767 * np.sin(2 * np.pi * 80 * np.arange(RATE // 4) / RATE)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(audio.astype("<i2").tobytes())
    points = mixpoints.analyze(path)
    assert points.intro_end == pytest.approx(points.mix_in + bars * 4 * 60 / bpm, abs=0.1)
    # A song that starts at full strength has no intro to play under the previous one.
    full = mixpoints.analyze(beat_track(tmp_path / "full.wav", bpm=bpm, seconds=60, lead=1.0))
    assert full.intro_end == pytest.approx(full.mix_in)


def test_analyze_short_or_silent_file(tmp_path: Path) -> None:
    path = tmp_path / "short.wav"
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"\0\0" * 100)
    points = mixpoints.analyze(path)
    assert points.bpm is None and points.key is None and points.key_confidence is None


def test_analyze_one_second_of_audio(tmp_path: Path) -> None:
    # A damaged file that decodes to only its first second (the rest of it is zeros).
    path = tmp_path / "damaged.wav"
    t = np.arange(RATE) / RATE
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((np.sin(2 * np.pi * 220 * t) * 12000).astype("<i2").tobytes())
    points = mixpoints.analyze(path)
    assert points.end <= 1.1 and points.mix_out <= points.end


async def test_crashing_analysis_is_stored_as_failed(monkeypatch: pytest.MonkeyPatch) -> None:
    def analyze(path):
        raise IndexError("index 42 is out of bounds")

    monkeypatch.setattr(mixpoints, "analyze", analyze)
    assert await mixpoints.analyze_async(Path("broken.mp3")) is None
    assert mixpoints._analysis_requests == 0


@pytest.mark.parametrize("notes, key", [([60, 64, 67], "8B"), ([57, 60, 64], "8A"), ([55, 59, 62], "9B")])
def test_analyze_finds_key(tmp_path: Path, notes: list[int], key: str) -> None:
    t = np.arange(RATE * 20) / RATE
    audio = sum(np.sin(2 * np.pi * 440 * 2 ** ((note - 69) / 12) * t) for note in notes + [n + 12 for n in notes])
    path = tmp_path / "triad.wav"
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((audio / 6 * 32767).astype("<i2").tobytes())
    points = mixpoints.analyze(path)
    assert points.key == key
    assert points.key_confidence is not None and 0 < points.key_confidence <= 1
    assert points.key_confidence == round(points.key_confidence, 3)


def test_analyze_silence_has_no_key(tmp_path: Path) -> None:
    path = tmp_path / "silence.wav"
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"\0\0" * RATE * 20)
    points = mixpoints.analyze(path)
    assert points.key is None and points.key_confidence is None


@pytest.fixture
async def env(client):
    async def reset() -> None:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)

    await reset()
    user = await register(client, "mix-points")
    async with SessionLocal() as db:
        artist = Artist(name="Beats", name_key="beats")
        db.add(artist)
        await db.flush()
        album = Album(title="Beats", title_key="beats", artist_id=artist.id)
        db.add(album)
        await db.flush()
        path = beat_track(MUSIC_DIR / "Beats/beat.wav", bpm=120, seconds=40)
        track = Track(
            path="Beats/beat.wav",
            title="Beat",
            album_id=album.id,
            artist_id=artist.id,
            artist_credit="Beats",
            duration=40,
            mtime=path.stat().st_mtime,
        )
        missing = Track(
            path="Beats/missing.wav", title="Gone", album_id=album.id, artist_id=artist.id, artist_credit="Beats"
        )
        db.add_all([track, missing])
        await db.commit()
        ids = (track.id, missing.id)
    yield client, auth(user["token"]), *ids
    await reset()
    shutil.rmtree(MUSIC_DIR / "Beats", ignore_errors=True)


async def test_api_analyzes_once_and_reanalyzes_changed_files(env, monkeypatch: pytest.MonkeyPatch) -> None:
    client, headers, track_id, missing_id = env
    calls = []
    original = mixpoints.analyze

    def counting(path):
        calls.append(path)
        return original(path)

    monkeypatch.setattr(mixpoints, "analyze", counting)
    unknown = uuid.uuid4()
    response = await client.get(
        "/api/mixpoints", params={"ids": f"{track_id},{missing_id},{unknown},{track_id}"}, headers=headers
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body[str(track_id)]["bpm"] == pytest.approx(120, rel=0.02)
    assert body[str(track_id)]["vocals_in"] is None and body[str(track_id)]["vocals_out"] is None
    assert body[str(missing_id)] is None and body[str(unknown)] is None
    assert len(calls) == 2
    again = await client.get("/api/mixpoints", params={"ids": str(track_id)}, headers=headers)
    assert again.json()[str(track_id)] == body[str(track_id)] and len(calls) == 2
    async with SessionLocal() as db:
        (await db.get(Track, track_id)).mtime += 1
        await db.commit()
    await client.get("/api/mixpoints", params={"ids": str(track_id)}, headers=headers)
    assert len(calls) == 3
    async with SessionLocal() as db:
        rows = {row.track_id: row for row in await db.scalars(select(TrackMixPoints))}
        assert set(rows) == {track_id, missing_id}
        assert rows[track_id].version == mixpoints.VERSION and not rows[track_id].failed
        assert rows[missing_id].failed
    assert (await client.get("/api/mixpoints", params={"ids": "nope"}, headers=headers)).status_code == 422
    assert (await client.get("/api/mixpoints", params={"ids": str(track_id)})).status_code == 401


async def test_api_vocal_bounds_follow_current_lyrics_without_reanalysis(env, monkeypatch: pytest.MonkeyPatch) -> None:
    client, headers, track_id, missing_id = env
    calls = []

    async def analyze(path):
        calls.append(path)
        return mixpoints.MixPoints(120, 0, 30, 39)

    monkeypatch.setattr(mixpoints, "analyze_async", analyze)
    synced = "[00:10]First\n[00:18]Second\n[00:38]Last"
    async with SessionLocal() as db:
        db.add_all([
            TrackLyrics(track_id=track_id, synced=synced, source="lrclib"),
            TrackLyrics(track_id=missing_id, synced=synced, instrumental=True, source="lrclib"),
        ])
        await db.commit()
    response = await client.get("/api/mixpoints", params={"ids": f"{track_id},{missing_id}"}, headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert (body[str(track_id)]["vocals_in"], body[str(track_id)]["vocals_out"]) == (10, 40)
    assert body[str(missing_id)]["vocals_in"] is None and body[str(missing_id)]["vocals_out"] is None
    assert len(calls) == 2
    for synced, instrumental, expected in (
        ("[00:02]First\n[00:06]Second\n[00:12]Last", False, (2, 17)),
        ("[00:02]First\n[00:06]Second\n[00:12]Last", True, (None, None)),
        (None, False, (None, None)),
    ):
        async with SessionLocal() as db:
            lyric = await db.get(TrackLyrics, track_id)
            lyric.synced, lyric.instrumental = synced, instrumental
            await db.commit()
        response = await client.get("/api/mixpoints", params={"ids": str(track_id)}, headers=headers)
        assert response.status_code == 200, response.text
        points = response.json()[str(track_id)]
        assert (points["vocals_in"], points["vocals_out"]) == expected
        assert len(calls) == 2


@pytest.mark.parametrize("change", ["mtime", "version"])
async def test_failed_analysis_is_stored_and_cached_until_file_or_version_changes(
    env, monkeypatch: pytest.MonkeyPatch, change: str
) -> None:
    client, headers, _, missing_id = env
    calls = []

    def fail(path):
        calls.append(path)
        raise ValueError("Broken audio")

    monkeypatch.setattr(mixpoints, "analyze", fail)
    async with SessionLocal() as db:
        track = await db.get(Track, missing_id)
        db.add(TrackMixPoints(
            track_id=missing_id, version=mixpoints.VERSION - 1, mtime=track.mtime,
            bpm=120, mix_in=0, mix_out=30, end=40, key="8A", key_confidence=0.2,
        ))
        await db.commit()
    for _ in range(2):
        response = await client.get("/api/mixpoints", params={"ids": str(missing_id)}, headers=headers)
        assert response.status_code == 200 and response.json() == {str(missing_id): None}
    assert len(calls) == 1
    async with SessionLocal() as db:
        row = await db.get(TrackMixPoints, missing_id)
        track = await db.get(Track, missing_id)
        assert row.failed and row.version == mixpoints.VERSION and row.mtime == track.mtime
        assert (row.bpm, row.mix_in, row.mix_out, row.end, row.key, row.key_confidence) == (None,) * 6
        if change == "mtime":
            track.mtime += 1
        else:
            row.version -= 1
        await db.commit()

    def succeed(path):
        calls.append(path)
        return mixpoints.MixPoints(120, 0, 30, 40, "8B", 0.1)

    monkeypatch.setattr(mixpoints, "analyze", succeed)
    response = await client.get("/api/mixpoints", params={"ids": str(missing_id)}, headers=headers)
    assert response.json()[str(missing_id)]["key"] == "8B" and len(calls) == 2
    async with SessionLocal() as db:
        row = await db.get(TrackMixPoints, missing_id)
        assert not row.failed and row.version == mixpoints.VERSION
        assert row.mtime == (await db.get(Track, missing_id)).mtime


async def test_status_counts_current_results_for_permanent_tracks_and_requires_admin(
    env, monkeypatch: pytest.MonkeyPatch
) -> None:
    client, headers, track_id, missing_id = env

    async def no_analysis(path):
        pytest.fail("Status must not analyze audio")

    monkeypatch.setattr(mixpoints, "analyze_async", no_analysis)
    assert (await client.get("/api/mixpoints/status")).status_code == 401
    empty = await client.get("/api/mixpoints/status", headers=headers)
    assert empty.status_code == 200
    assert {key: empty.json()[key] for key in ("total", "analyzed", "failed")} == {"total": 2, "analyzed": 0, "failed": 0}
    assert empty.json()["vocals"] == {
        "state": "off", "message": None, "enabled": False, "total": 2, "analyzed": 0, "failed": 0
    }
    invite = (await client.post("/api/admin/invites", json={}, headers=headers)).json()["token"]
    user = await register(client, "mix-listener", invite)
    assert (await client.get("/api/mixpoints/status", headers=auth(user["token"]))).status_code == 403
    async with SessionLocal() as db:
        track = await db.get(Track, track_id)
        db.add(TrackMixPoints(
            track_id=track_id, version=mixpoints.VERSION, mtime=track.mtime, bpm=None,
            mix_in=0, mix_out=30, end=40,
        ))
        db.add(TrackMixPoints(track_id=missing_id, version=mixpoints.VERSION, mtime=0, failed=True))
        for name, version, failed, mtime, temporary in (
            ("stale-success", mixpoints.VERSION, False, 1, False),
            ("old-success", mixpoints.VERSION - 1, False, 0, False),
            ("old-failure", mixpoints.VERSION - 1, True, 0, False),
            ("temporary-success", mixpoints.VERSION, False, 0, True),
            ("temporary-failure", mixpoints.VERSION, True, 0, True),
            ("stale-failure", mixpoints.VERSION, True, 1, False),
        ):
            extra = Track(
                path=f"{name}.wav", title=name, album_id=track.album_id, artist_id=track.artist_id,
                artist_credit="Beats", is_temporary=temporary, mtime=0,
            )
            db.add(extra)
            await db.flush()
            db.add(TrackMixPoints(
                track_id=extra.id, version=version, mtime=mtime, failed=failed,
                mix_in=None if failed else 0, mix_out=None if failed else 30, end=None if failed else 40,
            ))
        await db.commit()
    response = await client.get("/api/mixpoints/status", headers=headers)
    assert response.status_code == 200
    assert {key: response.json()[key] for key in ("total", "analyzed", "failed")} == {
        "total": 6, "analyzed": 1, "failed": 2,
    }


async def test_keys_api_reads_stored_keys_without_analysis(env, monkeypatch: pytest.MonkeyPatch) -> None:
    client, headers, track_id, missing_id = env

    async def no_analysis(path):
        pytest.fail("Keys lookup must not analyze audio")

    monkeypatch.setattr(mixpoints, "analyze_async", no_analysis)
    unknown = uuid.uuid4()
    async with SessionLocal() as db:
        db.add(TrackMixPoints(
            track_id=track_id, version=mixpoints.VERSION, mtime=0, bpm=120,
            mix_in=0, mix_out=30, end=40, key="8A", key_confidence=0.2,
        ))
        # An older analysis (before the songs are analyzed again) still knows tempo and key.
        db.add(TrackMixPoints(
            track_id=missing_id, version=mixpoints.KEYS_SINCE, mtime=0, bpm=90,
            mix_in=0, mix_out=30, end=40, key="3B", key_confidence=0.2,
        ))
        await db.commit()
    response = await client.get(
        "/api/mixpoints/keys", params={"ids": f"{track_id},{missing_id},{unknown}"}, headers=headers
    )
    assert response.status_code == 200, response.text
    assert response.json() == {
        str(track_id): {"key": "8A", "bpm": 120.0, "energy": None},
        str(missing_id): {"key": "3B", "bpm": 90.0, "energy": None},
        str(unknown): None,
    }
    full = ",".join(str(uuid.uuid4()) for _ in range(500))
    assert (await client.get("/api/mixpoints/keys", params={"ids": full}, headers=headers)).status_code == 200
    for ids in ("nope", f"{track_id},bad", "", full + f",{uuid.uuid4()}", ",".join([track_id.hex] * 501)):
        assert (await client.get("/api/mixpoints/keys", params={"ids": ids}, headers=headers)).status_code == 422
    assert (await client.get("/api/mixpoints/keys", params={"ids": str(track_id)})).status_code == 401


async def test_background_batch_selects_oldest_without_current_rows(env, monkeypatch: pytest.MonkeyPatch) -> None:
    _, _, track_id, missing_id = env
    created = datetime(2020, 1, 1, tzinfo=UTC)
    async with SessionLocal() as db:
        track = await db.get(Track, track_id)
        missing = await db.get(Track, missing_id)
        missing.created_at = created
        for id, version in ((track_id, mixpoints.VERSION), (missing_id, mixpoints.VERSION - 1)):
            db.add(TrackMixPoints(track_id=id, version=version, mtime=0, bpm=None, mix_in=0, mix_out=30, end=40))
        for i in range(121):
            db.add(Track(
                path=f"background/{i}.wav", title=str(i), album_id=track.album_id,
                artist_id=track.artist_id, artist_credit="Beats", created_at=created + timedelta(seconds=i + 1),
            ))
        db.add(Track(
            path="temporary.wav", title="Temporary", album_id=track.album_id, artist_id=track.artist_id,
            artist_credit="Beats", is_temporary=True, created_at=created - timedelta(days=1),
        ))
        await db.commit()
    paths = []
    sleeps = []

    async def analyze(path):
        paths.append(path)
        return mixpoints.MixPoints(120, 0, 30, 40, "8B", 0.1)

    async def sleep(seconds):
        sleeps.append(seconds)

    monkeypatch.setattr(mixpoints, "analyze_async", analyze)
    monkeypatch.setattr(mixpoints.asyncio, "sleep", sleep)
    await mixpoints.run_once()
    assert paths == [MUSIC_DIR / "Beats/missing.wav", *[MUSIC_DIR / f"background/{i}.wav" for i in range(119)]]
    assert sleeps == [5] * 120
    async with SessionLocal() as db:
        row = await db.get(TrackMixPoints, missing_id)
        assert row.version == mixpoints.VERSION and row.key == "8B" and row.key_confidence == 0.1


async def test_background_moves_past_a_full_batch_of_broken_files(env, monkeypatch: pytest.MonkeyPatch) -> None:
    _, _, track_id, missing_id = env
    async with SessionLocal() as db:
        track = await db.get(Track, track_id)
        for i in range(120):
            db.add(Track(
                path=f"broken/{i}.wav", title=str(i), album_id=track.album_id, artist_id=track.artist_id,
                artist_credit="Beats", created_at=datetime(2020, 1, 1, tzinfo=UTC),
            ))
        await db.commit()
    paths = []

    def analyze(path):
        paths.append(path)
        if path != MUSIC_DIR / "Beats/beat.wav":
            raise ValueError("Broken audio")
        return mixpoints.MixPoints(120, 0, 30, 40)

    async def sleep(seconds):
        assert seconds == 5

    monkeypatch.setattr(mixpoints, "analyze", analyze)
    monkeypatch.setattr(mixpoints.asyncio, "sleep", sleep)
    await mixpoints.run_once()
    assert len(paths) == 120 and all("broken" in str(path) for path in paths)
    await mixpoints.run_once()
    assert len(paths) == 122
    await mixpoints.run_once()
    assert len(paths) == 122
    async with SessionLocal() as db:
        assert not (await db.get(TrackMixPoints, track_id)).failed
        assert (await db.get(TrackMixPoints, missing_id)).failed


async def test_background_reanalyzes_a_changed_file(env, monkeypatch: pytest.MonkeyPatch) -> None:
    _, _, track_id, _ = env
    paths = []

    def analyze(path):
        paths.append(path)
        return mixpoints.MixPoints(120, 0, 30, 40)

    async def sleep(seconds):
        assert seconds == 5

    monkeypatch.setattr(mixpoints, "analyze", analyze)
    monkeypatch.setattr(mixpoints.asyncio, "sleep", sleep)
    await mixpoints.run_once()
    assert len(paths) == 2
    async with SessionLocal() as db:
        # A re-download replaces the file but keeps the track.
        (await db.get(Track, track_id)).mtime += 1
        await db.commit()
    await mixpoints.run_once()
    assert len(paths) == 3 and paths[-1] == MUSIC_DIR / "Beats/beat.wav"
    await mixpoints.run_once()
    assert len(paths) == 3


async def test_background_skips_busy_ticks_and_only_runs_one_analysis(env, monkeypatch: pytest.MonkeyPatch) -> None:
    _, _, track_id, missing_id = env
    ticks = 0
    paths = []
    on_demand_path = Path("on-demand.wav")
    started = asyncio.Event()
    release = asyncio.Event()

    async def to_thread(fn, path):
        paths.append(path)
        if path == on_demand_path:
            started.set()
            await release.wait()
        else:
            assert mixpoints._background_limit.locked()
        return mixpoints.MixPoints(120, 0, 30, 40)

    async def sleep(seconds):
        nonlocal ticks
        assert seconds == 5
        ticks += 1
        if ticks == 2:
            assert paths == [on_demand_path]
            release.set()
            await on_demand
            await mixpoints._background_limit.acquire()
        elif ticks == 3:
            assert paths == [on_demand_path]
            mixpoints._background_limit.release()

    monkeypatch.setattr(mixpoints, "_limit", asyncio.Semaphore(2))
    monkeypatch.setattr(mixpoints, "_background_limit", asyncio.Semaphore(1))
    monkeypatch.setattr(mixpoints.asyncio, "to_thread", to_thread)
    monkeypatch.setattr(mixpoints.asyncio, "sleep", sleep)
    on_demand = asyncio.create_task(mixpoints.analyze_async(on_demand_path))
    try:
        await started.wait()
        # One on-demand analysis holds a slot, even though the two-slot semaphore is not locked.
        assert not mixpoints._limit.locked()
        await mixpoints.run_once()
    finally:
        on_demand.cancel()
        await asyncio.gather(on_demand, return_exceptions=True)
    assert ticks == 4 and len(paths) == 3 and mixpoints._analysis_requests == 0
    async with SessionLocal() as db:
        assert not (await db.get(TrackMixPoints, track_id)).failed
        assert not (await db.get(TrackMixPoints, missing_id)).failed
