"""Shared test fixtures.

We avoid initialising a real Firebase Admin SDK in tests by:
  1. Setting SKIP_AUTH=true so the security dependency returns a synthetic user
  2. Stubbing `firebase_admin.initialize_app` to a no-op (called from main.py)
  3. Providing reusable in-memory fakes for Firestore via FakeFirestore below
"""
from __future__ import annotations

import os
from unittest.mock import patch

# Configure environment BEFORE importing the app.
os.environ["SKIP_AUTH"] = "true"
os.environ["DEBUG"] = "true"

import pytest
from fastapi.testclient import TestClient


@pytest.fixture(scope="session")
def client():
    """TestClient over the real FastAPI app with Firebase init mocked out."""
    with patch("app.core.firebase_admin.initialize_firebase", return_value=None):
        from app.main import app  # imported here to honour the patch
        with TestClient(app, raise_server_exceptions=True) as c:
            yield c


# ── In-memory Firestore fakes ────────────────────────────────────────────────


class FakeDocumentSnapshot:
    def __init__(self, doc_id: str, data: dict | None):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self) -> dict | None:
        return None if self._data is None else dict(self._data)


class FakeDocument:
    def __init__(self, parent: "FakeCollection", doc_id: str):
        self._parent = parent
        self.id = doc_id

    def get(self) -> FakeDocumentSnapshot:
        return FakeDocumentSnapshot(self.id, self._parent._docs.get(self.id))

    def set(self, data: dict, *, merge: bool = False, **_) -> None:
        if merge and self.id in self._parent._docs:
            existing = dict(self._parent._docs[self.id])
            existing.update(data)
            self._parent._docs[self.id] = existing
        else:
            self._parent._docs[self.id] = dict(data)

    def update(self, data: dict) -> None:
        existing = dict(self._parent._docs.get(self.id, {}))
        for k, v in data.items():
            # Trivial FieldValue.increment support — translate to int add
            if hasattr(v, "_increment_value"):
                existing[k] = (existing.get(k) or 0) + v._increment_value
            else:
                existing[k] = v
        self._parent._docs[self.id] = existing


class _Filter:
    """Mimics google.cloud.firestore_v1.base_query.FieldFilter for tests."""
    def __init__(self, field: str, op: str, value):
        self.field, self.op, self.value = field, op, value


def FieldFilter(field: str, op: str, value) -> _Filter:  # noqa: N802
    return _Filter(field, op, value)


class FakeQuery:
    def __init__(self, collection: "FakeCollection", filters=None,
                 order=None, limit=None):
        self._coll = collection
        self._filters = list(filters or [])
        self._order = order
        self._limit = limit

    def where(self, *args, **kwargs) -> "FakeQuery":
        # Accept both positional ('field', 'op', value) and keyword filter=
        if "filter" in kwargs:
            f = kwargs["filter"]
        else:
            f = _Filter(args[0], args[1], args[2])
        return FakeQuery(self._coll, self._filters + [f], self._order, self._limit)

    def order_by(self, field, direction=None) -> "FakeQuery":  # noqa: ARG002
        return FakeQuery(self._coll, self._filters, field, self._limit)

    def limit(self, n: int) -> "FakeQuery":
        return FakeQuery(self._coll, self._filters, self._order, n)

    def stream(self):
        results = []
        for doc_id, data in self._coll._docs.items():
            if all(_match(data, f) for f in self._filters):
                results.append(FakeDocumentSnapshot(doc_id, data))
        if self._limit is not None:
            results = results[: self._limit]
        return iter(results)

    def get(self):
        return list(self.stream())


def _match(data: dict, f: _Filter) -> bool:
    val = data.get(f.field)
    if f.op == "==":
        return val == f.value
    if f.op == "!=":
        return val != f.value
    if f.op == ">=":
        return val is not None and val >= f.value
    if f.op == "<=":
        return val is not None and val <= f.value
    if f.op == ">":
        return val is not None and val > f.value
    if f.op == "<":
        return val is not None and val < f.value
    if f.op == "in":
        return val in f.value
    if f.op == "array_contains":
        return isinstance(val, list) and f.value in val
    raise ValueError(f"Unsupported op: {f.op}")


class FakeCollection:
    def __init__(self, name: str):
        self.name = name
        self._docs: dict[str, dict] = {}

    # Document access — supports both .doc(id) and .document(id)
    def document(self, doc_id: str) -> FakeDocument:
        return FakeDocument(self, doc_id)

    def doc(self, doc_id: str) -> FakeDocument:
        return FakeDocument(self, doc_id)

    def add(self, data: dict) -> tuple[None, FakeDocument]:
        import uuid as _uuid
        doc_id = str(_uuid.uuid4())
        self._docs[doc_id] = dict(data)
        return (None, FakeDocument(self, doc_id))

    # Query starters
    def where(self, *args, **kwargs) -> FakeQuery:
        return FakeQuery(self).where(*args, **kwargs)

    def order_by(self, field, direction=None) -> FakeQuery:  # noqa: ARG002
        return FakeQuery(self).order_by(field, direction)

    def limit(self, n: int) -> FakeQuery:
        return FakeQuery(self).limit(n)

    def stream(self):
        return iter(
            FakeDocumentSnapshot(doc_id, data)
            for doc_id, data in self._docs.items()
        )


class FakeFirestore:
    """Minimal in-memory Firestore for unit tests."""

    def __init__(self):
        self._collections: dict[str, FakeCollection] = {}

    def collection(self, name: str) -> FakeCollection:
        if name not in self._collections:
            self._collections[name] = FakeCollection(name)
        return self._collections[name]


@pytest.fixture
def fake_db():
    """Fresh FakeFirestore for each test."""
    return FakeFirestore()
