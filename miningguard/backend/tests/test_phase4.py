"""
Phase 4 — Hazard Report image detection API tests.
Covers: health check, auth guard (401), content-type guard (422), valid image (200).
"""
import io
import struct
import zlib

import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_user
from app.main import app

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_FAKE_USER = {"uid": "test-uid", "email": "worker@mine.test"}


def _make_png_bytes() -> bytes:
    """Return a minimal valid 1×1 white PNG as bytes (no Pillow dependency)."""

    def _chunk(name: bytes, data: bytes) -> bytes:
        c = struct.pack(">I", len(data)) + name + data
        return c + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)
    raw_row = b"\x00\xFF\xFF\xFF"  # filter byte + RGB white
    idat = zlib.compress(raw_row)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", idat)
        + _chunk(b"IEND", b"")
    )


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def client():
    """TestClient with the real app; no Firebase init needed for most tests."""
    with TestClient(app, raise_server_exceptions=True) as c:
        yield c


@pytest.fixture(scope="module")
def authed_client():
    """TestClient with get_current_user dependency overridden to skip Firebase."""
    app.dependency_overrides[get_current_user] = lambda: _FAKE_USER
    with TestClient(app, raise_server_exceptions=True) as c:
        yield c
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


def test_health(client: TestClient):
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"


def test_detect_no_auth(client: TestClient):
    """Missing Authorization header → 403 (FastAPI HTTPBearer behaviour when header absent)."""
    png = _make_png_bytes()
    resp = client.post(
        "/api/v1/image/detect",
        files={"file": ("hazard.png", io.BytesIO(png), "image/png")},
    )
    assert resp.status_code == 403


def test_detect_non_image(authed_client: TestClient):
    """Non-image content-type → 422."""
    resp = authed_client.post(
        "/api/v1/image/detect",
        files={"file": ("note.txt", io.BytesIO(b"just text"), "text/plain")},
    )
    assert resp.status_code == 422


def test_detect_valid_image(authed_client: TestClient):
    """Valid PNG → 200 with expected response fields."""
    png = _make_png_bytes()
    resp = authed_client.post(
        "/api/v1/image/detect",
        files={"file": ("hazard.png", io.BytesIO(png), "image/png")},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data["hazard_detected"], str)
    assert isinstance(data["confidence"], float)
    assert 0.0 <= data["confidence"] <= 1.0
    assert isinstance(data["suggested_severity"], str)
    assert isinstance(data["recommended_action"], str)
