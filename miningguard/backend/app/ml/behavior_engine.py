"""
Behavior Analysis Engine — Stub for Phase 1.
Full pattern detection implementation in Phase 6.
"""
from datetime import datetime

from app.schemas.behavior_schema import BehaviorAnalysisRequest, BehaviorAnalysisResponse
from app.core.logger import logger


class BehaviorAnalysisEngine:
    """
    Placeholder that returns an empty pattern result.
    Full implementation in Phase 6.
    """

    def analyze(self, request: BehaviorAnalysisRequest) -> BehaviorAnalysisResponse:
        logger.info(f"[BehaviorEngine STUB] Analyzing uid={request.uid}")
        return BehaviorAnalysisResponse(
            uid=request.uid,
            analysis_window_days=30,
            patterns_found=[],
            overall_behavior_score=1.0,
            last_analyzed_at=datetime.utcnow().isoformat(),
        )


behavior_engine = BehaviorAnalysisEngine()
