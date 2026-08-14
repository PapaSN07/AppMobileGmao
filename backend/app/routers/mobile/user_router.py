import logging
from typing import Optional
from fastapi import APIRouter, Query, HTTPException
from app.services.coswin_user_service import CoswinUserService
from app.schemas.rest_response import RestResponse

logger = logging.getLogger(__name__)

mobile_user_router = APIRouter(
    prefix="/users",
    tags=["Utilisateurs - Mobile API"],
)

@mobile_user_router.get("/search", response_model=RestResponse)
async def search_users(
    query: Optional[str] = Query(None, description="Recherche par nom, matricule ou email"),
    entity: Optional[str] = Query(None, description="Filtre par entité (ex: SDPG)"),
    limit: int = Query(50, ge=1, le=200)
):
    """Recherche des agents Coswin depuis la table coswin_user pour autocomplétion"""
    try:
        users = CoswinUserService.search_users(query_str=query or "", entity=entity, limit=limit)
        return RestResponse(
            success=True,
            data=users,
            message=f"{len(users)} utilisateur(s) trouvé(s)"
        )
    except Exception as e:
        logger.error(f"Erreur endpoint search_users: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la recherche des utilisateurs")

@mobile_user_router.get("/validate/{code}", response_model=RestResponse)
async def validate_user_code(code: str):
    """Vérifie si un matricule/code utilisateur existe dans coswin_user"""
    try:
        is_valid = CoswinUserService.validate_employee_code(code)
        user_info = CoswinUserService.get_user_by_code(code) if is_valid else None
        return RestResponse(
            success=True,
            data={"valid": is_valid, "user": user_info},
            message="Matricule valide" if is_valid else "Matricule non trouvé dans Coswin"
        )
    except Exception as e:
        logger.error(f"Erreur endpoint validate_user_code: {e}")
        raise HTTPException(status_code=500, detail="Erreur de validation du matricule")
