from typing import Optional
from app.services.websocket_service import manager
from app.models.notification_model import NotificationModel
from app.core.cache import cache
import logging
import json
import time

logger = logging.getLogger(__name__)

async def send_notification(
    user_id: str, 
    title: str, 
    message: str, 
    type: str = "info", 
    broadcast: bool = False,
    sender_id: Optional[str] = None  # ✅ AJOUT : ID de l'émetteur à exclure
):
    """
    Envoie une notification en temps réel via WebSocket
    
    Args:
        user_id: ID du destinataire (ou "all" pour broadcast)
        title: Titre de la notification
        message: Message
        type: Type (info, success, warning, error)
        broadcast: Si True, envoyer à tous sauf sender_id
        sender_id: ID de l'émetteur à exclure des broadcasts
    """
    
    # Générer un ID unique
    notification_id = int(f"{int(time.time() * 1000)}{hash(user_id) % 1000:03d}")
    
    notification = NotificationModel(
        id=notification_id,
        user_id=user_id,
        title=title,
        message=message,
        type=type,
        broadcast=broadcast
    )
    
    notification_dict = notification.model_dump(mode='json')
    
    if broadcast:
        logger.info(f"📢 Broadcast notification: {title} (exclusion: {sender_id})")
        # ✅ CORRECTION : Exclure l'émetteur du broadcast
        await manager.broadcast(notification_dict, exclude_user_id=sender_id)
    else:
        logger.info(f"📨 Notification personnelle pour {user_id}: {title}")
        
        # Stocker dans Redis
        cache_key = f"notifications:{user_id}"
        existing = cache.get_data_only(cache_key) or "[]"
        notifications = json.loads(existing)
        notifications.append(notification_dict)
        cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)
        
        # Envoyer via WebSocket
        await manager.send_to_user(notification_dict, user_id)
    
    logger.info(f"📬 Notification envoyée (ID: {notification_id}): {title}")

async def notify_all_users(title: str, message: str, type: str = "info", sender_id: Optional[str] = None):
    """
    Envoie une notification broadcast à tous les utilisateurs connectés
    
    Args:
        title: Titre
        message: Message
        type: Type de notification
        sender_id: ID de l'émetteur à exclure
    """
    await send_notification(
        user_id="all",
        title=title,
        message=message,
        type=type,
        broadcast=True,
        sender_id=sender_id  # ✅ Passer l'émetteur pour exclusion
    )

async def notify_equipment_created(equipment_code: str, equipment_category: str, user_id: str, created_by: str):
    """Notification pour création d'équipement"""
    title = "Nouvel équipement créé"
    message = f"L'équipement {equipment_code} ({equipment_category}) a été créé par l'utilisateur GMAO {created_by}."
    
    # Notification personnelle uniquement pour le créateur
    await send_notification(user_id, title, message, "success", broadcast=False)

async def notify_equipment_updated(user_id: str, equipment_code: str):
    """Notification pour modification d'équipement"""
    await send_notification(
        user_id=user_id,
        title="Équipement modifié",
        message=f"L'équipement {equipment_code} a été mis à jour.",
        type="info",
        broadcast=False
    )

def get_unread_notifications(user_id: str) -> list:
    """Récupère les notifications non lues depuis Redis"""
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    notifications = json.loads(existing)
    
    # Sécurité : s'assurer que toutes les notifications ont un ID
    for notif in notifications:
        if notif.get('id') is None:
            notif['id'] = int(time.time() * 1000)
    
    return notifications

def mark_notification_as_read(user_id: str, notification_id: int):
    """Marque une notification comme lue en la supprimant de Redis"""
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    notifications = json.loads(existing)
    
    initial_count = len(notifications)
    notifications = [n for n in notifications if n.get("id") != notification_id]
    removed_count = initial_count - len(notifications)
    
    cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)
    
    logger.info(f"✅ Notification {notification_id} marquée comme lue pour {user_id} ({removed_count} supprimée)")
    return removed_count > 0