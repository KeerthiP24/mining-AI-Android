"""
Risk Prediction Engine — Stub for Phase 1.
Full Gradient Boosting implementation in Phase 6.
"""
from app.schemas.risk_schema import (
    RiskContributingFactor,
    RiskPredictionRequest,
    RiskPredictionResponse,
)
from app.core.logger import logger


class RiskPredictionModel:
    """
    Placeholder risk model that returns a deterministic result
    based on simple threshold logic. Replaced in Phase 6 with
    a trained scikit-learn GradientBoostingClassifier.
    """

    def predict(self, request: RiskPredictionRequest) -> RiskPredictionResponse:
        logger.info(f"[RiskModel STUB] Predicting risk for uid={request.uid}")

        # Simple heuristic until real model is trained
        score = (
            (request.missed_checklists_7d * 10)
            + (request.consecutive_missed_days * 8)
            + (request.high_severity_reports_7d * 12)
            - (request.videos_watched_7d * 3)
            + ((1.0 - request.compliance_rate) * 30)
        )
        score = max(0.0, min(100.0, float(score)))

        if score >= 65:
            risk_level = "high"
        elif score >= 35:
            risk_level = "medium"
        else:
            risk_level = "low"

        factors = []
        if request.missed_checklists_7d >= 3:
            factors.append(RiskContributingFactor(
                factor="missed_checklists",
                impact="high",
                description=f"Missed {request.missed_checklists_7d} checklists in the last 7 days.",
            ))
        if request.compliance_rate < 0.6:
            factors.append(RiskContributingFactor(
                factor="low_compliance",
                impact="high",
                description=f"Compliance rate is {request.compliance_rate:.0%} — below the 60% threshold.",
            ))
        if request.high_severity_reports_7d >= 2:
            factors.append(RiskContributingFactor(
                factor="high_severity_reports",
                impact="medium",
                description=f"Filed {request.high_severity_reports_7d} high-severity reports this week.",
            ))

        return RiskPredictionResponse(
            uid=request.uid,
            risk_level=risk_level,
            risk_score=score,
            contributing_factors=factors,
            model_confidence=0.60,  # stub confidence
        )


# Singleton instance loaded at startup
risk_model = RiskPredictionModel()
