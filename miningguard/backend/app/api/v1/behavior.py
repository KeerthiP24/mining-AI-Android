from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_current_user
from app.core.firebase_admin import get_db
from app.core.logger import logger
from app.ml.alerts_dispatcher import dispatch_behavior_pattern_alerts
from app.ml.behavior_engine import behavior_engine
from app.schemas.behavior_schema import (
    BehaviorAnalysisRequest,
    BehaviorAnalysisResponse,
)

router = APIRouter()


@router.post("/analyze", response_model=BehaviorAnalysisResponse)
async def analyze_behavior(
    request: BehaviorAnalysisRequest,
    current_user: dict = Depends(get_current_user),
) -> BehaviorAnalysisResponse:
    """
    Analyze a worker's behavior patterns over the last 30 days.

    Side effects:
      - alerts/{auto-id} for every newly-detected medium/high severity pattern
      - FCM push to the worker's supervisor when a high-severity pattern fires
    """
    db = get_db()
    try:
        response = behavior_engine.analyze_with_db(request.uid, db)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=500,
            detail=f"Behavior analysis failed: {exc}",
        )

    alertable = [
        p for p in response.patterns_found if p.severity in ("medium", "high")
    ]
    if alertable:
        try:
            await dispatch_behavior_pattern_alerts(request.uid, alertable, db=db)
        except Exception as exc:  # noqa: BLE001 — alerts must never break analysis
            logger.error(
                f"[BehaviorRouter] Alert dispatch failed for {request.uid}: {exc}"
            )

    return response
