from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    """Phase 6 default — uid-only; engine derives the context from Firestore."""
    uid: str
    # Legacy fields kept for callers that pre-compute context (Phase 1 stub).
    recent_report_categories: list[str] = []
    missed_checklist_items: list[str] = []
    risk_level: str = "low"
    role: str = "worker"
    shift: str = "morning"


class VideoRecommendation(BaseModel):
    video_id: str
    title: str = ""
    youtube_id: str = ""
    category: str = "General"
    score: float
    reason: str = Field(..., description="Human-readable why-shown explanation")


class RecommendationResponse(BaseModel):
    uid: str
    video_of_the_day: VideoRecommendation
    also_recommended: list[VideoRecommendation] = []

    # Legacy fields preserved so older clients keep working.
    recommended_video_id: str = ""
    recommendation_reason: str = ""
    safety_tip: str = ""
    fallback_category: str = ""
