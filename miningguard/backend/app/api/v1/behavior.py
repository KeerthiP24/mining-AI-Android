from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.behavior_engine import behavior_engine
from app.schemas.behavior_schema import BehaviorAnalysisRequest, BehaviorAnalysisResponse

router = APIRouter()


@router.post("/analyze", response_model=BehaviorAnalysisResponse)
async def analyze_behavior(
    request: BehaviorAnalysisRequest,
    current_user: dict = Depends(get_current_user),
) -> BehaviorAnalysisResponse:
    """
    Analyze a worker's behavior patterns over the last 30 days.
    """
    return behavior_engine.analyze(request)
