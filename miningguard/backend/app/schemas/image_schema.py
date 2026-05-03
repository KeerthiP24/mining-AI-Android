from pydantic import BaseModel, Field


class ImageDetectionResponse(BaseModel):
    hazard_detected: str         # "missing_helmet" | "missing_vest" | "unsafe_environment" | "machinery_hazard" | "safe" | category
    confidence: float            # 0.0–1.0
    suggested_severity: str      # "low" | "medium" | "high" | "critical"
    recommended_action: str = Field(
        ...,
        description="Action to take based on the detected hazard.",
    )
    processing_time_ms: int = 0
