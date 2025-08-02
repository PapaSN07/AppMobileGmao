from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException
from app.schemas.rest_response import create_simple_response
from app.services.user_service import (
    authenticate_user,
    logout_user
)
import logging
import oracledb

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
authenticate_user_router = APIRouter(
    prefix="/auth",
    tags=["Authentification GMAO - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===

@authenticate_user_router.post("/login",
    summary="Authentification utilisateur",
    description="Authentifie un utilisateur avec login et mot de passe"
)
async def login_user(
    username: str = Query(..., description="Identifiant de l'utilisateur"),
    password: str = Query(..., description="Mot de passe de l'utilisateur")
) -> Dict[str, Any]:
    """Authentification utilisateur"""
    try:
        if not username or not password:
            logger.warning("Username ou mot de passe manquant.")
            raise HTTPException(status_code=400, detail="Username et mot de passe requis")

        user = authenticate_user(username, password)
        if not user:
            raise HTTPException(status_code=401, detail="Identifiants invalides")
        logger.info(f"Utilisateur {username} authentifié avec succès")
        
        return create_simple_response(
            message="Authentification réussie",
            data=user.to_api_response(),
        )
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de l'authentification")

@authenticate_user_router.post("/logout",
    summary="Déconnexion utilisateur",
    description="Déconnecte l'utilisateur en cours"
)
async def logout_user_endpoint(
    username: str = Query(..., description="Identifiant de l'utilisateur")
) -> Dict[str, Any]:
    """Déconnexion utilisateur"""
    try:
        if not username or username.strip() == "":
            logger.warning("Login manquant ou invalide pour la déconnexion.")
            raise HTTPException(status_code=400, detail="Login requis pour la déconnexion")
        
        success = logout_user(username)
        if not success:
            logger.warning(f"Échec de la déconnexion pour {username}.")
            raise HTTPException(status_code=500, detail="Erreur lors de la déconnexion")
        
        logger.info(f"Utilisateur {username} déconnecté avec succès")
        return {"status": "success", "message": "Déconnexion réussie"}
    except Exception as e:
        logger.error(f"❌ Erreur de déconnexion: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la déconnexion")
