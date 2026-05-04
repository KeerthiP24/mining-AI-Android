from fastapi import APIRouter
from app.api.v1 import alerts, behavior, image_detect, recommendations, risk

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(risk.router, prefix="/risk", tags=["Risk Prediction"])
api_v1_router.include_router(behavior.router, prefix="/behavior", tags=["Behavior Analysis"])
api_v1_router.include_router(image_detect.router, prefix="/image", tags=["Image Detection"])
api_v1_router.include_router(recommendations.router, prefix="/recommendations", tags=["Recommendations"])
api_v1_router.include_router(alerts.router, prefix="/alerts", tags=["Alerts"])
