"""Tests for the behavior pattern detection engine.

Each detector is invoked with the in-memory FakeFirestore from conftest, so
tests run without any Firebase credentials or network access.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.ml.behavior_engine import (
    behavior_engine,
    detect_escalating_severity,
    detect_inactivity_spike,
    detect_night_shift_gap,
    detect_repeated_ppe_miss,
    detect_weekly_skip,
)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _add(coll, payload: dict) -> None:
    """Convenience: write into a FakeCollection with an auto id."""
    coll.add(payload)


# ── Detector 1: weekly_skip ─────────────────────────────────────────────────


def test_weekly_skip_fires_when_same_weekday_misses_60_percent(fake_db):
    now = _now()
    monday = now - timedelta(days=now.weekday())  # this Monday
    coll = fake_db.collection("checklists")
    # 5 Mondays — 4 missed
    for i in range(5):
        coll.add({
            "uid": "u1",
            "status": "missed" if i < 4 else "submitted",
            "submittedAt": monday - timedelta(days=7 * i),
        })
    # Tuesdays — all submitted (control)
    for i in range(5):
        coll.add({
            "uid": "u1",
            "status": "submitted",
            "submittedAt": monday + timedelta(days=1) - timedelta(days=7 * i),
        })

    result = detect_weekly_skip("u1", fake_db, now - timedelta(days=60))
    assert result is not None
    assert result.pattern_type == "weekly_skip"
    assert "Monday" in result.description


def test_weekly_skip_returns_none_when_pattern_absent(fake_db):
    now = _now()
    coll = fake_db.collection("checklists")
    for i in range(5):
        coll.add({
            "uid": "u1",
            "status": "submitted",
            "submittedAt": now - timedelta(days=i),
        })
    assert detect_weekly_skip("u1", fake_db, now - timedelta(days=60)) is None


# ── Detector 2: night_shift_gap ─────────────────────────────────────────────


def test_night_shift_gap_fires_when_compliance_drops(fake_db):
    now = _now()
    coll = fake_db.collection("checklists")
    for i in range(5):
        coll.add({"uid": "u1", "status": "submitted",
                  "submittedAt": now - timedelta(days=i),
                  "shiftType": "morning"})
    for i in range(5):
        coll.add({"uid": "u1", "status": "missed",
                  "submittedAt": now - timedelta(days=i),
                  "shiftType": "night"})
    result = detect_night_shift_gap("u1", fake_db, now - timedelta(days=60))
    assert result is not None
    assert result.pattern_type == "night_shift_gap"
    assert result.severity == "high"


# ── Detector 3: escalating_severity ─────────────────────────────────────────


def test_escalating_severity_fires_for_low_med_high(fake_db):
    now = _now()
    coll = fake_db.collection("hazard_reports")
    coll.add({"uid": "u1", "severity": "low",
              "submittedAt": now - timedelta(days=14)})
    coll.add({"uid": "u1", "severity": "medium",
              "submittedAt": now - timedelta(days=7)})
    coll.add({"uid": "u1", "severity": "high",
              "submittedAt": now - timedelta(days=1)})

    result = detect_escalating_severity("u1", fake_db, now - timedelta(days=60))
    assert result is not None
    assert result.pattern_type == "escalating_severity"


def test_escalating_severity_silent_with_only_two_reports(fake_db):
    now = _now()
    coll = fake_db.collection("hazard_reports")
    coll.add({"uid": "u1", "severity": "low",
              "submittedAt": now - timedelta(days=10)})
    coll.add({"uid": "u1", "severity": "high",
              "submittedAt": now - timedelta(days=1)})
    assert detect_escalating_severity("u1", fake_db,
                                      now - timedelta(days=60)) is None


# ── Detector 4: repeated_ppe_miss ───────────────────────────────────────────


def test_repeated_ppe_miss_fires_after_4_misses(fake_db):
    now = _now()
    coll = fake_db.collection("checklists")
    for i in range(5):
        coll.add({
            "uid": "u1",
            "status": "submitted",
            "submittedAt": now - timedelta(days=i),
            "items": [
                {"itemId": "ppe_helmet", "completed": False},
                {"itemId": "ppe_boots", "completed": True},
            ],
        })
    result = detect_repeated_ppe_miss("u1", fake_db, now - timedelta(days=60))
    assert result is not None
    assert result.pattern_type == "repeated_ppe_miss"
    assert "ppe_helmet" in result.description


# ── Detector 5: inactivity_spike ────────────────────────────────────────────


def test_inactivity_spike_fires(fake_db):
    now = _now()
    coll = fake_db.collection("checklists")
    # 5 each in weeks 1, 2, 3 — 0 this week
    for week in range(1, 4):
        for d in range(5):
            coll.add({
                "uid": "u1",
                "status": "submitted",
                "submittedAt": now - timedelta(days=week * 7 + d),
            })
    result = detect_inactivity_spike("u1", fake_db, now - timedelta(days=60))
    assert result is not None
    assert result.pattern_type == "inactivity_spike"


# ── Engine end-to-end ───────────────────────────────────────────────────────


def test_engine_aggregates_and_scores(fake_db):
    now = _now()
    # Seed an escalating-severity pattern → high severity
    coll = fake_db.collection("hazard_reports")
    coll.add({"uid": "u1", "severity": "low",
              "submittedAt": now - timedelta(days=14)})
    coll.add({"uid": "u1", "severity": "medium",
              "submittedAt": now - timedelta(days=7)})
    coll.add({"uid": "u1", "severity": "high",
              "submittedAt": now - timedelta(days=1)})

    response = behavior_engine.analyze_with_db("u1", fake_db)
    assert response.uid == "u1"
    assert any(p.pattern_type == "escalating_severity"
               for p in response.patterns_found)
    # Score ranges: high pattern subtracts 0.3 from baseline 1.0
    assert response.overall_behavior_score < 1.0
