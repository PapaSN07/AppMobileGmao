import asyncio
import json
import logging
from typing import Dict, List
from fastapi import WebSocket
from app.core.cache import RedisCache

logger = logging.getLogger(__name__)
cache = RedisCache()

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info(f"✅ User {user_id} connecté. Total: {len(self.active_connections[user_id])}")

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_connections:
            try:
                self.active_connections[user_id].remove(websocket)
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
                logger.info(f"❌ User {user_id} déconnecté")
            except ValueError:
                logger.warning(f"WebSocket déjà supprimé pour {user_id}")

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
        
        # ✅ CORRECTION : Nettoyer les connexions mortes
        for dead_conn in dead_connections:
            self.disconnect(dead_conn, user_id)

    async def broadcast(self, message: dict):
        """Envoie un message à tous les utilisateurs connectés"""
        for user_id in list(self.active_connections.keys()):
            await self.send_to_user(message, user_id)
    
    async def start_heartbeat(self, websocket: WebSocket, user_id: str):
        """Envoie un ping toutes les 30s pour maintenir la connexion"""
        try:
            while True:
                await asyncio.sleep(30)
                await websocket.send_text(json.dumps({"type": "ping"}))
        except Exception:
            self.disconnect(websocket, user_id)

manager = WebSocketManager()