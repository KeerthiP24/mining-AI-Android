from fastapi import APIRouter, Depends
from google.cloud.firestore_v1.base_query import FieldFilter

from app.api.deps import get_current_user
from app.core.firebase_admin import get_db
from app.schemas.alerts_schema import Alert, AlertsListResponse, MarkReadResponse

router = APIRouter()


@router.get("/{uid}", response_model=AlertsListResponse)
async def list_alerts(
    uid: str,
    unread_only: bool = False,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
) -> AlertsListResponse:
    """Return the most recent [limit] alerts for [uid], newest first."""
    db = get_db()
    query = (
        db.collection("alerts")
        .where(filter=FieldFilter("uid", "==", uid))
    )
    if unread_only:
        query = query.where(filter=FieldFilter("isRead", "==", False))
    query = query.order_by("createdAt", direction="DESCENDING").limit(limit)

    alerts = [
        Alert(**({"alertId": doc.id} | (doc.to_dict() or {})))
        for doc in query.stream()
    ]
    return AlertsListResponse(uid=uid, alerts=alerts, count=len(alerts))


@router.patch("/{uid}/read/{alert_id}", response_model=MarkReadResponse)
async def mark_alert_read(
    uid: str,
    alert_id: str,
    current_user: dict = Depends(get_current_user),
) -> MarkReadResponse:
    """Mark a single alert as read."""
    db = get_db()
    db.collection("alerts").document(alert_id).update({"isRead": True})
    return MarkReadResponse(success=True)
