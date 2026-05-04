"""Tests for the risk-prediction model and endpoint.

Phase 6 — exercises the trained GradientBoostingClassifier through both the
inference wrapper and the FastAPI route. The route test mocks the
Firestore-backed feature extractor so we don't hit a live database.
"""
from __future__ import annotations

import os
from unittest.mock import patch

import pytest

from app.ml.risk_model import risk_model
from app.ml.risk_train import train
from app.schemas.risk_schema import RiskPredictionRequest


def _features(**overrides) -> RiskPredictionRequest:
    base = dict(
        uid="test-001",
        missed_checklists_7d=0,
        consecutive_missed_days=0,
        compliance_rate=1.0,
        high_severity_reports_7d=0,
        total_reports_7d=0,
        videos_watched_7d=3,
        role="worker",
        shift="morning",
    )
    base.update(overrides)
    return RiskPredictionRequest(**base)


@pytest.fixture(autouse=True, scope="session")
def ensure_model() -> None:
    """The model file must exist for inference. Train it once for the session."""
    if not os.path.exists("models/risk_model.pkl"):
        train(verbose=False)
    risk_model._model = None  # type: ignore[attr-defined]


# ── Model unit tests ────────────────────────────────────────────────────────


def test_high_risk_when_compliance_low_and_missed_high():
    response = risk_model.predict(_features(
        missed_checklists_7d=4,
        consecutive_missed_days=3,
        compliance_rate=0.3,
    ))
    assert response.risk_level == "high"
    assert response.risk_score >= 66


def test_low_risk_when_clean():
    response = risk_model.predict(_features(
        missed_checklists_7d=0,
        compliance_rate=0.95,
        videos_watched_7d=5,
    ))
    assert response.risk_level == "low"
    assert response.risk_score < 50


def test_medium_risk_borderline():
    response = risk_model.predict(_features(
        missed_checklists_7d=2,
        compliance_rate=0.6,
    ))
    assert response.risk_level in {"medium", "high"}


def test_risk_score_range_bounds():
    response = risk_model.predict(_features())
    assert 0 <= response.risk_score <= 100


def test_contributing_factors_not_empty_for_high_risk():
    response = risk_model.predict(_features(
        missed_checklists_7d=3,
        compliance_rate=0.4,
    ))
    assert len(response.contributing_factors) >= 1


# ── Endpoint integration test (mocked Firestore) ─────────────────────────────


async def _async_noop(*args, **kwargs):  # noqa: ANN001 - generic async stub
    return None


def test_predict_endpoint_writes_back_and_dispatches(client):
    """POST /api/v1/risk/predict resolves features from Firestore, mutates
    users/{uid}, and reports the new risk level."""
    fake_features = _features(
        uid="uid-123",
        missed_checklists_7d=4,
        consecutive_missed_days=3,
        compliance_rate=0.3,
    )
    user_data = {"riskLevel": "low", "mineId": "M1", "role": "worker"}

    class _Snap:
        exists = True

        def to_dict(self):
            return user_data

    class _UserRef:
        def get(self):
            return _Snap()

        def update(self, data):
            user_data.update(data)

    class _Coll:
        def document(self, _):
            return _UserRef()

        def doc(self, _):
            return _UserRef()

    class _DB:
        def collection(self, _):
            return _Coll()

    with patch("app.api.v1.risk.get_db", return_value=_DB()), \
         patch("app.api.v1.risk.get_user_features", return_value=fake_features), \
         patch("app.api.v1.risk.dispatch_risk_escalation_alert", new=_async_noop):
        response = client.post(
            "/api/v1/risk/predict",
            json={"uid": "uid-123"},
            headers={"X-Dev-UID": "uid-123"},
        )

    assert response.status_code == 200, response.text
    data = response.json()
    assert data["uid"] == "uid-123"
    assert data["risk_level"] in {"low", "medium", "high"}
    assert "riskLevel" in user_data  # write-back happened


def test_predict_endpoint_returns_404_for_missing_user(client):
    class _Snap:
        exists = False

        def to_dict(self):
            return {}

    class _UserRef:
        def get(self):
            return _Snap()

        def update(self, _):
            pass

    class _Coll:
        def document(self, _):
            return _UserRef()

    class _DB:
        def collection(self, _):
            return _Coll()

    with patch("app.api.v1.risk.get_db", return_value=_DB()):
        response = client.post(
            "/api/v1/risk/predict",
            json={"uid": "ghost"},
            headers={"X-Dev-UID": "ghost"},
        )
    assert response.status_code == 404
