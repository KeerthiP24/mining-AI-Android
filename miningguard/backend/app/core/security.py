from typing import Optional

from fastapi import HTTPException, Request, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth

from app.config import settings
from app.core.logger import logger

# auto_error=False so we can fall back to the SKIP_AUTH dev bypass even when
# no Authorization header is present.
bearer_scheme = HTTPBearer(auto_error=False)


async def verify_firebase_token(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Security(bearer_scheme),
) -> dict:
    """
    Verify a Firebase ID token from the Authorization header.

    Two paths:
    - Production / staging: validate the bearer token via Firebase Admin SDK.
    - Development (`SKIP_AUTH=true`): skip validation and use `X-Dev-UID` /
      `X-Dev-Role` headers as the synthetic identity.

    Returns the decoded token dict (`uid`, `role`, etc).
    Raises HTTP 401 in production if the token is missing/invalid/expired.
    """
    if settings.skip_auth:
        return {
            "uid": request.headers.get("X-Dev-UID", "dev-user-001"),
            "role": request.headers.get("X-Dev-Role", "worker"),
            "_skip_auth": True,
        }

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header.",
        )

    token = credentials.credentials
    try:
        decoded = auth.verify_id_token(token)
        return decoded
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase token has expired. Please re-authenticate.",
        )
    except auth.InvalidIdTokenError as e:
        logger.warning(f"Invalid Firebase token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase token.",
        )
    except Exception as e:
        logger.error(f"Token verification error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed.",
        )
