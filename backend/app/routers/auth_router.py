from typing import Any, Dict
from fastapi import APIRouter, HTTPException
from app.core.exceptions import DatabaseError, InvalidPasswordError, UserNotFoundError
from app.schemas.responses.auth_response import AuthResponse
from app.services.jwt_service import jwt_service
from app.services.auth_service import (
    authenticate_user,
    logout_user
)
from app.schemas.requests.auth_request import (LoginRequest, LogoutRequest)
import logging

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
authenticate_user_router = APIRouter(
    prefix="/auth",
    tags=["Authentification GMAO - Mobile/WEB API"],
)

# === ENDPOINTS CORE POUR WEB ===

@authenticate_user_router.post("/login",
    summary="Authentification utilisateur",
    description="Authentifie un utilisateur avec login et mot de passe",
    response_model=AuthResponse
)
async def login_user(
    login_request: LoginRequest
) -> AuthResponse:
    """Authentification utilisateur"""
    try:
        # Extraction des données depuis le body
        username = login_request.username.strip()
        password = login_request.password.strip()

        if not username or not password:
            logger.warning("Username ou mot de passe manquant.")
            raise HTTPException(status_code=400, detail="Username et mot de passe requis")

        user = authenticate_user(username, password)
        
        if not user:
            raise HTTPException(status_code=401, detail="Identifiants invalides")
        
        # Créer les tokens
        user_data = {"sub": str(user.id), "username": user.username, "role": user.role}
        access_token = jwt_service.create_access_token(user_data)
        refresh_token = jwt_service.create_refresh_token(user_data)
        
        # Stocker le refresh token dans Redis
        jwt_service.store_refresh_token(username, refresh_token)
        
        logger.info(f"Utilisateur {username} authentifié avec succès")
        
        return AuthResponse(
            success=True,
            data=user.to_dict(),
            count=1,
            message="Authentification réussie",
            access_token=access_token,
            refresh_token=refresh_token
        )
        
    except UserNotFoundError as e:
        logger.warning(f"Utilisateur non trouvé: {e.message}")
        raise HTTPException(status_code=e.status_code, detail={"status": e.status_code, "error_code": e.error_code, "message": e.message})
    except InvalidPasswordError as e:
        logger.warning(f"Mot de passe incorrect: {e.message}")
        raise HTTPException(status_code=e.status_code, detail={"status": e.status_code, "error_code": e.error_code, "message": e.message})
    except DatabaseError as e:
        logger.error(f"Erreur DB: {e.message}")
        raise HTTPException(status_code=e.status_code, detail={"error_code": e.error_code, "message": e.message})
    except ValueError as e:
        raise HTTPException(status_code=400, detail={"status": 400, "error_code": "VALIDATION_ERROR", "message": str(e)})
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail={"status": 500, "error_code": "UNKNOWN_ERROR", "message": "Erreur lors de l'authentification"})

@authenticate_user_router.post("/logout",
    summary="Déconnexion utilisateur",
    description="Déconnecte l'utilisateur en cours"
)
async def logout_user_endpoint(
    logout_request: LogoutRequest
) -> Dict[str, Any]:
    """Déconnexion utilisateur"""
    try:
        # Extraction des données depuis le body
        username = logout_request.username.strip()
        
        if not username or username.strip() == "":
            logger.warning("Login manquant ou invalide pour la déconnexion.")
            raise HTTPException(status_code=400, detail="Login requis pour la déconnexion")
        
        # Révoquer le refresh token
        jwt_service.revoke_refresh_token(username)
        
        success = logout_user(username)
        
        if not success:
            logger.warning(f"Échec de la déconnexion pour {username}.")
            raise HTTPException(status_code=500, detail="Erreur lors de la déconnexion")
        
        logger.info(f"Utilisateur {username} déconnecté avec succès")
        return {"status": "success", "message": "Déconnexion réussie"}
    except Exception as e:
        logger.error(f"❌ Erreur de déconnexion: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la déconnexion")

@authenticate_user_router.post("/refresh",
    summary="Rafraîchir le token d'accès",
    description="Utilise un refresh token pour obtenir un nouveau access token"
)
async def refresh_token_endpoint(refresh_request: Dict[str, str]) -> Dict[str, Any]:
    """Rafraîchir le token d'accès"""
    try:
        refresh_token = refresh_request.get("refresh_token")
        if not refresh_token:
            raise HTTPException(status_code=400, detail="Refresh token requis")
        
        new_access_token = jwt_service.refresh_access_token(refresh_token)
        if not new_access_token:
            raise HTTPException(status_code=401, detail="Refresh token invalide")
        
        return {
            "success": True,
            "access_token": new_access_token,
            "token_type": "bearer"
        }
    except Exception as e:
        logger.error(f"❌ Erreur de rafraîchissement: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors du rafraîchissement")
