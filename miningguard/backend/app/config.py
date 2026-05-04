from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    In development: create a .env file in backend/ with these values.
    In production: set these as environment variables on your hosting platform.
    Never commit .env to git.
    """

    # App
    app_name: str = "MiningGuard AI Backend"
    app_version: str = "1.0.0"
    debug: bool = False

    # Firebase Admin SDK
    # Path to your service account key JSON file
    firebase_credentials_path: str = "firebase-service-account.json"
    firebase_project_id: str = ""

    # CORS — Add your Flutter app's origin if using web, or keep * for mobile
    allowed_origins: list[str] = ["*"]

    # ML Model Paths
    risk_model_path: str = "models/risk_model.pkl"
    image_model_path: str = "models/image_model.h5"

    # Development bypass — when true, skips Firebase token verification and
    # uses X-Dev-UID / X-Dev-Role headers instead. NEVER enable in production.
    skip_auth: bool = False

    # FCM cooldown to prevent alert spam: minimum hours between same alert
    # type for the same user.
    alert_cooldown_hours: int = 24

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
