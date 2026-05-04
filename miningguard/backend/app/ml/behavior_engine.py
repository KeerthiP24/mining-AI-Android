"""Behavior pattern detection engine.

Runs five independent detectors over a worker's last 30 days of activity in
Firestore and surfaces any concerning patterns. Each detector is a pure
function over a (db, since) pair so they can be unit-tested with a fake
Firestore client.

The engine is intentionally tolerant — a detector raising an exception just
gets logged and skipped, so a single bad query never blocks the others.
"""
from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from typing import Callable

from app.core.firebase_admin import get_db
from app.core.logger import logger
from app.schemas.behavior_schema import (
    BehaviorAnalysisRequest,
    BehaviorAnalysisResponse,
    DetectedPattern,
)

DAY_NAMES = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday",
]

SEVERITY_RANK = {"low": 1, "medium": 2, "high": 3, "critical": 4}

# Behaviour score: subtract weighted severity from a perfect 1.0 baseline.
SEVERITY_WEIGHT = {"low": 0.05, "medium": 0.15, "high": 0.30}


# ─── Detector 1: weekly_skip ─────────────────────────────────────────────────


def detect_weekly_skip(uid: str, db, since: datetime) -> DetectedPattern | None:
    """Worker consistently misses checklists on the same weekday."""
    day_miss = defaultdict(int)
    day_total = defaultdict(int)

    for doc in (
        db.collection("checklists")
        .where("uid", "==", uid)
        .where("submittedAt", ">=", since)
        .stream()
    ):
        data = doc.to_dict() or {}
        ts = data.get("submittedAt")
        if not ts or not hasattr(ts, "weekday"):
            continue
        day = ts.weekday()
        day_total[day] += 1
        if data.get("status") == "missed":
            day_miss[day] += 1

    for day, total in day_total.items():
        if total >= 4 and day_miss[day] / total >= 0.6:
            return DetectedPattern(
                pattern_type="weekly_skip",
                severity="medium",
                description=(
                    f"Worker has missed checklists on {day_miss[day]} out of "
                    f"{total} {DAY_NAMES[day]}s in the last 30 days."
                ),
                recommended_action=(
                    "Schedule a 1:1 safety briefing focused on the start-of-shift "
                    "routine. Investigate whether the worker's schedule or workload "
                    "creates a barrier on this day."
                ),
                data_points=[
                    f"weekday={DAY_NAMES[day]}",
                    f"missed={day_miss[day]}",
                    f"total={total}",
                ],
            )
    return None


# ─── Detector 2: night_shift_gap ─────────────────────────────────────────────


def detect_night_shift_gap(uid: str, db, since: datetime) -> DetectedPattern | None:
    """Night-shift compliance dramatically lower than day-shift."""
    shift_total = defaultdict(int)
    shift_done = defaultdict(int)

    for doc in (
        db.collection("checklists")
        .where("uid", "==", uid)
        .where("submittedAt", ">=", since)
        .stream()
    ):
        data = doc.to_dict() or {}
        shift = data.get("shiftType", data.get("shift", "morning"))
        shift_total[shift] += 1
        if data.get("status") == "submitted":
            shift_done[shift] += 1

    def rate(s: str) -> float | None:
        t = shift_total[s]
        return shift_done[s] / t if t >= 3 else None

    night = rate("night")
    day = rate("morning") or rate("afternoon")

    if night is not None and day is not None and (day - night) >= 0.25:
        gap = day - night
        return DetectedPattern(
            pattern_type="night_shift_gap",
            severity="high",
            description=(
                f"Compliance on night shifts is {int(night * 100)}% vs "
                f"{int(day * 100)}% on day shifts — a {int(gap * 100)}-point "
                "gap, strongly associated with fatigue-related incidents."
            ),
            recommended_action=(
                "Flag for fatigue-management review. Consider adjusting shift "
                "rotation. Conduct a direct welfare check before the worker's "
                "next night shift."
            ),
            data_points=[
                f"night_compliance={int(night * 100)}%",
                f"day_compliance={int(day * 100)}%",
                f"gap={int(gap * 100)}%",
            ],
        )
    return None


# ─── Detector 3: escalating_severity ─────────────────────────────────────────


def detect_escalating_severity(uid: str, db, since: datetime) -> DetectedPattern | None:
    """Last 3 hazard reports show monotonically increasing severity."""
    docs = list(
        db.collection("hazard_reports")
        .where("uid", "==", uid)
        .where("submittedAt", ">=", since)
        .stream()
    )
    if len(docs) < 3:
        return None
    ordered = sorted(
        docs,
        key=lambda d: (d.to_dict() or {}).get("submittedAt")
        or datetime.min.replace(tzinfo=timezone.utc),
    )
    last3 = [
        SEVERITY_RANK.get(str((d.to_dict() or {}).get("severity", "low")).lower(), 1)
        for d in ordered[-3:]
    ]
    if last3[0] < last3[1] < last3[2]:
        return DetectedPattern(
            pattern_type="escalating_severity",
            severity="high",
            description=(
                "The worker's last 3 hazard reports show progressively increasing "
                "severity. The working environment may be deteriorating."
            ),
            recommended_action=(
                "Conduct an urgent inspection of the worker's mine section. "
                "Review all open hazard reports from this area and escalate to "
                "the safety officer."
            ),
            data_points=[
                f"severities={last3}",
                f"reports_total={len(docs)}",
            ],
        )
    return None


