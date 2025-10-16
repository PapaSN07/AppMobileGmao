from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException, Path
import pymssql
from app.services.entity_service import (
    get_entities,
    get_hierarchy
)
import logging

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
entity_router = APIRouter(
    prefix="/entity",
    tags=["Entité - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===

@entity_router.get("",
    summary="Liste des entités",
    description="Récupère la liste des entités pour mobile"
)
async def get_entity_mobile(
    entity: str = Query(..., description="Entité de l'entité à récupérer"),
) -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    try:
        # Récupérer la hiérarchie dans la fonction
        hierarchy_result = get_hierarchy(entity)
        result = get_entities(entity=entity, hierarchy_result=hierarchy_result)

        return {
            "status": "success",
            "message": "Entités récupérées avec succès",
            "data": result
        }

    except pymssql.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des entités")

@entity_router.get("/hierarchy/{entity_code}",
    summary="Hiérarchie Oracle d'entité",
    description="Utilise la fonction Oracle sn_hierarchie pour récupérer la hiérarchie complète"
)
async def get_oracle_hierarchy(
    entity_code: str = Path(..., description="Code de l'entité à analyser")
) -> Dict[str, Any]:
    """Hiérarchie Oracle d'une entité"""
    try:
        result = get_hierarchy(entity_code=entity_code)
        
        return {
            "status": "success",
            "message": f"Hiérarchie Oracle de l'entité {entity_code} récupérée avec succès",
            "data": result
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur hiérarchie Oracle: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")