"""Alert dispatcher.

Centralises every code path that writes to `alerts/` and pushes FCM
notifications. Keeping this in one module gives us:
  - a single place to enforce dedup (no duplicate alerts within 24h)
  - a single place to mock in tests
  - one well-known schema for alert documents
"""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Iterable

from app.config import settings
from app.core.logger import logger
from app.schemas.behavior_schema import DetectedPattern


# ── Helpers ──────────────────────────────────────────────────────────────────


def _is_duplicate(uid: str, alert_type: str, db) -> bool:
    """True iff an alert of this type was written for the user within the
    cooldown window. Reads up to one document — cheap."""
    cutoff = datetime.now(timezone.utc) - timedelta(
        hours=settings.alert_cooldown_hours
    )
    hits = list(
        db.collection("alerts")
        .where("uid", "==", uid)
        .where("type", "==", alert_type)
        .where("createdAt", ">=", cutoff)
        .limit(1)
        .stream()
    )
    return bool(hits)


def _write_alert(
    uid: str,
    *,
    alert_type: str,
    severity: str,
    title: str,
    message: str,
    db,
) -> str:
    alert_id = str(uuid.uuid4())
    db.collection("alerts").document(alert_id).set({
        "alertId": alert_id,
        "uid": uid,
        "type": alert_type,
        "severity": severity,
        "title": title,
        "message": message,
        "isRead": False,
        "notifiedVia": "in_app",
        "createdAt": datetime.now(timezone.utc),
    })
    return alert_id


def _fcm_token(uid: str, db) -> str | None:
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        return None
    return (doc.to_dict() or {}).get("fcmToken")


def _supervisor_uid_for(worker_uid: str, db) -> str | None:
    """Find a supervisor on the same mineId. We use the same lookup the
    Phase 4 hazard-report Cloud Function uses, so notifications stay
    consistent across paths."""
    user_doc = db.collection("users").document(worker_uid).get()
    if not user_doc.exists:
        return None
    mine_id = (user_doc.to_dict() or {}).get("mineId")
    if not mine_id:
        return None
    sup_query = list(
        db.collection("users")
        .where("role", "==", "supervisor")
        .where("mineId", "==", mine_id)
        .limit(1)
        .stream()
    )
    return sup_query[0].id if sup_query else None


def _send_fcm(token: str, title: str, body: str, *, high_priority: bool) -> None:
    """Best-effort FCM send. Logs and swallows errors so caller's main flow
    isn't disrupted by transient messaging failures."""
    try:
        from firebase_admin import messaging
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            android=messaging.AndroidConfig(
                priority="high" if high_priority else "normal",
                notification=messaging.AndroidNotification(
                    channel_id="safety_critical" if high_priority else "safety_standard",
                    sound="default",
                ),
            ),
            token=token,
        )
        messaging.send(message)
    except Exception as exc:  # noqa: BLE001
        logger.error(f"[FCM] Send failed: {exc}")


# ── Public dispatchers ───────────────────────────────────────────────────────


_RANK = {"low": 0, "medium": 1, "high": 2, "critical": 3}


async def dispatch_risk_escalation_alert(
    *,
    uid: str,
    previous_level: str,
    new_level: str,
    db,
) -> str | None:
    """
    Fire an alert ONLY when risk increases (e.g. low → high). A new level
    that's the same or lower is a no-op.

    Returns the alertId if an alert was written, else None.
    """
    prev = _RANK.get(previous_level.lower(), 0)
    new = _RANK.get(new_level.lower(), 0)
    if new <= prev:
        return None

    alert_type = f"risk_{new_level.lower()}"
    if _is_duplicate(uid, alert_type, db):
        return None

    title = f"Risk level changed to {new_level.title()}"
    message = (
        f"Your safety risk level increased from {previous_level} to {new_level}. "
        "Open MiningGuard to review your checklist and recent activity."
    )

    alert_id = _write_alert(
        uid,
        alert_type=alert_type,
        severity=new_level.lower(),
        title=title,
        message=message,
        db=db,
    )

    # Worker push
    worker_token = _fcm_token(uid, db)
    if worker_token:
        _send_fcm(worker_token, title, message, high_priority=(new_level.lower() == "high"))

    # Supervisor push only on escalation to high
    if new_level.lower() == "high":
        sup_uid = _supervisor_uid_for(uid, db)
        if sup_uid:
            sup_token = _fcm_token(sup_uid, db)
            if sup_token:
                _send_fcm(
                    sup_token,
                    "Worker risk level: HIGH",
                    "A worker in your section has reached HIGH risk level. "
                    "Open MiningGuard to review.",
                    high_priority=True,
                )
    return alert_id


async def dispatch_behavior_pattern_alerts(
    uid: str,
    patterns: Iterable[DetectedPattern],
    *,
    db,
) -> list[str]:
    """
    Write one alert per non-duplicate medium/high-severity pattern, and
    push to the worker's supervisor when severity is high.

    Returns the list of newly-written alertIds.
    """
    written: list[str] = []
    sup_uid = _supervisor_uid_for(uid, db)
    sup_token = _fcm_token(sup_uid, db) if sup_uid else None

    for p in patterns:
        if _is_duplicate(uid, p.pattern_type, db):
            continue
        alert_id = _write_alert(
            uid,
            alert_type=p.pattern_type,
            severity=p.severity,
            title=_pattern_title(p),
            message=p.description,
            db=db,
        )
        written.append(alert_id)

        if sup_token and p.severity == "high":
            _send_fcm(
                sup_token,
                f"Pattern detected: {_pattern_title(p)}",
                p.recommended_action,
                high_priority=True,
            )

    return written


def _pattern_title(p: DetectedPattern) -> str:
    """Friendly title — derived from pattern_type because DetectedPattern
    doesn't carry a separate title field in our schema."""
    pretty = p.pattern_type.replace("_", " ").title()
    return f"Safety pattern: {pretty}"
