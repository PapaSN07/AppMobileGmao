from fastapi import APIRouter, HTTPException
from app.services.user_service import add_user
from app.schemas.requests.user_request import AddUserRequest
from app.schemas.responses.user_response import AddUserResponse
import logging

logger = logging.getLogger(__name__)

# Routeur pour les utilisateurs web
user_router_web = APIRouter(
    prefix="/users",
    tags=["Utilisateurs - Web API"],
)

@user_router_web.post("",
    summary="Ajouter un utilisateur",
    description="Enregistre un nouvel utilisateur dans la DB temporaire MSSQL",
    response_model=AddUserResponse
)
async def create_user(request: AddUserRequest) -> AddUserResponse:
    """Ajoute un utilisateur"""
    try:
        result = add_user(request)
        if not result.success:
            # Lever une HTTPException pour les erreurs métier (400)
            raise HTTPException(status_code=400, detail=result.model_dump())
        return result
    except HTTPException:
        # Re-lancer les HTTPException (comme 400) sans les masquer
        raise
    except Exception as e:
        # Capturer seulement les erreurs inattendues (pas les HTTPException)
        logger.error(f"❌ Erreur inattendue dans l'endpoint create_user: {e}")
        raise HTTPException(status_code=500, detail="Erreur interne du serveur")