"""Backfill the Phase 7 dashboard counters for every user.

Computes `pendingReportCount` and `todayChecklistDone` from current Firestore
state and writes them to each `users/` document. Safe to run any time —
overwrites both fields with the freshly-computed values.

Usage:
    python scripts/backfill_dashboard_counters.py \\
        --project mininggaurd \\
        --creds e:/secrets/mininggaurd-admin.json
"""

from __future__ import annotations

import argparse
import os
import sys
from collections import Counter
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore


OPEN_STATUSES = {"pending", "acknowledged", "in_progress"}
USERS_COLLECTION = "users"
REPORTS_COLLECTION = "hazard_reports"
CHECKLISTS_COLLECTION = "checklists"


def today_utc_key() -> str:
    n = datetime.now(timezone.utc)
    return f"{n.year:04d}-{n.month:02d}-{n.day:02d}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--creds", required=True)
    args = ap.parse_args()

    if not os.path.exists(args.creds):
        print(f"[backfill] credentials not found: {args.creds}", file=sys.stderr)
        return 1

    firebase_admin.initialize_app(
        credentials.Certificate(args.creds),
        {"projectId": args.project},
    )
    db = firestore.client()

    today = today_utc_key()

    # ── pendingReportCount per uid ──────────────────────────────────────────
    pending_per_uid: Counter[str] = Counter()
    for status in OPEN_STATUSES:
        for doc in (
            db.collection(REPORTS_COLLECTION)
            .where("status", "==", status)
            .stream()
        ):
            uid = doc.to_dict().get("uid", "")
            if uid:
                pending_per_uid[uid] += 1

    # ── todayChecklistDone per uid ──────────────────────────────────────────
    submitted_today: set[str] = set()
    for doc in (
        db.collection(CHECKLISTS_COLLECTION)
        .where("date", "==", today)
        .where("status", "==", "submitted")
        .stream()
    ):
        uid = doc.to_dict().get("uid", "")
        if uid:
            submitted_today.add(uid)

    # ── batched writes (Firestore limit = 500) ──────────────────────────────
    user_docs = list(db.collection(USERS_COLLECTION).stream())
    written = 0
    for i in range(0, len(user_docs), 400):
        batch = db.batch()
        for doc in user_docs[i : i + 400]:
            batch.update(
                doc.reference,
                {
                    "pendingReportCount": pending_per_uid.get(doc.id, 0),
                    "todayChecklistDone": doc.id in submitted_today,
                },
            )
            written += 1
        batch.commit()

    print(
        f"[backfill] updated {written} users · "
        f"todayChecklistDone=true count={len(submitted_today)} · "
        f"pending counter total={sum(pending_per_uid.values())}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
