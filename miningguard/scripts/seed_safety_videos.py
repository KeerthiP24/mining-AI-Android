"""Seed safety_videos collection in Firestore.

Reads `seed_videos.json` (sibling file) and writes each entry to the
`safety_videos` collection with a stable document id, deterministic upload
timestamp, and the auto-derived YouTube thumbnail URL.

Usage:
    pip install firebase-admin
    python scripts/seed_safety_videos.py \\
        --project YOUR_FIREBASE_PROJECT_ID \\
        --creds path/to/service-account.json
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def _stub_translations(field: dict[str, str]) -> dict[str, str]:
    """Phase 5 ships English-only; mirror EN into the other language slots
    so the localize fallback chain succeeds even if the UI requests hi/bn/etc.
    Phase 9 replaces these stubs with real translations.
    """
    en = field.get("en", "")
    return {
        "en": en,
        "hi": field.get("hi", en),
        "bn": field.get("bn", en),
        "te": field.get("te", en),
        "mr": field.get("mr", en),
        "or": field.get("or", en),
    }


def _localize_question(question: dict) -> dict:
    return {
        "questionId": question["questionId"],
        "question": _stub_translations(question["question"]),
        "options": [_stub_translations(o) for o in question["options"]],
        "correctOptionIndex": question["correctOptionIndex"],
        "explanation": _stub_translations(question["explanation"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed safety_videos.")
    parser.add_argument("--project", required=True, help="Firebase project id")
    parser.add_argument(
        "--creds",
        required=True,
        help="Path to service-account JSON",
    )
    parser.add_argument(
        "--seed",
        default=str(Path(__file__).with_name("seed_videos.json")),
        help="Path to seed JSON (defaults to scripts/seed_videos.json)",
    )
    args = parser.parse_args()

    if not os.path.exists(args.creds):
        print(f"[seed] Credentials not found: {args.creds}", file=sys.stderr)
        return 1
    if not os.path.exists(args.seed):
        print(f"[seed] Seed JSON not found: {args.seed}", file=sys.stderr)
        return 1

    cred = credentials.Certificate(args.creds)
    firebase_admin.initialize_app(cred, {"projectId": args.project})
    db = firestore.client()

    with open(args.seed, encoding="utf-8") as f:
        videos = json.load(f)

    uploaded_at = datetime.now(timezone.utc)
    written = 0
    for v in videos:
        video_id = v["videoId"]
        youtube_id = v["youtubeId"]
        doc = {
            "title": _stub_translations(v["title"]),
            "description": _stub_translations(v["description"]),
            "category": v["category"],
            "source": v["source"],
            "youtubeId": youtube_id,
            "thumbnailUrl": f"https://img.youtube.com/vi/{youtube_id}/hqdefault.jpg",
            "durationSeconds": v["durationSeconds"],
            "targetRoles": v["targetRoles"],
            "tags": v["tags"],
            "quizQuestions": [_localize_question(q) for q in v["quizQuestions"]],
            "uploadedAt": uploaded_at,
            "isActive": True,
        }
        db.collection("safety_videos").document(video_id).set(doc)
        written += 1
        print(f"[seed] wrote safety_videos/{video_id}")

    print(f"[seed] done — {written} videos written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
