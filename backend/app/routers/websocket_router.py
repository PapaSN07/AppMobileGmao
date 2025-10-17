from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.services.websocket_service import manager
from app.services.jwt_service import jwt_service
import logging

logger = logging.getLogger(__name__)
router_ws = APIRouter()

@router_ws.websocket("/ws/notifications")
async def websocket_notifications(
    websocket: WebSocket, 
    token: str = Query(..., description="JWT token pour authentification")
):
    """WebSocket pour les notifications en temps réel"""
    try:
        # ✅ CORRECTION : Vérifier le token avec jwt_service directement
        payload = jwt_service.verify_token(token)
        if not payload:
            logger.warning("Token invalide pour WebSocket")
            await websocket.close(code=1008, reason="Token invalide")
            return
        
        # Extraire user_id du payload (adaptez selon votre structure JWT)
        user_id = str(payload.get("id") or payload.get("code") or payload.get("sub"))
        if not user_id:
            logger.error("user_id manquant dans le token JWT")
            await websocket.close(code=1008, reason="user_id manquant")
            return
        
        await manager.connect(websocket, user_id)
        logger.info(f"✅ WebSocket connecté pour user_id={user_id}")
        
        try:
            while True:
                # Recevoir les messages du client (heartbeat, ack, etc.)
                data = await websocket.receive_text()
                logger.debug(f"Message reçu de {user_id}: {data}")
                # Traiter si nécessaire (ex. : marquer notification comme lue)
        except WebSocketDisconnect:
            logger.info(f"WebSocket déconnecté pour user_id={user_id}")
            manager.disconnect(websocket, user_id)
    except Exception as e:
        logger.error(f"Erreur WebSocket: {e}")
        await websocket.close(code=1011, reason="Erreur serveur")