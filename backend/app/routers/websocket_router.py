from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.services.websocket_service import manager
from app.services.jwt_service import jwt_service
import logging
import json

logger = logging.getLogger(__name__)
router_ws = APIRouter()

@router_ws.websocket("/ws/notifications")
async def websocket_notifications(
    websocket: WebSocket, 
    token: str = Query(..., description="JWT token pour authentification")
):
    """WebSocket pour les notifications en temps réel"""
    user_id = None
    try:
        # ✅ CORRECTION : Vérifier le token avec logs détaillées
        logger.info(f"🔐 Tentative de connexion WebSocket avec token: {token[:20]}...")
        payload = jwt_service.verify_token(token)
        
        if not payload:
            logger.warning(f"❌ Token invalide ou expiré: {token[:20]}...")
            await websocket.close(code=1008, reason="Token invalide ou expiré")
            return
        
        logger.info(f"✅ Token valide. Payload: {payload}")
        
        # ✅ CORRECTION : Extraire user_id en priorité depuis "sub" (comme dans login)
        user_id = str(payload.get("sub") or payload.get("id") or payload.get("code") or payload.get("username"))
        
        if not user_id:
            logger.error(f"❌ user_id manquant dans le token JWT. Payload: {payload}")
            await websocket.close(code=1008, reason="user_id manquant dans le token")
            return
        
        await manager.connect(websocket, user_id)
        logger.info(f"✅ WebSocket connecté pour user_id={user_id}")
        
        try:
            while True:
                # Recevoir les messages du client
                data = await websocket.receive_text()
                message = json.loads(data)
                
                logger.info(f"📨 Message reçu de {user_id}: {message}")
                
                # ✅ Gérer différents types de messages
                if message.get("action") == "mark_read":
                    # Client demande de marquer une notification comme lue
                    notification_id = message.get("notification_id")
                    if notification_id:
                        from app.services.notification_service import mark_notification_as_read
                        mark_notification_as_read(user_id, notification_id)
                        await websocket.send_text(json.dumps({
                            "type": "ack",
                            "message": f"Notification {notification_id} marquée comme lue"
                        }))
                
                elif message.get("action") == "ping":
                    # Heartbeat pour maintenir la connexion active
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    logger.debug(f"🏓 Pong envoyé à {user_id}")
                
                else:
                    logger.warning(f"⚠️ Action inconnue: {message}")
                
        except WebSocketDisconnect:
            logger.info(f"🔌 WebSocket déconnecté normalement pour user_id={user_id}")
            manager.disconnect(websocket, user_id)
        except json.JSONDecodeError as e:
            logger.error(f"❌ Message JSON invalide de {user_id}: {e}")
        except Exception as e:
            logger.error(f"❌ Erreur traitement message de {user_id}: {e}")
            manager.disconnect(websocket, user_id)
    
    except Exception as e:
        logger.error(f"❌ Erreur WebSocket inattendue: {e}", exc_info=True)
        if user_id:
            manager.disconnect(websocket, user_id)
        try:
            await websocket.close(code=1011, reason="Erreur serveur")
        except:
            pass