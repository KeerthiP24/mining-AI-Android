from pydantic import BaseModel


class BehaviorAnalysisRequest(BaseModel):
    uid: str


class DetectedPattern(BaseModel):
    pattern_type: str    # "weekly_skip" | "night_shift_gap" | "escalating_severity" | "repeated_ppe_miss" | "inactivity_spike"
    severity: str        # "low" | "medium" | "high"
    description: str
    recommended_action: str
    data_points: list[str]


class BehaviorAnalysisResponse(BaseModel):
    uid: str
    analysis_window_days: int
    patterns_found: list[DetectedPattern]
    overall_behavior_score: float  # 0.0–1.0 (higher is safer)
    last_analyzed_at: str          # ISO timestamp
