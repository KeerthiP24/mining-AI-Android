from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

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
    Returns 401 if Firebase token is missing/invalid (handled by get_current_user).
    Returns 422 if the uploaded file is not an image.
    """
    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise HTTPException(
            status_code=422,
            detail=f"Invalid file type '{content_type}'. Only image/* files are accepted.",
        )

    image_bytes = await file.read()
    return image_model.predict(image_bytes)
