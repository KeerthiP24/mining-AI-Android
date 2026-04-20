from fastapi import APIRouter, Depends, File, UploadFile
from app.api.deps import get_current_user
from app.ml.image_model import image_model
from app.schemas.image_schema import ImageDetectionResponse

router = APIRouter()


@router.post("/detect", response_model=ImageDetectionResponse)
async def detect_hazard(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
) -> ImageDetectionResponse:
    """
    Analyze an uploaded image for safety hazards.
    Accepts JPEG or PNG. Max size enforced at the nginx/reverse-proxy layer.
    """
    image_bytes = await file.read()
    return image_model.predict(image_bytes)
