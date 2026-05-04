"""Extract risk-prediction features for one user from Firestore.

The model expects a fixed-length numeric vector. This module is the bridge
between Firestore documents (variable-shape JSON) and that vector. Keep all
field-name knowledge here so the rest of the pipeline doesn't need to know
which Firestore collections back which feature.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING

from app.schemas.risk_schema import RiskPredictionRequest

if TYPE_CHECKING:  # pragma: no cover - typing only
    from google.cloud import firestore as gcfs


ROLE_MAP = {"worker": 0, "supervisor": 1, "admin": 2}
SHIFT_MAP = {"morning": 0, "afternoon": 1, "night": 2}

# These severity values must match HazardSeverity.firestoreValue in the
# Flutter app (see hazard_report_model.dart).
HIGH_SEV_VALUES = ("high", "critical")


def get_user_features(uid: str, db) -> RiskPredictionRequest:
    """
    Build a [RiskPredictionRequest] for [uid] by reading directly from
    Firestore. Raises [ValueError] if the user document doesn't exist.

    Reads:
    - users/{uid} for profile + denormalised counters
    - checklists where uid==uid AND status=="missed" in last 7 days
    - hazard_reports where uid==uid in last 7 days (segregated by severity)
    """
    now = datetime.now(timezone.utc)
    seven_days_ago = now - timedelta(days=7)

    # ── User profile ────────────────────────────────────────────────────────
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        raise ValueError(f"User {uid} not found in Firestore")
    user = user_doc.to_dict() or {}

    compliance_rate = float(user.get("complianceRate", 1.0))
    consecutive_missed = int(user.get("consecutiveMissedDays", 0))
    # Flutter writes this as videosWatched7Days; tolerate both spellings.
    videos_watched_7d = int(
        user.get("videosWatched7Days", user.get("videosWatched7d", 0))
    )
    role_str = str(user.get("role", "worker")).lower()
    shift_str = str(user.get("shift", "morning")).lower()

    # ── Missed checklists in the last 7 days ────────────────────────────────
    missed_checklists_7d = _count(
        db.collection("checklists")
        .where("uid", "==", uid)
        .where("status", "==", "missed")
        .where("submittedAt", ">=", seven_days_ago)
        .stream()
    )

    # ── Hazard reports in last 7 days (split by severity) ───────────────────
    high_severity_reports_7d = 0
    total_reports_7d = 0
    for doc in (
        db.collection("hazard_reports")
        .where("uid", "==", uid)
        .where("submittedAt", ">=", seven_days_ago)
        .stream()
    ):
        total_reports_7d += 1
        sev = str(doc.to_dict().get("severity", "")).lower()
        if sev in HIGH_SEV_VALUES:
            high_severity_reports_7d += 1

    return RiskPredictionRequest(
        uid=uid,
        missed_checklists_7d=min(missed_checklists_7d, 7),  # cap at 7 for schema
        consecutive_missed_days=consecutive_missed,
        compliance_rate=max(0.0, min(1.0, compliance_rate)),
        high_severity_reports_7d=high_severity_reports_7d,
        total_reports_7d=total_reports_7d,
        videos_watched_7d=videos_watched_7d,
        role=role_str,
        shift=shift_str,
    )


def _count(stream) -> int:
    """Count documents in a Firestore stream without materialising the list."""
    n = 0
    for _ in stream:
        n += 1
    return n
