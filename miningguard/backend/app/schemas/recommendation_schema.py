from pydantic import BaseModel


class RecommendationRequest(BaseModel):
    uid: str
    recent_report_categories: list[str] = []
    missed_checklist_items: list[str] = []
    risk_level: str = "low"
    role: str = "worker"
    shift: str = "morning"


class VideoRecommendation(BaseModel):
    video_id: str
    reason: str
    priority_score: float


class RecommendationResponse(BaseModel):
    uid: str
    recommended_video_id: str
    recommendation_reason: str
    safety_tip: str
    fallback_category: str
