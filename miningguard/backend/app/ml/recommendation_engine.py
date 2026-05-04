"""Personalised safety-video recommendation engine.

Score-based content matcher. Reads the worker's profile, recent activity,
and watch history from Firestore, then ranks every active video in
`safety_videos/` against a weighted set of signals. The top result becomes
"Video of the Day"; the next four are "Also Recommended".

The engine is deterministic for a given Firestore state — useful for tests
and for caching the same selection across same-day reads.
"""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta, timezone

from app.core.firebase_admin import get_db
from app.core.logger import logger
from app.schemas.recommendation_schema import (
    RecommendationRequest,
    RecommendationResponse,
    VideoRecommendation,
)


# Signal → points. Tuned so a "matches your recent hazard report" win cleanly
# beats a generic role/rotation pick.
SCORE_WEIGHTS = {
    "matches_recent_report_category":   40,
    "matches_missed_item_category":     30,
    "matches_high_risk":                20,
    "not_watched_recently":             15,
    "matches_role":                     10,
    "category_rotation":                 8,
    "matches_night_shift":               5,
}

# Map worker-side checklist item ids (stored in Firestore checklist docs) to
# the video categories they correspond to.
ITEM_TO_CATEGORY = {
    # PPE
    "ppe_helmet": "ppe",
    "ppe_boots": "ppe",
    "ppe_vest": "ppe",
    "ppe_gloves": "ppe",
    "ppe_lamp_charged": "ppe",
    "ppe_scsr_present": "emergency",
    # Machinery
    "mach_preshift_done": "machinery",
    "mach_guards_in_place": "machinery",
    "mach_no_leaks": "machinery",
    # Environment / gas / roof
    "env_gas_detector_ok": "gas_ventilation",
    "env_ventilation_ok": "gas_ventilation",
    "env_roof_inspected": "roof_support",
    "env_walkways_clear": "emergency",
    # Emergency
    "emg_exit_known": "emergency",
    "emg_comms_working": "emergency",
    "emg_first_aid_located": "emergency",
}

# Phase 4 hazard category → recommendation category. Lets the engine match a
# hazard report ("gas_leak") to videos tagged "gas_ventilation".
HAZARD_TO_VIDEO_CATEGORY = {
    "roof_fall": "roof_support",
    "gas_leak": "gas_ventilation",
    "fire": "emergency",
    "machinery": "machinery",
    "electrical": "machinery",
    "other": "",
}


