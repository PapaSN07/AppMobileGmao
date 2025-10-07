from typing import Optional
from fastapi import APIRouter, HTTPException, Path
from app.services.user_service import add_user, get_all_users, update_user, delete_user
from app.schemas.requests.user_request import AddUserRequest, UpdateUserRequest
from app.schemas.responses.user_response import (
    AddUserResponse, GetAllUsersResponse, UpdateUserResponse, DeleteUserResponse
)
import logging

logger = logging.getLogger(__name__)

# Routeur pour les utilisateurs web
user_router_web = APIRouter(
    prefix="/users",
    tags=["Utilisateurs - Web API"],
)

@user_router_web.get("/{supervisor_id}",
    summary="Récupérer tous les utilisateurs d'un superviseur",
    description="Récupère la liste de tous les utilisateurs associés à un superviseur donné",
    response_model=GetAllUsersResponse
)
async def get_users(
    supervisor_id: int = Path(..., description="ID du superviseur"),
):
    """Récupère tous les utilisateurs"""
    try:
        result = get_all_users(supervisor_id)
        if not result.success:
            raise HTTPException(status_code=500, detail=result.model_dump())
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur inattendue dans get_users: {e}")
        raise HTTPException(status_code=500, detail="Erreur interne du serveur")

@user_router_web.patch("/{user_id}",
    summary="Mettre à jour un utilisateur",
    description="Met à jour un utilisateur par ID",
    response_model=UpdateUserResponse)
async def update_user_endpoint(
    user_id: int = Path(..., description="ID de l'utilisateur"),
    request: Optional[UpdateUserRequest] = None
):
    """Met à jour un utilisateur"""
    try:
        if request is None:
            raise HTTPException(status_code=400, detail="Aucune donnée fournie pour la mise à jour")
        result = update_user(user_id, request)
        if not result.success:
            if result.error_code == "USER_NOT_FOUND":
                raise HTTPException(status_code=404, detail=result.model_dump())
            raise HTTPException(status_code=400, detail=result.model_dump())
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur inattendue dans update_user_endpoint: {e}")
        raise HTTPException(status_code=500, detail="Erreur interne du serveur")

@user_router_web.delete("/{user_id}",
    summary="Supprimer un utilisateur",
    description="Supprime un utilisateur par ID",
    response_model=DeleteUserResponse
)
async def delete_user_endpoint(user_id: int = Path(..., description="ID de l'utilisateur")):
    """Supprime un utilisateur"""
    try:
        result = delete_user(user_id)
        if not result.success:
            if result.error_code == "USER_NOT_FOUND":
                raise HTTPException(status_code=404, detail=result.model_dump())
            raise HTTPException(status_code=500, detail=result.model_dump())
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur inattendue dans delete_user_endpoint: {e}")
        raise HTTPException(status_code=500, detail="Erreur interne du serveur")

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