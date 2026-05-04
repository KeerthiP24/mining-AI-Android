"""Train the risk-prediction GradientBoostingClassifier.

Generates synthetic data using domain-knowledge labelling rules, fits a
GBC, and saves to `models/risk_model.pkl`. Run once before deploy:

    cd backend && python -m app.ml.risk_train
"""
from __future__ import annotations

import os
import sys

import joblib
import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from app.config import settings


# Order matters — must match RiskModel.FEATURE_ORDER in inference.
FEATURE_ORDER = [
    "missed_checklists_7d",
    "consecutive_missed_days",
    "compliance_rate",
    "high_severity_reports_7d",
    "total_reports_7d",
    "videos_watched_7d",
    "role_encoded",
    "shift_encoded",
]


def generate_synthetic_data(n: int = 8000, seed: int = 42) -> tuple[np.ndarray, np.ndarray]:
    """Synthetic supervised dataset built from domain rules + 5% label noise."""
    rng = np.random.default_rng(seed)
    X, y = [], []

    for _ in range(n):
        missed = int(rng.integers(0, 8))
        consec = int(rng.integers(0, 12))
        comp = float(rng.uniform(0.0, 1.0))
        hi_sev = int(rng.integers(0, 6))
        tot_rep = int(rng.integers(0, 12))
        videos = int(rng.integers(0, 10))
        role = int(rng.integers(0, 3))
        shift = int(rng.integers(0, 3))

        # Domain rules — matches the qualitative thresholds used by FACTOR_FN
        if missed >= 3 or consec >= 3 or comp < 0.4:
            label = "high"
        elif missed == 2 or (0.4 <= comp < 0.65) or hi_sev >= 2 or consec == 2:
            label = "medium"
        else:
            label = "low"

        # Night shift slightly elevates risk for marginal-compliance workers
        if shift == 2 and comp < 0.75 and label == "low":
            label = "medium"

        # 5% label noise so the model generalises rather than memorises
        if rng.random() < 0.05:
            label = str(rng.choice(["low", "medium", "high"]))

        X.append([missed, consec, comp, hi_sev, tot_rep, videos, role, shift])
        y.append(label)

    return np.array(X, dtype=np.float32), np.array(y)


def train(verbose: bool = True) -> str:
    """Generate data, fit, save. Returns the path the model was written to."""
    X, y = generate_synthetic_data(n=8000)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = GradientBoostingClassifier(
        n_estimators=300,
        max_depth=4,
        learning_rate=0.05,
        subsample=0.8,
        min_samples_leaf=10,
        random_state=42,
    )
    model.fit(X_train, y_train)

    if verbose:
        y_pred = model.predict(X_test)
        print("\nClassification report (held-out 20%):")
        print(classification_report(y_test, y_pred))
        print("\nFeature importances (descending):")
        for feat, imp in sorted(
            zip(FEATURE_ORDER, model.feature_importances_),
            key=lambda kv: -kv[1],
        ):
            print(f"  {feat:<28} {imp:.4f}")

    out = settings.risk_model_path
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    joblib.dump(model, out)
    if verbose:
        print(f"\nSaved model to {out}")
    return out


if __name__ == "__main__":
    sys.exit(0 if train() else 1)
