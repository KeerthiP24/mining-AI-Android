from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class Alert(BaseModel):
    alertId: str
    uid: str
    type: str
    severity: str
    title: str
    message: str
    isRead: bool = False
    notifiedVia: Optional[str] = None
    createdAt: Optional[datetime] = None


class AlertsListResponse(BaseModel):
    uid: str
    alerts: list[Alert]
    count: int


class MarkReadResponse(BaseModel):
    success: bool
