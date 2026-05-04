"""Tests for the alerts dispatcher and the alerts API."""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from app.ml.alerts_dispatcher import (
    dispatch_behavior_pattern_alerts,
    dispatch_risk_escalation_alert,
)
from app.schemas.behavior_schema import DetectedPattern


def _seed_worker_with_supervisor(fake_db, *, fcm: bool = True) -> None:
    fake_db.collection("users")._docs["u1"] = {
        "role": "worker",
        "mineId": "M1",
        "fcmToken": "WORKER_TOKEN" if fcm else None,
    }
    fake_db.collection("users")._docs["sup1"] = {
        "role": "supervisor",
        "mineId": "M1",
        "fcmToken": "SUP_TOKEN" if fcm else None,
    }


def test_risk_escalation_writes_alert_and_pushes(fake_db):
    _seed_worker_with_supervisor(fake_db)

    with patch("app.ml.alerts_dispatcher._send_fcm") as send:
        alert_id = asyncio.run(dispatch_risk_escalation_alert(
            uid="u1",
            previous_level="low",
            new_level="high",
            db=fake_db,
        ))

    assert alert_id is not None
    docs = list(fake_db.collection("alerts")._docs.values())
    assert len(docs) == 1
    assert docs[0]["type"] == "risk_high"
    assert docs[0]["severity"] == "high"
    # Worker FCM + supervisor FCM both pushed (2 calls)
    assert send.call_count == 2


def test_risk_de_escalation_no_op(fake_db):
    _seed_worker_with_supervisor(fake_db)
    alert_id = asyncio.run(dispatch_risk_escalation_alert(
        uid="u1",
        previous_level="high",
        new_level="medium",
        db=fake_db,
    ))
    assert alert_id is None
    assert not fake_db.collection("alerts")._docs


def test_risk_alert_dedup_within_24h(fake_db):
    _seed_worker_with_supervisor(fake_db)

    # Pre-seed an existing alert from 2h ago
    fake_db.collection("alerts")._docs["existing"] = {
        "uid": "u1",
        "type": "risk_high",
        "createdAt": datetime.now(timezone.utc) - timedelta(hours=2),
    }

    with patch("app.ml.alerts_dispatcher._send_fcm") as send:
        alert_id = asyncio.run(dispatch_risk_escalation_alert(
            uid="u1",
            previous_level="low",
            new_level="high",
            db=fake_db,
        ))
    assert alert_id is None
    assert send.call_count == 0


def test_behavior_pattern_alerts_write_per_pattern(fake_db):
    _seed_worker_with_supervisor(fake_db)
    patterns = [
        DetectedPattern(
            pattern_type="weekly_skip",
            severity="medium",
            description="Weekly skip detected",
            recommended_action="Schedule briefing",
            data_points=["weekday=Monday"],
        ),
        DetectedPattern(
            pattern_type="night_shift_gap",
            severity="high",
            description="Night gap detected",
            recommended_action="Welfare check",
            data_points=["gap=30%"],
        ),
    ]

    with patch("app.ml.alerts_dispatcher._send_fcm") as send:
        ids = asyncio.run(dispatch_behavior_pattern_alerts(
            "u1", patterns, db=fake_db,
        ))
    assert len(ids) == 2
    # Only the high-severity pattern triggers a supervisor push
    assert send.call_count == 1
