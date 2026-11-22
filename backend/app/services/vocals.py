"""Optional song analysis for AutoMix: where a song's voice starts and ends, from a stem separation (Demucs).

Off by default (Admin → Server → Bibliothek). When switched on, Demucs and PyTorch (CPU) are installed once into the
data folder (about 1 GB, so the image stays small), then the library is analyzed in the background, one song at a
time at low priority, most played songs first. The results replace the lyrics-based vocal bounds of `mixpoints`.
"""

import asyncio
import json
import logging
import os
import shutil
import sys
import time
import uuid
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import SessionLocal
from app.models import PlayEvent, Track, TrackVocals
from app.services.server_config import load_config
from app.services.transcode import resolve_path

log = logging.getLogger(__name__)

# Bump when the analysis changes so stored results get recomputed.
VERSION = 1
# Bump when the installed packages change so they get installed again.
_RUNTIME = 1
_PACKAGES = (
    ["--index-url", "https://download.pytorch.org/whl/cpu", "torch==2.8.0", "torchaudio==2.8.0"],
    ["demucs==4.0.1"],
)
_WORKER = Path(__file__).with_name("vocals_worker.py")
# Separating both windows of a song takes about a minute; give up on one after this long.
_SONG_TIMEOUT = 15 * 60
# The loaded model takes a lot of memory; it is released after this many seconds without work.
_WORKER_IDLE = 10 * 60

# A song that stops the worker this often in a row is stored as failed.
_MAX_CRASHES = 3

# In the evening and at night the server also runs game servers, which need the CPU at once when they generate new
# terrain. nice does not help across containers, so the separation then uses a single thread (about a quarter of
# its usual speed). From 18:00 to 03:00 German time; the container itself runs in UTC.
_QUIET_HOURS = (18, 3)
_QUIET_THREADS = 1
_ZONE = ZoneInfo("Europe/Berlin")

_state: dict[str, str | None] = {"state": "off", "message": None}
_crashes: dict[uuid.UUID, int] = {}
_install_failed_at = 0.0
_loop_task: asyncio.Task | None = None


def _root() -> Path:
    return get_settings().data_dir / "vocals"


def _python() -> Path:
    return _root() / "venv" / "bin" / "python"


def _marker() -> Path:
    return _root() / f"installed-{_RUNTIME}"