# ─── Detector 4: repeated_ppe_miss ───────────────────────────────────────────


def detect_repeated_ppe_miss(uid: str, db, since: datetime) -> DetectedPattern | None:
    """Same checklist item is consistently unchecked across submissions."""
    submitted = list(
        db.collection("checklists")
        .where("uid", "==", uid)
        .where("status", "==", "submitted")
        .where("submittedAt", ">=", since)
        .stream()
    )
    if len(submitted) < 4:
        return None

    miss_counts: Counter[str] = Counter()
    for doc in submitted:
        items = (doc.to_dict() or {}).get("items", [])
        # Items may be a list (Phase 4 schema) OR a map keyed by itemId
        # (Phase 3 in-app schema). Normalise both.
        iterable = items.values() if isinstance(items, dict) else items
        for item in iterable:
            if isinstance(item, dict) and not item.get("completed", True):
                key = item.get("itemId") or item.get("label") or "unknown"
                miss_counts[key] += 1

    for item_id, count in miss_counts.most_common(1):
        if count >= 4:
            return DetectedPattern(
                pattern_type="repeated_ppe_miss",
                severity="medium",
                description=(
                    f"The checklist item '{item_id}' has been unchecked in "
                    f"{count} of the last {len(submitted)} submitted checklists."
                ),
                recommended_action=(
                    f"Assign a targeted safety video for '{item_id}'. Supervisor "
                    "should physically verify compliance on the next shift."
                ),
                data_points=[
                    f"item={item_id}",
                    f"misses={count}",
                    f"submissions={len(submitted)}",
                ],
            )
    return None


# ─── Detector 5: inactivity_spike ────────────────────────────────────────────


def detect_inactivity_spike(uid: str, db, since: datetime) -> DetectedPattern | None:
    """Sudden drop in app activity after a period of regular use."""
    docs = list(
        db.collection("checklists")
        .where("uid", "==", uid)
        .where("submittedAt", ">=", since)
        .stream()
    )
    if len(docs) < 6:
        return None

    now = datetime.now(timezone.utc)
    week_counts: Counter[int] = Counter()
    for doc in docs:
        ts = (doc.to_dict() or {}).get("submittedAt")
        if not ts:
            continue
        try:
            days_ago = (now - ts).days
        except TypeError:
            continue
        week_counts[days_ago // 7] += 1

    if len(week_counts) < 3:
        return None

    older = [week_counts.get(i, 0) for i in (1, 2, 3)]
    avg_older = sum(older) / len(older)
    this_week = week_counts.get(0, 0)

    if avg_older >= 4 and this_week <= 1:
        return DetectedPattern(
            pattern_type="inactivity_spike",
            severity="medium",
            description=(
                f"Worker averaged {avg_older:.1f} check-ins per week over the "
                f"previous 3 weeks but only {this_week} this week."
            ),
            recommended_action=(
                "Conduct a welfare check. The worker may be ill, dealing with "
                "personal difficulties, or may have stopped using the app. "
                "Ensure they are aware of support resources."
            ),
            data_points=[
                f"this_week={this_week}",
                f"avg_prev_3_weeks={avg_older:.1f}",
            ],
        )
    return None


# ─── Engine entry point ──────────────────────────────────────────────────────


_DETECTORS: list[Callable[[str, object, datetime], DetectedPattern | None]] = [
    detect_weekly_skip,
    detect_night_shift_gap,
    detect_escalating_severity,
    detect_repeated_ppe_miss,
    detect_inactivity_spike,
]


def _behavior_score(patterns: list[DetectedPattern]) -> float:
    """Higher is safer. 1.0 = no issues, 0.0 = saturated with high-severity."""
    deduction = sum(SEVERITY_WEIGHT.get(p.severity, 0.0) for p in patterns)
    return max(0.0, min(1.0, 1.0 - deduction))


class BehaviorAnalysisEngine:
    def analyze(self, request: BehaviorAnalysisRequest) -> BehaviorAnalysisResponse:
        db = get_db()
        return self.analyze_with_db(request.uid, db)

    def analyze_with_db(self, uid: str, db) -> BehaviorAnalysisResponse:
        """Same as [analyze] but accepts an injected db (used by tests)."""
        since = datetime.now(timezone.utc) - timedelta(days=30)
        patterns: list[DetectedPattern] = []
        for detector in _DETECTORS:
            try:
                result = detector(uid, db, since)
                if result:
                    patterns.append(result)
            except Exception as exc:  # noqa: BLE001
                logger.error(
                    f"[BehaviorEngine] {detector.__name__} failed for {uid}: {exc}"
                )

        return BehaviorAnalysisResponse(
            uid=uid,
            analysis_window_days=30,
            patterns_found=patterns,
            overall_behavior_score=_behavior_score(patterns),
            last_analyzed_at=datetime.now(timezone.utc).isoformat(),
        )


behavior_engine = BehaviorAnalysisEngine()
