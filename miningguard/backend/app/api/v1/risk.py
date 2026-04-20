from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.risk_model import risk_model
from app.schemas.risk_schema import RiskPredictionRequest, RiskPredictionResponse

router = APIRouter()


@router.post("/predict", response_model=RiskPredictionResponse)
async def predict_risk(
    request: RiskPredictionRequest,
    current_user: dict = Depends(get_current_user),
) -> RiskPredictionResponse:
    """
    Predict a worker's current risk level based on their behavioral features.
    Requires a valid Firebase ID token in the Authorization header.
    """
    return risk_model.predict(request)
