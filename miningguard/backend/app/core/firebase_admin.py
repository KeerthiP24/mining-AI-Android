import json
import os
import tempfile

import firebase_admin
from firebase_admin import credentials, firestore as fs, auth

from app.config import settings
from app.core.logger import logger


def _materialize_creds_from_env() -> None:
    """Render.com / managed-host helper: when the full service-account JSON
    is supplied via `GOOGLE_APPLICATION_CREDENTIALS_JSON`, write it to a
    tempfile and point `GOOGLE_APPLICATION_CREDENTIALS` at it. No-op if
    either env var is unset or the credentials path already exists."""
    raw = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    if not raw:
        return
    if os.path.exists(settings.firebase_credentials_path):
        return
    tmp = tempfile.NamedTemporaryFile(
        mode="w", suffix=".json", delete=False, encoding="utf-8"
    )
    json.dump(json.loads(raw), tmp)
    tmp.close()
    settings.firebase_credentials_path = tmp.name
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = tmp.name

_app: firebase_admin.App | None = None


def initialize_firebase() -> firebase_admin.App:
    """
    Initialize the Firebase Admin SDK.
    Called once at application startup in main.py.
    Safe to call multiple times — returns existing app if already initialized.
    When running against local emulators (FIRESTORE_EMULATOR_HOST set), a real
    service account is not needed — we use a placeholder credential instead.
    """
    global _app
    if _app is not None:
        return _app

    _materialize_creds_from_env()

    using_emulator = bool(
        os.getenv("FIRESTORE_EMULATOR_HOST") or os.getenv("FIREBASE_AUTH_EMULATOR_HOST")
    )

    try:
        if using_emulator or not os.path.exists(settings.firebase_credentials_path):
            logger.info("Firebase emulator detected — initialising with Application Default Credentials.")
            _app = firebase_admin.initialize_app(options={
                "projectId": settings.firebase_project_id or "demo-miningguard",
            })
        else:
            cred = credentials.Certificate(settings.firebase_credentials_path)
            _app = firebase_admin.initialize_app(cred, {
                "projectId": settings.firebase_project_id,
            })
        logger.info("Firebase Admin SDK initialized successfully.")
        return _app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise


def get_firestore_client():
    """Return a Firestore client. Requires firebase to be initialized."""
    return fs.client()


def get_db():
    """
    Convenience accessor for the Firestore client. Initialises Firebase
    on first call so standalone scripts (training, ad-hoc queries) work
    without going through the FastAPI lifespan event.
    """
    if not firebase_admin._apps:
        initialize_firebase()
    return fs.client()


def get_auth_client():
    """Return the Firebase Auth client."""
    return auth


def get_messaging_client():
    """Return the Firebase Cloud Messaging client."""
    from firebase_admin import messaging
    return messaging
