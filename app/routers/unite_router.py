from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException
from app.schemas.rest_response import create_simple_response
from app.services.unite_service import get_unites
import logging
import oracledb

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
unite_router = APIRouter(
    prefix="/unite",
    tags=["Unité - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===
@unite_router.get("",
    summary="Liste des unités",
    description="Récupère la liste des unités pour mobile"
)
async def get_unites_mobile(
    entity: str = Query(..., description="Entité obligatoire (hiérarchie automatique)"),
    hierarchy_result: Dict[str, Any] = Query(..., description="Résultat de la hiérarchie de l'entité")
) -> Dict[str, Any]:
    """Liste des unités pour mobile"""
    try:
        result = get_unites(entity=entity, hierarchy_result=hierarchy_result)
        
        return {
            "status": "success",
            "message": "Unités récupérées avec succès",
            "data": result
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des unités")