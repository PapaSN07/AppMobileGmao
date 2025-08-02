from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException, Path
from app.schemas.rest_response import create_simple_response
from app.services.entity_service import (
    get_entities,
    get_hierarchy
)
import logging
import oracledb

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
entity_router = APIRouter(
    prefix="/entity",
    tags=["Entité - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===

@entity_router.get("/",
    summary="Liste des entités",
    description="Récupère la liste des entités pour mobile"
)
async def get_entity_mobile(
    limit: int = Query(20, ge=10, le=100, description="Nombre d'éléments (10-100)"),
    code: str = Query(..., description="Code de l'entité à récupérer")
) -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    try:
        result = get_entities(limit=limit, code=code)

        return {
            "status": "success",
            "message": "Entités récupérées avec succès",
            "data": {
                "entities": result["entities"],
                "pagination": {
                    "count": result["count"],
                    "limit": limit,
                    "total_available": result.get("total_available", result["count"])
                }
            }
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des entités")


# @entity_router.get("/search",
#     summary="Recherche d'entités",
#     description="Recherche dans les entités par code ou description"
# )
# async def search_entities(
#     q: str = Query(..., min_length=2, description="Terme de recherche"),
#     limit: int = Query(20, ge=10, le=50, description="Nombre d'éléments")
# ) -> Dict[str, Any]:
#     """Recherche d'entités"""
#     try:
#         # Cette fonctionnalité nécessiterait une fonction dédiée dans le service
#         # Pour l'instant, on retourne un message
#         return {
#             "status": "info",
#             "message": "Fonctionnalité de recherche à implémenter",
#             "data": {
#                 "query": q, 
#                 "limit": limit,
#                 "suggestion": "Utilisez les endpoints /type/{entity_type} pour filtrer par type"
#             }
#         }
#     except Exception as e:
#         logger.error(f"❌ Erreur recherche: {e}")
#         raise HTTPException(status_code=500, detail="Erreur lors de la recherche")

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