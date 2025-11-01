import asyncio
import json
import logging
from typing import Dict, List, Optional
from fastapi import WebSocket

logger = logging.getLogger(__name__)

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info(f"✅ User {user_id} connecté. Total connexions: {len(self.active_connections[user_id])}")

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"❌ User {user_id} déconnecté")

    async def send_to_user(self, message: dict, user_id: str):
        """Envoie un message à un utilisateur spécifique"""
        if user_id not in self.active_connections:
            logger.warning(f"Aucune connexion active pour user_id={user_id}")
            return
        
        dead_connections = []
        for conn in self.active_connections[user_id]:
            try:
                await conn.send_text(json.dumps(message))
                logger.debug(f"📤 Message envoyé à {user_id}")
            except Exception as e:
                logger.error(f"❌ Erreur envoi à {user_id}: {e}")
                dead_connections.append(conn)
        
        for dead_conn in dead_connections:
            self.disconnect(dead_conn, user_id)

    async def broadcast(self, message: dict, exclude_user_id: Optional[str] = None):
        """
        Envoie un message à tous les utilisateurs connectés
        
        Args:
            message: Message à envoyer
            exclude_user_id: ID de l'utilisateur à exclure (généralement l'émetteur)
        """
        for user_id in list(self.active_connections.keys()):
            # ✅ CORRECTION : Exclure l'émetteur
            if exclude_user_id and user_id == exclude_user_id:
                logger.debug(f"⏭️ Broadcast: utilisateur {user_id} exclu (émetteur)")
                continue
                
            await self.send_to_user(message, user_id)
        
        logger.info(f"📢 Broadcast envoyé à {len(self.active_connections) - (1 if exclude_user_id else 0)} utilisateurs")

    async def start_heartbeat(self, websocket: WebSocket, user_id: str):
        """Envoie un ping toutes les 30s pour maintenir la connexion"""
        try:
            while True:
                await asyncio.sleep(30)
                await websocket.send_text(json.dumps({"type": "ping"}))
        except Exception:
            self.disconnect(websocket, user_id)

manager = WebSocketManager()