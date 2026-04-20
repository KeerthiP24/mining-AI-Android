"""
Tests for the Risk Prediction API endpoint.
Phase 1: tests the stub model logic.
Phase 6: updated to test the trained model.
"""
from app.ml.risk_model import risk_model
from app.schemas.risk_schema import RiskPredictionRequest


def test_risk_prediction_low():
    """Worker with good compliance should get low risk."""
    request = RiskPredictionRequest(
        uid="test_worker_001",
        missed_checklists_7d=0,
        consecutive_missed_days=0,
        compliance_rate=1.0,
        high_severity_reports_7d=0,
        total_reports_7d=1,
        videos_watched_7d=3,
        role="worker",
        shift="morning",
    )
    response = risk_model.predict(request)
    assert response.risk_level == "low"
    assert response.risk_score < 35
    assert response.uid == "test_worker_001"


def test_risk_prediction_high():
    """Worker with poor compliance should get high risk."""
    request = RiskPredictionRequest(
        uid="test_worker_002",
        missed_checklists_7d=5,
        consecutive_missed_days=5,
        compliance_rate=0.3,
        high_severity_reports_7d=3,
        total_reports_7d=4,
        videos_watched_7d=0,
        role="worker",
        shift="night",
    )
    response = risk_model.predict(request)
    assert response.risk_level == "high"
    assert response.risk_score >= 65
    assert len(response.contributing_factors) > 0


def test_risk_prediction_medium():
    """Worker with moderate compliance should get medium risk."""
    request = RiskPredictionRequest(
        uid="test_worker_003",
        missed_checklists_7d=3,
        consecutive_missed_days=2,
        compliance_rate=0.7,
        high_severity_reports_7d=1,
        total_reports_7d=2,
        videos_watched_7d=1,
        role="worker",
        shift="afternoon",
    )
    response = risk_model.predict(request)
    assert response.risk_level in ["medium", "high"]
    assert response.uid == "test_worker_003"
