from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_current_user
from app.core.firebase_admin import get_db
from app.core.logger import logger
from app.ml.alerts_dispatcher import dispatch_risk_escalation_alert
from app.ml.risk_features import get_user_features
from app.ml.risk_model import risk_model
from app.schemas.risk_schema import (
    RiskPredictByUidRequest,
    RiskPredictionRequest,
    RiskPredictionResponse,
)

router = APIRouter()


@router.post("/predict", response_model=RiskPredictionResponse)
async def predict_risk(
    request: RiskPredictByUidRequest,
    current_user: dict = Depends(get_current_user),
) -> RiskPredictionResponse:
    """
    Predict the worker's current risk level. Features are pulled from
    Firestore (`users/{uid}` + recent checklist/hazard counts), the trained
    GradientBoosting model produces a label, and the result is written back
    to the user document so the Flutter dashboard can render it live.

    Side effects:
      - users/{uid}.{riskLevel, riskScore, riskFactors, riskUpdatedAt}
      - alerts/{auto-id} when level escalates to "high"
      - FCM push to worker (and supervisor if high)
    """
    db = get_db()

    # Snapshot previous risk before we overwrite — needed for escalation detection.
    user_ref = db.collection("users").document(request.uid)
    prev_snap = user_ref.get()
    if not prev_snap.exists:
        raise HTTPException(
            status_code=404, detail=f"User {request.uid} not found"
        )
    previous_level = str(prev_snap.to_dict().get("riskLevel", "low")).lower()

    try:
        features = get_user_features(request.uid, db)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    response = risk_model.predict(features)

    now = datetime.now(timezone.utc)
    user_ref.update({
        "riskLevel": response.risk_level,
        "riskScore": response.risk_score,
        "riskFactors": [f.description for f in response.contributing_factors],
        "riskUpdatedAt": now,
    })

    try:
        await dispatch_risk_escalation_alert(
            uid=request.uid,
            previous_level=previous_level,
            new_level=response.risk_level,
            db=db,
        )
    except Exception as exc:  # noqa: BLE001 - alerts must never break inference
        logger.error(f"[RiskRouter] Alert dispatch failed for {request.uid}: {exc}")

    return response


@router.post("/predict-features", response_model=RiskPredictionResponse)
async def predict_risk_with_features(
    request: RiskPredictionRequest,
    current_user: dict = Depends(get_current_user),
) -> RiskPredictionResponse:
    """
    Predict risk from a fully-supplied feature payload. Useful for testing
    or for callers that already have the features and want to avoid a
    Firestore round-trip.
    """
    return risk_model.predict(request)
