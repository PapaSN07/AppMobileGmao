from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException
from app.schemas.rest_response import create_simple_response
from app.services.famille_service import get_familles
import logging
import oracledb

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
famille_router = APIRouter(
    prefix="/famille",
    tags=["Famille - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===
@famille_router.get("",
    summary="Liste des familles",
    description="Récupère la liste des familles pour mobile"
)
async def get_familles_mobile(
    entity: str = Query(..., description="Entité obligatoire (hiérarchie automatique)"),
    hierarchy_result: Dict[str, Any] = Query(..., description="Résultat de la hiérarchie de l'entité")
) -> Dict[str, Any]:
    """Liste des familles pour mobile"""
    try:
        result = get_familles(entity=entity, hierarchy_result=hierarchy_result)

        return {
            "status": "success",
            "message": "Familles récupérées avec succès",
            "data": result
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des familles")