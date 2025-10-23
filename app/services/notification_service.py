from app.services.websocket_service import manager
from app.models.notification_model import NotificationModel
from app.core.cache import cache
import logging
import json
import time  # ✅ AJOUT

logger = logging.getLogger(__name__)

async def send_notification(user_id: str, title: str, message: str, type: str = "info", broadcast: bool = False):
    """Envoie une notification en temps réel via WebSocket"""
    
    # ✅ CORRECTION : Générer un ID unique basé sur timestamp + user_id
    notification_id = int(f"{int(time.time() * 1000)}{hash(user_id) % 1000:03d}")
    
    notification = NotificationModel(
        id=notification_id,  # ✅ ID généré
        user_id=user_id,
        title=title,
        message=message,
        type=type,
        broadcast=broadcast
    )
    
    notification_dict = notification.model_dump(mode='json')
    
    # Si broadcast, envoyer à tous
    if broadcast:
        logger.info(f"📢 Broadcast notification: {title}")
        await manager.broadcast(notification_dict)
        # ✅ Ne PAS stocker les notifications broadcast dans Redis
    else:
        # Notification personnelle
        logger.info(f"📨 Notification personnelle pour {user_id}: {title}")
        
        # ✅ Stocker dans Redis avec l'ID généré
        cache_key = f"notifications:{user_id}"
        existing = cache.get_data_only(cache_key) or "[]"
        notifications = json.loads(existing)
        notifications.append(notification_dict)
        cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)  # 7 jours
        
        # Envoyer via WebSocket si connecté
        await manager.send_to_user(notification_dict, user_id)
    
    logger.info(f"📬 Notification envoyée (ID: {notification_id}): {title}")

# ✅ Fonction pour notifier tous les utilisateurs
async def notify_all_users(title: str, message: str, type: str = "info"):
    """Envoie une notification broadcast à tous les utilisateurs connectés"""
    await send_notification(
        user_id="all",
        title=title,
        message=message,
        type=type,
        broadcast=True
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
    
    # ✅ SÉCURITÉ : S'assurer que toutes les notifications ont un ID
    for notif in notifications:
        if notif.get('id') is None:
            notif['id'] = int(time.time() * 1000)
    
    return notifications

def mark_notification_as_read(user_id: str, notification_id: int):
    """Marque une notification comme lue en la supprimant de Redis"""
    cache_key = f"notifications:{user_id}"
    existing = cache.get_data_only(cache_key) or "[]"
    notifications = json.loads(existing)
    
    # ✅ CORRECTION : Filtrer correctement par ID
    initial_count = len(notifications)
    notifications = [n for n in notifications if n.get("id") != notification_id]
    removed_count = initial_count - len(notifications)
    
    cache.set(cache_key, json.dumps(notifications), ttl=7*24*3600)
    
    logger.info(f"✅ Notification {notification_id} marquée comme lue pour {user_id} ({removed_count} supprimée)")
    return removed_count > 0