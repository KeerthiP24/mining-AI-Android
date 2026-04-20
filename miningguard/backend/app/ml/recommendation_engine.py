"""
Personalized Recommendation Engine — Stub for Phase 1.
Full content-matching logic in Phase 6.
"""
from app.schemas.recommendation_schema import RecommendationRequest, RecommendationResponse
from app.core.logger import logger


class RecommendationEngine:
    """
    Placeholder that returns a default PPE video recommendation.
    Full personalization logic in Phase 6.
    """

    def recommend(self, request: RecommendationRequest) -> RecommendationResponse:
        logger.info(f"[RecommendationEngine STUB] Recommending for uid={request.uid}")
        return RecommendationResponse(
            uid=request.uid,
            recommended_video_id="default_ppe_intro",
            recommendation_reason="Default recommendation: PPE fundamentals apply to all workers.",
            safety_tip="Always wear your PPE before entering the mine. Your hard hat protects you from roof falls.",
            fallback_category="ppe",
        )


recommendation_engine = RecommendationEngine()
