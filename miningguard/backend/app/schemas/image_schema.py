from pydantic import BaseModel


class ImageDetectionResponse(BaseModel):
    hazard_detected: str         # "missing_helmet" | "missing_vest" | "unsafe_environment" | "machinery_hazard" | "safe"
    confidence: float            # 0.0–1.0
    suggested_severity: str      # "low" | "medium" | "high" | "critical"
    correction_recommendation: str
    processing_time_ms: int
