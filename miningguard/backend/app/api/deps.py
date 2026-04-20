from fastapi import Depends
from app.core.security import verify_firebase_token


async def get_current_user(
    token_data: dict = Depends(verify_firebase_token),
) -> dict:
    """
    Dependency that returns the verified Firebase user data.
    Inject into any route that requires authentication.
    """
    return token_data