class RecommendationEngine:
    def recommend(self, request: RecommendationRequest) -> RecommendationResponse:
        return self.recommend_with_db(request, get_db())

    def recommend_with_db(
        self, request: RecommendationRequest, db
    ) -> RecommendationResponse:
        """Same as [recommend] but with an injected db, used by tests."""
        ctx = self._gather_context(request, db)
        videos = self._fetch_videos(db)
        if not videos:
            logger.warning("[Recommender] No active videos in safety_videos collection")
            return self._empty_response(request.uid)

        scored = sorted(
            (self._score(v, ctx) for v in videos),
            key=lambda r: -r.score,
        )
        top = scored[0]
        return RecommendationResponse(
            uid=request.uid,
            video_of_the_day=top,
            also_recommended=scored[1:5],
            recommended_video_id=top.video_id,
            recommendation_reason=top.reason,
            safety_tip="Always wear your PPE before entering the mine.",
            fallback_category=top.category,
        )

    # ── Context (per-worker signal extraction) ──────────────────────────────

    def _gather_context(self, request: RecommendationRequest, db) -> dict:
        now = datetime.now(timezone.utc)
        seven_days_ago = now - timedelta(days=7)
        thirty_days_ago = now - timedelta(days=30)

        user_doc = db.collection("users").document(request.uid).get()
        user = user_doc.to_dict() if user_doc.exists else {}
        risk_level = str(user.get("riskLevel", request.risk_level)).lower()
        role = str(user.get("role", request.role)).lower()
        shift = str(user.get("shift", request.shift)).lower()

        # Recent hazard report categories (Phase 4 → video taxonomy)
        recent_report_categories: set[str] = set()
        if request.recent_report_categories:
            recent_report_categories = {c.lower() for c in request.recent_report_categories}
        else:
            for doc in (
                db.collection("hazard_reports")
                .where("uid", "==", request.uid)
                .where("submittedAt", ">=", seven_days_ago)
                .stream()
            ):
                cat = (doc.to_dict() or {}).get("category", "")
                mapped = HAZARD_TO_VIDEO_CATEGORY.get(cat.lower(), cat.lower())
                if mapped:
                    recent_report_categories.add(mapped)

        # Frequently missed checklist items → video categories
        if request.missed_checklist_items:
            missed_item_categories = {
                ITEM_TO_CATEGORY[i] for i in request.missed_checklist_items
                if i in ITEM_TO_CATEGORY
            }
        else:
            miss_counter: Counter[str] = Counter()
            for doc in (
                db.collection("checklists")
                .where("uid", "==", request.uid)
                .where("status", "==", "submitted")
                .where("submittedAt", ">=", seven_days_ago)
                .stream()
            ):
                items = (doc.to_dict() or {}).get("items", [])
                iterable = items.values() if isinstance(items, dict) else items
                for item in iterable:
                    if isinstance(item, dict) and not item.get("completed", True):
                        item_id = item.get("itemId") or item.get("label") or ""
                        if item_id:
                            miss_counter[item_id] += 1
            missed_item_categories = {
                ITEM_TO_CATEGORY[item_id]
                for item_id, _ in miss_counter.most_common(3)
                if item_id in ITEM_TO_CATEGORY
            }

        # Watched-video state — Phase 5 stores in `video_watches` collection
        watched_30d_ids: set[str] = set()
        recently_watched_video_ids: set[str] = set()
        for doc in (
            db.collection("video_watches")
            .where("userId", "==", request.uid)
            .where("watchedAt", ">=", thirty_days_ago)
            .stream()
        ):
            data = doc.to_dict() or {}
            vid = data.get("videoId", "")
            if vid:
                watched_30d_ids.add(vid)
                ts = data.get("watchedAt")
                if ts and ts >= seven_days_ago:
                    recently_watched_video_ids.add(vid)

        return {
            "risk_level": risk_level,
            "role": role,
            "shift": shift,
            "recent_report_categories": recent_report_categories,
            "missed_item_categories": missed_item_categories,
            "watched_30d_ids": watched_30d_ids,
            "recently_watched_video_ids": recently_watched_video_ids,
        }

    def _fetch_videos(self, db) -> list[dict]:
        """Pull all active videos. Filtering on the read so we don't waste a
        scoring cycle on videos hidden by admins."""
        videos: list[dict] = []
        for doc in db.collection("safety_videos").where("isActive", "==", True).stream():
            data = doc.to_dict() or {}
            videos.append({
                "video_id": doc.id,
                "title": _localized(data.get("title", {})),
                "youtube_id": data.get("youtubeId", ""),
                "category": data.get("category", "general"),
                "target_roles": data.get("targetRoles", []) or [],
                "tags": data.get("tags", []) or [],
            })
        return videos

    # ── Scoring ──────────────────────────────────────────────────────────────

    def _score(self, video: dict, ctx: dict) -> VideoRecommendation:
        score = 0.0
        reasons: list[str] = []
        cat = (video.get("category") or "").lower()

        if cat in ctx["recent_report_categories"]:
            score += SCORE_WEIGHTS["matches_recent_report_category"]
            reasons.append("matches your recent hazard reports")

        if cat in ctx["missed_item_categories"]:
            score += SCORE_WEIGHTS["matches_missed_item_category"]
            reasons.append("covers an item you often skip on your checklist")

        if ctx["risk_level"] == "high" and cat in ("ppe", "emergency"):
            score += SCORE_WEIGHTS["matches_high_risk"]
            reasons.append("recommended for workers at elevated risk")

        if video["video_id"] not in ctx["watched_30d_ids"]:
            score += SCORE_WEIGHTS["not_watched_recently"]

        target_roles = [r.lower() for r in (video.get("target_roles") or [])]
        if not target_roles or ctx["role"] in target_roles:
            score += SCORE_WEIGHTS["matches_role"]

        if video["video_id"] not in ctx["recently_watched_video_ids"]:
            score += SCORE_WEIGHTS["category_rotation"]

        if ctx["shift"] == "night" and cat in ("emergency", "gas_ventilation"):
            score += SCORE_WEIGHTS["matches_night_shift"]

        reason = (
            f"Based on {reasons[0]}"
            if reasons
            else "Part of your rotating safety curriculum"
        )

        return VideoRecommendation(
            video_id=video["video_id"],
            title=video.get("title", ""),
            youtube_id=video.get("youtube_id", ""),
            category=video.get("category", "general"),
            score=score,
            reason=reason,
        )

    def _empty_response(self, uid: str) -> RecommendationResponse:
        empty = VideoRecommendation(
            video_id="",
            title="",
            youtube_id="",
            category="general",
            score=0.0,
            reason="No videos available — upload content via the Admin Panel.",
        )
        return RecommendationResponse(
            uid=uid,
            video_of_the_day=empty,
            also_recommended=[],
            recommended_video_id="",
            recommendation_reason=empty.reason,
            safety_tip="",
            fallback_category="general",
        )


def _localized(field: object, lang: str = "en") -> str:
    """Phase 5 stores titles as `{en, hi, bn, ...}`. Fall back to en."""
    if isinstance(field, dict):
        return str(field.get(lang) or field.get("en") or next(iter(field.values()), ""))
    return str(field or "")


recommendation_engine = RecommendationEngine()
