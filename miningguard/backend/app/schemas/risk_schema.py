from pydantic import BaseModel, Field


class RiskPredictionRequest(BaseModel):
    """
    Input features for the risk prediction model.
    All features must be present; use 0 as default if a value is unavailable.
    """
    uid: str = Field(..., description="Worker's Firebase UID")
    missed_checklists_7d: int = Field(
        ..., ge=0, le=7,
        description="Number of checklists missed in the last 7 days"
    )
    consecutive_missed_days: int = Field(
        ..., ge=0,
        description="Current streak of consecutive missed days"
    )
    compliance_rate: float = Field(
        ..., ge=0.0, le=1.0,
        description="Overall compliance rate as a fraction (0.0 to 1.0)"
    )
    high_severity_reports_7d: int = Field(
        ..., ge=0,
        description="High or critical severity reports filed in last 7 days"
    )
    total_reports_7d: int = Field(
        ..., ge=0,
        description="Total hazard reports filed in last 7 days"
    )
    videos_watched_7d: int = Field(
        ..., ge=0,
        description="Safety videos watched in last 7 days (positive signal)"
    )
    role: str = Field(..., description="worker | supervisor | admin")
    shift: str = Field(..., description="morning | afternoon | night")


class RiskContributingFactor(BaseModel):
    factor: str
    impact: str  # "high" | "medium" | "low"
    description: str


class RiskPredictionResponse(BaseModel):
    uid: str
    risk_level: str          # "low" | "medium" | "high"
    risk_score: float        # 0–100
    contributing_factors: list[RiskContributingFactor]
    model_confidence: float  # 0.0–1.0
