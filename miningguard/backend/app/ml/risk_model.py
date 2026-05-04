"""Risk-prediction inference wrapper.

Loads the trained `models/risk_model.pkl` lazily on first prediction call.
If the model file is missing, the lookup falls back to the deterministic
heuristic so the API still responds (mostly useful during early dev when
training hasn't been run yet).
"""
from __future__ import annotations

import os
from typing import Optional

import joblib
import numpy as np

from app.config import settings
from app.core.logger import logger
from app.ml.risk_train import FEATURE_ORDER
from app.schemas.risk_schema import (
    RiskContributingFactor,
    RiskPredictionRequest,
    RiskPredictionResponse,
)

ROLE_MAP = {"worker": 0, "supervisor": 1, "admin": 2}
SHIFT_MAP = {"morning": 0, "afternoon": 1, "night": 2}

# Each entry returns either a RiskContributingFactor or None (skip).
_FACTOR_BUILDERS = {
    "missed_checklists_7d": lambda v: RiskContributingFactor(
        factor="missed_checklists",
        impact="high",
        description=f"Missed {int(v)} checklist(s) in the last 7 days.",
    ) if v >= 2 else None,

    "consecutive_missed_days": lambda v: RiskContributingFactor(
        factor="consecutive_missed_days",
        impact="high",
        description=f"{int(v)} consecutive days without a completed checklist.",
    ) if v >= 2 else None,

    "compliance_rate": lambda v: RiskContributingFactor(
        factor="low_compliance",
        impact="high" if v < 0.5 else "medium",
        description=f"Overall compliance rate is {int(v * 100)}% — below the safe threshold.",
    ) if v < 0.65 else None,

    "high_severity_reports_7d": lambda v: RiskContributingFactor(
        factor="high_severity_reports",
        impact="medium",
        description=f"Filed {int(v)} high-severity hazard report(s) this week.",
    ) if v >= 2 else None,

    "total_reports_7d": lambda v: RiskContributingFactor(
        factor="elevated_reporting",
        impact="low",
        description=f"Filed {int(v)} hazard reports in 7 days — elevated reporting activity.",
    ) if v >= 4 else None,

    "videos_watched_7d": lambda v: RiskContributingFactor(
        factor="active_education",
        impact="low",
        description=f"Watched {int(v)} safety video(s) this week (positive signal).",
    ) if v >= 3 else None,
}


class RiskPredictionModel:
    """Singleton inference wrapper around the trained GBC."""

    def __init__(self) -> None:
        self._model: Optional[object] = None

    def _load(self) -> None:
        if self._model is not None:
            return
        path = settings.risk_model_path
        if not os.path.exists(path):
            logger.warning(
                f"[RiskModel] Trained model not found at {path}. "
                "Run `python -m app.ml.risk_train` to generate it."
            )
            return
        self._model = joblib.load(path)
        logger.info(f"[RiskModel] Loaded trained model from {path}")

    def predict(self, request: RiskPredictionRequest) -> RiskPredictionResponse:
        self._load()
        feat_vec = self._featurize(request)

        if self._model is None:
            return self._heuristic_fallback(request)

        # Real inference
        proba = self._model.predict_proba(feat_vec)[0]
        classes = list(self._model.classes_)
        label_idx = int(np.argmax(proba))
        label = str(classes[label_idx])
        confidence = float(proba[label_idx])

        # Risk score: 0/33/66 floors plus up-to-34 from confidence
        base = {"low": 0, "medium": 33, "high": 66}.get(label, 0)
        risk_score = float(min(100, int(base + confidence * 34)))

        factors = self._build_factors(request)

        return RiskPredictionResponse(
            uid=request.uid,
            risk_level=label,
            risk_score=risk_score,
            contributing_factors=factors,
            model_confidence=round(confidence, 3),
        )

    # ── Helpers ─────────────────────────────────────────────────────────────

    def _featurize(self, r: RiskPredictionRequest) -> np.ndarray:
        values = {
            "missed_checklists_7d": r.missed_checklists_7d,
            "consecutive_missed_days": r.consecutive_missed_days,
            "compliance_rate": r.compliance_rate,
            "high_severity_reports_7d": r.high_severity_reports_7d,
            "total_reports_7d": r.total_reports_7d,
            "videos_watched_7d": r.videos_watched_7d,
            "role_encoded": ROLE_MAP.get(r.role.lower(), 0),
            "shift_encoded": SHIFT_MAP.get(r.shift.lower(), 0),
        }
        row = [values[f] for f in FEATURE_ORDER]
        return np.array([row], dtype=np.float32)

    def _build_factors(
        self, r: RiskPredictionRequest
    ) -> list[RiskContributingFactor]:
        values = {
            "missed_checklists_7d": r.missed_checklists_7d,
            "consecutive_missed_days": r.consecutive_missed_days,
            "compliance_rate": r.compliance_rate,
            "high_severity_reports_7d": r.high_severity_reports_7d,
            "total_reports_7d": r.total_reports_7d,
            "videos_watched_7d": r.videos_watched_7d,
        }
        factors = [
            builder(values[k])
            for k, builder in _FACTOR_BUILDERS.items()
            if builder(values[k]) is not None
        ]
        if not factors:
            factors.append(
                RiskContributingFactor(
                    factor="all_clear",
                    impact="low",
                    description="All safety indicators are within normal range.",
                )
            )
        return factors

    def _heuristic_fallback(
        self, r: RiskPredictionRequest
    ) -> RiskPredictionResponse:
        """Cheap deterministic fallback used when the model file is missing."""
        score = (
            (r.missed_checklists_7d * 10)
            + (r.consecutive_missed_days * 8)
            + (r.high_severity_reports_7d * 12)
            - (r.videos_watched_7d * 3)
            + ((1.0 - r.compliance_rate) * 30)
        )
        score = max(0.0, min(100.0, float(score)))
        if score >= 65:
            level = "high"
        elif score >= 35:
            level = "medium"
        else:
            level = "low"
        return RiskPredictionResponse(
            uid=r.uid,
            risk_level=level,
            risk_score=score,
            contributing_factors=self._build_factors(r),
            model_confidence=0.50,
        )


# Singleton instance shared across requests.
risk_model = RiskPredictionModel()
