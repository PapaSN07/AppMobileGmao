from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from jose import jwt
from jose.exceptions import ExpiredSignatureError, JWTError
import bcrypt
from app.core.config import JWT_SECRET_KEY, JWT_ALGORITHM, JWT_ACCESS_TOKEN_EXPIRE_MINUTES, JWT_REFRESH_TOKEN_EXPIRE_DAYS
from app.core.cache import cache
import logging

logger = logging.getLogger(__name__)

# Contexte pour le hachage des mots de passe

class JWTService:
    def __init__(self):
        self.SECRET_KEY = JWT_SECRET_KEY
        self.ALGORITHM = JWT_ALGORITHM

    @staticmethod
    def hash_password(password: str) -> str:
        """Hache un mot de passe"""
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Vérifie un mot de passe haché"""
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

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
        logger.info(f"✅ Token créé pour user: {to_encode.get('username')} (sub={to_encode.get('sub')})")
        return encoded_jwt

    @staticmethod
    def create_refresh_token(data: Dict[str, Any]) -> str:
        """Crée un token de rafraîchissement JWT"""
        to_encode = data.copy()
        expire = datetime.now(timezone.utc) + timedelta(days=JWT_REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt

    def verify_token(self, token: str, expected_type: str = "access") -> dict | None:
        """
        Vérifie et décode un token JWT avec logs détaillés
        
        Args:
            token: Token JWT à vérifier
            expected_type: Type attendu ("access" ou "refresh")
        
        Returns:
            dict: Payload du token si valide, None sinon
        """
        try:
            logger.info("🔐 Décodage token JWT...")
            
            # Décoder le token
            payload = jwt.decode(token, self.SECRET_KEY, algorithms=[self.ALGORITHM])
            
            # ✅ CORRECTION : Vérifier le type attendu
            token_type = payload.get("type", "access")
            
            if token_type != expected_type:
                logger.warning(f"❌ Type de token incorrect: {token_type} (attendu: {expected_type})")
                return None
            
            logger.info(f"✅ Token {expected_type} décodé avec succès")
            return payload
            
        except ExpiredSignatureError:
            logger.error("❌ Token expiré")
            return None
        except JWTError as e:
            logger.error(f"❌ Token invalide: {e}")
            return None
        except Exception as e:
            logger.error(f"❌ Erreur inattendue lors de la vérification: {e}")
            return None

    @staticmethod
    def refresh_access_token(refresh_token: str) -> Optional[str]:
        """
        Crée un nouvel access token à partir d'un refresh token valide
        
        Args:
            refresh_token: Token de rafraîchissement
        
        Returns:
            str: Nouveau access token, None si refresh token invalide
        """
        try:
            jwt_service = JWTService()
            
            # ✅ CORRECTION : Vérifier que c'est bien un refresh token
            payload = jwt_service.verify_token(refresh_token, expected_type="refresh")
            
            if not payload:
                logger.error("❌ Refresh token invalide ou expiré")
                return None
            
            # Créer un nouvel access token avec les mêmes données
            new_access_token = jwt_service.create_access_token({
                "sub": payload.get("sub"),
                "id": payload.get("id"),
                "code": payload.get("code"),
                "username": payload.get("username"),
                "email": payload.get("email"),
                "role": payload.get("role"),
                "entity": payload.get("entity")
            })
            
            logger.info(f"✅ Nouveau access token créé pour user: {payload.get('sub')}")
            return new_access_token
            
        except Exception as e:
            logger.error(f"❌ Erreur lors du rafraîchissement: {e}")
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