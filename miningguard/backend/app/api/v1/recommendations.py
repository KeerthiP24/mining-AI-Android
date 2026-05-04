from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_current_user
from app.ml.recommendation_engine import recommendation_engine
from app.schemas.recommendation_schema import (
    RecommendationRequest,
    RecommendationResponse,
)

router = APIRouter()


@router.get("/{uid}", response_model=RecommendationResponse)
async def get_recommendations_by_uid(
    uid: str,
    current_user: dict = Depends(get_current_user),
) -> RecommendationResponse:
    """
    Get a personalised "Video of the Day" + 4 also-recommended videos for
    the given worker. The engine derives all signals from Firestore so the
    caller doesn't have to assemble them.
    """
    try:
        return recommendation_engine.recommend(
            RecommendationRequest(uid=uid)
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=500,
            detail=f"Recommendation engine error: {exc}",
        )


@router.post("/", response_model=RecommendationResponse)
async def get_recommendations(
    request: RecommendationRequest,
    current_user: dict = Depends(get_current_user),
) -> RecommendationResponse:
    """Legacy POST endpoint accepting a fully-populated request payload."""
    return recommendation_engine.recommend(request)
