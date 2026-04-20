from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.recommendation_engine import recommendation_engine
from app.schemas.recommendation_schema import RecommendationRequest, RecommendationResponse

router = APIRouter()


@router.post("/", response_model=RecommendationResponse)
async def get_recommendations(
    request: RecommendationRequest,
    current_user: dict = Depends(get_current_user),
) -> RecommendationResponse:
    """
    Get a personalized video recommendation and safety tip for a worker.
    """
    return recommendation_engine.recommend(request)
