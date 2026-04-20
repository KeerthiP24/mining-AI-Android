"""
Image Hazard Detection Engine — Stub for Phase 1.
Full MobileNetV2 TensorFlow implementation in Phase 6.
"""
from app.schemas.image_schema import ImageDetectionResponse
from app.core.logger import logger


class ImageDetectionModel:
    """
    Placeholder that returns a safe result for all images.
    Replaced in Phase 6 with a fine-tuned MobileNetV2 classifier.
    """

    def predict(self, image_bytes: bytes) -> ImageDetectionResponse:
        logger.info(f"[ImageModel STUB] Analyzing image ({len(image_bytes)} bytes)")
        return ImageDetectionResponse(
            hazard_detected="safe",
            confidence=0.50,
            suggested_severity="low",
            correction_recommendation="No immediate action required. (Model stub — full analysis available in Phase 6.)",
            processing_time_ms=10,
        )


image_model = ImageDetectionModel()
