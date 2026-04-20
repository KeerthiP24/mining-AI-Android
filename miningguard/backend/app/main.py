from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_v1_router
from app.config import settings
from app.core.firebase_admin import initialize_firebase
from app.core.logger import logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — runs setup on start, cleanup on shutdown."""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    initialize_firebase()
    logger.info("All services initialized. Ready to serve requests.")
    yield
    logger.info("Shutting down MiningGuard AI Backend.")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="AI-powered safety analysis backend for MiningGuard mobile app.",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,  # Disable Swagger in production
    redoc_url="/redoc" if settings.debug else None,
)

# CORS — allow Flutter app to call the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# Register routes
app.include_router(api_v1_router)


@app.get("/health")
async def health_check():
    """Liveness probe endpoint for Render.com / Cloud Run health checks."""
    return {"status": "healthy", "version": settings.app_version}
