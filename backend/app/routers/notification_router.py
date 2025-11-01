from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import get_current_user
from app.services.notification_service import get_unread_notifications, mark_notification_as_read
from app.schemas.requests.mark_read_request import MarkReadRequest
import logging

logger = logging.getLogger(__name__)

router_notification = APIRouter()

@router_notification.get("/notifications/unread")
async def get_notifications(current_user: dict = Depends(get_current_user)):
    """Récupère les notifications non lues de l'utilisateur connecté"""
    user_id = str(current_user.get("id") or current_user.get("code"))
    
    notifications = get_unread_notifications(user_id)
    logger.info(f"📬 {len(notifications)} notifications non lues pour user_id={user_id}")
    
    return {
        "count": len(notifications),
        "notifications": notifications
    }

@router_notification.post("/notifications/mark-read")
async def mark_read(
    request: MarkReadRequest,
    current_user: dict = Depends(get_current_user)
):
    """Marque une notification comme lue"""
    user_id = str(current_user.get("id") or current_user.get("code"))
    
    # ✅ VALIDATION : Vérifier que notification_id est bien fourni
    if request.notification_id is None:
        logger.error(f"❌ notification_id manquant pour user_id={user_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="notification_id est requis"
        )
    
    success = mark_notification_as_read(user_id, request.notification_id)
    
    if not success:
        logger.warning(f"⚠️ Notification {request.notification_id} non trouvée pour {user_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification non trouvée"
        )
    
    return {
        "success": True,
        "message": "Notification marquée comme lue"
    }

@router_notification.post("/notifications/mark-all-read")
async def mark_all_read(current_user: dict = Depends(get_current_user)):
    """Marque toutes les notifications comme lues"""
    user_id = str(current_user.get("id") or current_user.get("code"))
    
    from app.core.cache import cache
    cache_key = f"notifications:{user_id}"
    cache.delete(cache_key)
    
    logger.info(f"✅ Toutes les notifications marquées comme lues pour {user_id}")
    
    return {
        "success": True,
        "message": "Toutes les notifications ont été marquées comme lues"
    }