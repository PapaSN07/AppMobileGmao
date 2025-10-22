from fastapi import APIRouter, Depends
from app.services.notification_service import get_unread_notifications
from app.dependencies import get_current_user

router_notification = APIRouter(prefix="/notifications", tags=["Notifications"])

@router_notification.get("/unread")
async def get_unread(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user.get("id") or current_user.get("code"))
    return {"notifications": get_unread_notifications(user_id)}