from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRE_MINUTES, JWT_REFRESH_TOKEN_EXPIRE_DAYS
from app.core.cache import cache
import logging

logger = logging.getLogger(__name__)

# Contexte pour le hachage des mots de passe
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class JWTService:
    @staticmethod
    def hash_password(password: str) -> str:
        """Hache un mot de passe"""
        return pwd_context.hash(password)

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Vérifie un mot de passe haché"""
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        """Crée un token d'accès JWT"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire, "type": "access"})
        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt

    @staticmethod
    def create_refresh_token(data: Dict[str, Any]) -> str:
        """Crée un token de rafraîchissement JWT"""
        to_encode = data.copy()
        expire = datetime.now(timezone.utc) + timedelta(days=JWT_REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt

    @staticmethod
    def verify_token(token: str) -> Optional[Dict[str, Any]]:
        """Vérifie et décode un token JWT"""
        try:
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
            # Vérifier si le token est blacklisté
            token_key = f"blacklist:{token}"
            if cache.exists(token_key):
                return None
            return payload
        except JWTError:
            return None

    @staticmethod
    def refresh_access_token(refresh_token: str) -> Optional[str]:
        """Rafraîchit un token d'accès à partir d'un token de rafraîchissement"""
        payload = JWTService.verify_token(refresh_token)
        if payload and payload.get("type") == "refresh":
            user_data = {"sub": payload.get("sub"), "username": payload.get("username")}
            return JWTService.create_access_token(user_data)
        return None

    @staticmethod
    def blacklist_token(token: str, ttl: int = 3600) -> bool:
        """Ajoute un token à la blacklist dans Redis"""
        token_key = f"blacklist:{token}"
        return cache.set(token_key, True, ttl)

    @staticmethod
    def store_refresh_token(username: str, refresh_token: str) -> bool:
        """Stocke le token de rafraîchissement dans Redis"""
        key = f"refresh:{username}"
        return cache.set(key, refresh_token, JWT_REFRESH_TOKEN_EXPIRE_DAYS * 24 * 3600)

    @staticmethod
    def get_refresh_token(username: str) -> Optional[str]:
        """Récupère le token de rafraîchissement depuis Redis"""
        key = f"refresh:{username}"
        return cache.get_data_only(key)

    @staticmethod
    def revoke_refresh_token(username: str) -> bool:
        """Révoque le token de rafraîchissement"""
        key = f"refresh:{username}"
        return cache.delete(key)

# Instance globale
jwt_service = JWTService()