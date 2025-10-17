from app.services.websocket_service import manager
from app.models.notification_model import NotificationModel
from app.core.cache import cache
import logging
import json

logger = logging.getLogger(__name__)

async def send_notification(user_id: str, title: str, message: str, type: str = "info"):
    """Envoie une notification en temps réel via WebSocket"""
    notification = NotificationModel(
        user_id=user_id,
        title=title,
        message=message,
        type=type
    )
    
    # ✅ CORRECTION : Stocker dans Redis pour notifications non lues
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    notifications = json.loads(existing)
    notifications.append(notification.model_dump(mode='json'))
    cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)  # 7 jours
    
    # Envoyer via WebSocket si connecté
    await manager.send_to_user(notification.model_dump(mode='json'), user_id)
    logger.info(f"📬 Notification envoyée à {user_id}: {title}")

async def notify_equipment_created(user_id: str, equipment_code: str):
    """Notification pour création d'équipement"""
    await send_notification(
        user_id=user_id,
        title="Nouvel équipement",
        message=f"L'équipement {equipment_code} a été créé avec succès.",
        type="success"
    )

async def notify_equipment_updated(user_id: str, equipment_code: str):
    """Notification pour modification d'équipement"""
    await send_notification(
        user_id=user_id,
        title="Équipement modifié",
        message=f"L'équipement {equipment_code} a été mis à jour.",
        type="info"
    )

def get_unread_notifications(user_id: str) -> list:
    """Récupère les notifications non lues depuis Redis"""
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    return json.loads(existing)

def mark_notification_as_read(user_id: str, notification_id: int):
    """Marque une notification comme lue"""
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    notifications = json.loads(existing)
    # Filtrer la notification lue
    notifications = [n for n in notifications if n.get("id") != notification_id]
    cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)