def threads(now: datetime | None = None) -> int:
    """How many threads the separation may use now."""
    hour = (now or datetime.now(_ZONE)).astimezone(_ZONE).hour
    start, end = _QUIET_HOURS
    if hour >= start or hour < end:
        return _QUIET_THREADS
    return max(1, (os.cpu_count() or 2) // 2)


def installed() -> bool:
    return _marker().exists() and _python().exists()


def state() -> dict[str, str | None]:
    return dict(_state)


async def _run(*command: str | Path) -> None:
    process = await asyncio.create_subprocess_exec(
        *map(str, command), stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT,
    )
    output, _ = await process.communicate()
    if process.returncode != 0:
        tail = output.decode(errors="replace").strip().splitlines()[-3:]
        raise RuntimeError(" ".join(tail)[-300:] or f"exit {process.returncode}")


async def install() -> bool:
    """Installs Demucs into the data folder; False (with the reason in the state) when that fails."""
    global _install_failed_at
    _state.update(state="installing", message=None)
    root = _root()
    try:
        if root.exists():
            await asyncio.to_thread(shutil.rmtree, root)
        root.mkdir(parents=True)
        await _run(sys.executable, "-m", "venv", root / "venv")
        for packages in _PACKAGES:
            await _run(_python(), "-m", "pip", "install", "--no-cache-dir", "--disable-pip-version-check", *packages)
        _marker().touch()
    except (OSError, RuntimeError) as e:
        log.warning("Installing the song analysis failed: %s", e)
        _install_failed_at = time.monotonic()
        _state.update(state="failed", message=str(e))
        return False
    _state.update(state="ready", message=None)
    return True


class Worker:
    """The Demucs process; it keeps the model loaded between songs."""

    def __init__(self) -> None:
        self._process: asyncio.subprocess.Process | None = None
        # One request at a time: the background analysis and stems for playback share the worker.
        self._lock = asyncio.Lock()
        self._used_at = 0.0

    async def _start(self) -> asyncio.subprocess.Process:
        root = _root()
        process = await asyncio.create_subprocess_exec(
            # Lowest priority: the separation uses up to half the machine's cores and must not slow anything else down.
            "nice", "-n", "19", str(_python()), str(_WORKER),
            stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
            env={"TORCH_HOME": str(root / "torch"), "HOME": str(root), "PATH": "/usr/local/bin:/usr/bin:/bin"},
            limit=2**20,
        )
        try:
            # The first start downloads the model (80 MB).
            line = await asyncio.wait_for(_answer(process), timeout=_SONG_TIMEOUT)
            if not json.loads(line or b"{}").get("ready"):
                raise RuntimeError("Song analysis did not start")
        except BaseException:
            process.kill()
            await process.wait()
            raise
        return process

    async def analyze(self, path: Path, duration: float) -> tuple[float, float]:
        result = await self._request({"path": str(path), "duration": duration})
        return float(result["vocals_in"]), float(result["vocals_out"])

    async def instrumental(self, path: Path, length: float, out: Path) -> None:
        await self._request({"path": str(path), "length": length, "stem": str(out)})

    async def _request(self, request: dict) -> dict:
        async with self._lock:
            try:
                return await self._send(request)
            finally:
                self._used_at = time.monotonic()

    async def _send(self, request: dict) -> dict:
        if self._process is None or self._process.returncode is not None:
            self._process = await self._start()
        process = self._process
        # Asked per song, so the evening limit applies from the next song on without restarting the worker.
        request = {**request, "threads": threads()}
        process.stdin.write((json.dumps(request) + "\n").encode())
        try:
            await process.stdin.drain()
            line = await asyncio.wait_for(_answer(process), timeout=_SONG_TIMEOUT)
        except (TimeoutError, OSError):
            await self.close()
            raise
        if not line:
            await self.close()
            raise RuntimeError("Song analysis stopped")
        result = json.loads(line)
        if "error" in result:
            raise ValueError(result["error"])
        return result

    async def close_idle(self) -> None:
        """Ends the process when it has had nothing to do for a while; the next request starts it again."""
        if not self._lock.locked() and time.monotonic() - self._used_at >= _WORKER_IDLE:
            await self.close()

    async def close(self) -> None:
        process, self._process = self._process, None
        if process is not None and process.returncode is None:
            process.kill()
            await process.wait()


async def _answer(process: asyncio.subprocess.Process) -> bytes:
    """The worker's next JSON line; anything else a library printed is skipped (empty at the end of the output)."""
    while True:
        line = await process.stdout.readline()
        if not line or line.lstrip().startswith(b"{"):
            return line
        log.debug("Song analysis printed: %s", line[:200])


_worker = Worker()


def _current():
    return select(TrackVocals.track_id).where(
        TrackVocals.track_id == Track.id, TrackVocals.version == VERSION, TrackVocals.mtime == Track.mtime
    ).exists()


async def _next_tracks(db: AsyncSession, limit: int) -> list[Track]:
    """Songs without a current analysis, the most played first."""
    plays = (
        select(PlayEvent.track_id, func.count().label("plays")).group_by(PlayEvent.track_id).subquery()
    )
    return list(await db.scalars(
        select(Track)
        .outerjoin(plays, plays.c.track_id == Track.id)
        .where(Track.is_temporary.is_(False), ~_current())
        .order_by(func.coalesce(plays.c.plays, 0).desc(), Track.created_at.desc(), Track.id)
        .limit(limit)
    ))


async def _store(
    track_id: uuid.UUID, mtime: float, bounds: tuple[float, float] | None, error: str | None = None
) -> None:
    values = {
        "version": VERSION, "mtime": mtime, "failed": bounds is None, "error": error[:500] if error else None,
        "vocals_in": bounds[0] if bounds else None, "vocals_out": bounds[1] if bounds else None,
        "analyzed_at": func.now(),
    }
    async with SessionLocal() as db:
        await db.execute(
            insert(TrackVocals).values(track_id=track_id, **values)
            .on_conflict_do_update(index_elements=[TrackVocals.track_id], set_=values)
        )
        await db.commit()


async def run_once(limit: int = 20) -> int:
    """Analyzes up to `limit` songs while the analysis is switched on; returns how many."""
    async with SessionLocal() as db:
        if not (await load_config(db)).library.vocal_analysis:
            _state.update(state="off", message=None)
            await _worker.close()
            return 0
        tracks = await _next_tracks(db, limit)
    if not installed():
        # A failed install is retried after an hour (e.g. no internet at the moment).
        if _state["state"] == "failed" and time.monotonic() - _install_failed_at < 3600:
            return 0
        if not await install():
            return 0
    _state.update(state="ready", message=None)
    done = 0
    for track in tracks:
        error = None
        try:
            if not track.duration:
                raise ValueError("Unknown length")
            bounds = await _worker.analyze(resolve_path(track.path), track.duration)
        except ValueError as e:
            # The worker could not analyze this song (unreadable file, …).
            log.info("Song analysis failed for %s: %s", track.id, e)
            bounds, error = None, str(e)
        except (RuntimeError, OSError, TimeoutError) as e:
            # The worker itself stopped: not the song's fault, so it is not stored as failed (that once marked almost
            # the whole library) unless the same song keeps stopping it.
            crashes = _crashes[track.id] = _crashes.get(track.id, 0) + 1
            log.warning("Song analysis stopped at %s (%d. time): %s", track.id, crashes, e)
            if crashes < _MAX_CRASHES:
                break
            bounds, error = None, f"{type(e).__name__}: {e}"
        _crashes.pop(track.id, None)
        await _store(track.id, track.mtime, bounds, error)
        done += 1
        async with SessionLocal() as db:
            if not (await load_config(db)).library.vocal_analysis:
                break
    return done


# Seconds of a song's start separated for the desktop's vocal swap (its intro and the first bars after it).
STEM_SECONDS = 90.0
_STEM_DAYS = 30
_stems_pending: set[uuid.UUID] = set()
_stem_tasks: set[asyncio.Task] = set()
# Why separating a song failed, and when: it is not tried again for an hour.
_stem_errors: dict[uuid.UUID, tuple[float, str]] = {}


def stem_path(track: Track) -> Path:
    """The instrumental start of [track]'s current file."""
    return get_settings().data_dir / "stems" / f"{track.id}-{int(track.mtime or 0)}.opus"


def _clean_stems(directory: Path) -> None:
    cutoff = time.time() - _STEM_DAYS * 86400
    for path in directory.glob("*.opus"):
        if path.stat().st_mtime < cutoff:
            path.unlink(missing_ok=True)


def stem_error(track_id: uuid.UUID) -> str | None:
    failed = _stem_errors.get(track_id)
    return failed[1] if failed and time.monotonic() - failed[0] < 3600 else None


async def request_stem(db: AsyncSession, track: Track) -> str:
    """ready | pending | failed | unavailable: starts separating the song's start when the song analysis is on."""
    path = stem_path(track)
    if path.exists():
        return "ready"
    if track.id in _stems_pending:
        return "pending"
    if stem_error(track.id) is not None:
        return "failed"
    if not (await load_config(db)).library.vocal_analysis or not installed() or not track.duration:
        return "unavailable"
    path.parent.mkdir(parents=True, exist_ok=True)
    _clean_stems(path.parent)
    _stems_pending.add(track.id)
    source, length = resolve_path(track.path), min(STEM_SECONDS, track.duration)

    async def run() -> None:
        partial = path.with_suffix(".part.opus")
        try:
            await _worker.instrumental(source, length, partial)
            partial.replace(path)
        except (ValueError, RuntimeError, OSError, TimeoutError) as e:
            log.warning("Instrumental stem failed for %s: %s", track.id, e)
            _stem_errors[track.id] = (time.monotonic(), str(e)[:500])
            partial.unlink(missing_ok=True)
        finally:
            _stems_pending.discard(track.id)

    task = asyncio.get_running_loop().create_task(run())
    _stem_tasks.add(task)
    task.add_done_callback(_stem_tasks.discard)
    return "pending"


async def bounds_for(db: AsyncSession, tracks: list[Track]) -> dict[uuid.UUID, tuple[float, float]]:
    """Stored voice bounds of tracks whose file has not changed since."""
    mtimes = {track.id: track.mtime for track in tracks}
    rows = await db.scalars(select(TrackVocals).where(
        TrackVocals.track_id.in_(mtimes), TrackVocals.version == VERSION, TrackVocals.failed.is_(False),
    ))
    return {
        row.track_id: (row.vocals_in, row.vocals_out)
        for row in rows
        if row.mtime == mtimes[row.track_id] and row.vocals_in is not None and row.vocals_out is not None
    }


async def status(db: AsyncSession) -> dict:
    enabled = (await load_config(db)).library.vocal_analysis
    current = select(TrackVocals.failed).where(
        TrackVocals.track_id == Track.id, TrackVocals.version == VERSION, TrackVocals.mtime == Track.mtime
    ).scalar_subquery()
    total, analyzed, failed = (await db.execute(
        select(
            func.count(Track.id), func.count(Track.id).filter(current.is_(False)), func.count(Track.id).filter(current)
        ).where(Track.is_temporary.is_(False))
    )).one()
    shown = state() if enabled else {"state": "off", "message": None}
    if enabled and shown["state"] == "off":
        shown["state"] = "ready" if installed() else "installing"
    return {**shown, "enabled": enabled, "total": total, "analyzed": analyzed, "failed": failed}


async def _loop() -> None:
    while True:
        try:
            if not await run_once():
                await _worker.close_idle()
                await asyncio.sleep(60)
        except Exception:
            log.exception("Song analysis loop failed")
            await asyncio.sleep(60)


async def start() -> None:
    global _loop_task
    if _loop_task is None or _loop_task.done():
        _loop_task = asyncio.create_task(_loop())


async def stop() -> None:
    global _loop_task
    if _loop_task is not None:
        _loop_task.cancel()
        await asyncio.gather(_loop_task, return_exceptions=True)
        _loop_task = None
    await _worker.close()
