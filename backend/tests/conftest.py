import os
import subprocess
import tempfile
from pathlib import Path

_tmp = Path(tempfile.mkdtemp(prefix="resonance-test-"))
os.environ.setdefault("RESONANCE_DATABASE_URL", "postgresql+asyncpg://app:app@localhost:55432/app_test")
os.environ["RESONANCE_BOOKS_DIR"] = str(_tmp / "books")
os.environ["RESONANCE_MUSIC_DIR"] = str(_tmp / "music")
os.environ["RESONANCE_IMPORT_DIR"] = str(_tmp / "import")
os.environ["RESONANCE_DATA_DIR"] = str(_tmp / "data")
os.environ["RESONANCE_DOWNLOAD_WORKERS"] = "0"
os.environ["RESONANCE_DOWNLOADS_DIR"] = str(_tmp / "downloads")

import httpx  # noqa: E402
import pytest  # noqa: E402
import requests  # noqa: E402

from app.db import Base, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models.library import SEARCH_FOLD_DDL  # noqa: E402

MUSIC_DIR = _tmp / "music"


def make_track(rel: str, **tags: str) -> Path:
    """Create a 2s sine wave audio file with the given tags via ffmpeg."""
    path = MUSIC_DIR / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    meta = [arg for k, v in tags.items() for arg in ("-metadata", f"{k}={v}")]
    subprocess.run(
        [
            "ffmpeg",
            "-nostdin",
            "-loglevel",
            "error",
            "-y",
            "-f",
            "lavfi",
            "-i",
            "sine=frequency=440:duration=2",
            *meta,
            str(path),
        ],
        check=True,
    )
    return path


@pytest.fixture(autouse=True)
def no_network(monkeypatch: pytest.MonkeyPatch) -> None:
    async def block_http(*args: object, **kwargs: object) -> None:
        raise AssertionError("External HTTP is forbidden in tests")

    def block_requests(*args: object, **kwargs: object) -> None:
        raise AssertionError("External HTTP is forbidden in tests")

    monkeypatch.setattr(httpx.AsyncHTTPTransport, "handle_async_request", block_http)
    monkeypatch.setattr(requests.Session, "request", block_requests)


@pytest.fixture(scope="session", autouse=True)
async def _schema():
    assert engine.url.database.startswith("app_test")
    async with engine.begin() as conn:
        await conn.exec_driver_sql("CREATE EXTENSION IF NOT EXISTS pg_trgm")
        for statement in SEARCH_FOLD_DDL:
            await conn.exec_driver_sql(statement)
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


@pytest.fixture(scope="session")
async def client():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


async def register(client: httpx.AsyncClient, username: str, invite: str | None = None) -> dict:
    r = await client.post(
        "/api/auth/register", json={"username": username, "password": "password123", "invite": invite}
    )
    assert r.status_code == 201, r.text
    return r.json()


def auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
