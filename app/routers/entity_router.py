from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException, Path
from app.schemas.rest_response import create_simple_response
from app.services.entity_service import (
    get_entities,
    get_entities_by_type,
    get_entities_hierarchy,
    get_entities_hierarchy_by_type  # NOUVELLE FONCTION
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
    limit: int = Query(20, ge=10, le=100, description="Nombre d'éléments (10-100)")
) -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    try:
        result = get_entities(limit=limit)
        
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

@entity_router.get("/type/{entity_type}",
    summary="Entités par type",
    description="Récupère les entités d'un type spécifique"
)
async def get_entities_by_type_mobile(
    entity_type: str = Path(..., description="Type d'entité (COMPANY, REGION, CENTER, etc.)"),
    limit: int = Query(20, ge=10, le=100, description="Nombre d'éléments (10-100)")
) -> Dict[str, Any]:
    """Entités par type pour mobile"""
    try:
        result = get_entities_by_type(entity_type=entity_type, limit=limit)
        
        return {
            "status": "success",
            "message": f"Entités de type {entity_type} récupérées avec succès",
            "data": {
                "entities": result["entities"],
                "entity_type": result["entity_type"],
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
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des entités de type {entity_type}")

@entity_router.get("/hierarchy/type/{entity_type}",
    summary="Hiérarchie d'entité par type",
    description="Récupère une entité et sa hiérarchie complète basée sur le type d'entité"
)
async def get_entities_hierarchy_by_type_mobile(
    entity_type: str = Path(..., description="Type d'entité (COMPANY, REGION, CENTER, DEPARTMENT, SUBSTATION, PARTNER)")
) -> Dict[str, Any]:
    """Hiérarchie d'entité par type pour mobile"""
    try:
        result = get_entities_hierarchy_by_type(entity_type=entity_type)
        
        return {
            "status": "success",
            "message": f"Hiérarchie des entités de type {entity_type} récupérée avec succès",
            "data": {
                "main_entity": result["main_entity"],
                "hierarchy": result["hierarchy"],
                "entity_type": result["entity_type"],
                "count": result["count"],
                "total_levels": result.get("total_levels", 1)
            }
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération de la hiérarchie pour le type {entity_type}")

@entity_router.get("/hierarchy",
    summary="Hiérarchie complète des entités",
    description="Récupère la structure hiérarchique complète de toutes les entités"
)
async def get_entities_hierarchy_mobile() -> Dict[str, Any]:
    """Hiérarchie complète des entités pour mobile"""
    try:
        result = get_entities_hierarchy()
        
        return {
            "status": "success",
            "message": "Hiérarchie complète des entités récupérée avec succès",
            "data": {
                "hierarchy": result["hierarchy"],
                "hierarchy_by_type": result["hierarchy_by_type"],
                "count": result["count"],
                "types_count": result["types_count"]
            }
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération de la hiérarchie des entités")

@entity_router.get("/types",
    summary="Types d'entités disponibles",
    description="Récupère la liste des types d'entités disponibles"
)
async def get_entity_types() -> Dict[str, Any]:
    """Types d'entités disponibles"""
    try:
        # Types d'entités fixes basés sur votre structure SENELEC
        entity_types = [
            {
                "type": "COMPANY",
                "description": "Société (SENELEC)",
                "example": "SENELEC"
            },
            {
                "type": "REGION", 
                "description": "Direction Régionale",
                "example": "DRD, DRT, DRN, DRS, DRC, DRE"
            },
            {
                "type": "CENTER",
                "description": "Centre d'exploitation",
                "example": "DRD_CENTRE, DRT_THIES"
            },
            {
                "type": "DEPARTMENT",
                "description": "Département technique",
                "example": "DEPT_PRODUCTION, DEPT_TRANSPORT"
            },
            {
                "type": "SUBSTATION",
                "description": "Poste électrique",
                "example": "POSTE_CAP_VERT, POSTE_HANN"
            },
            {
                "type": "PARTNER",
                "description": "Partenaire (OMVS, OMVG)",
                "example": "OMVS, OMVG"
            },
            {
                "type": "UNIT",
                "description": "Unité opérationnelle",
                "example": "Unités spécialisées"
            }
        ]
        
        return {
            "status": "success",
            "message": "Types d'entités récupérés avec succès",
            "data": {
                "entity_types": entity_types,
                "count": len(entity_types)
            }
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur types entités: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des types d'entités")

@entity_router.get("/search",
    summary="Recherche d'entités",
    description="Recherche dans les entités par code ou description"
)
async def search_entities(
    q: str = Query(..., min_length=2, description="Terme de recherche"),
    limit: int = Query(20, ge=10, le=50, description="Nombre d'éléments")
) -> Dict[str, Any]:
    """Recherche d'entités"""
    try:
        # Cette fonctionnalité nécessiterait une fonction dédiée dans le service
        # Pour l'instant, on retourne un message
        return {
            "status": "info",
            "message": "Fonctionnalité de recherche à implémenter",
            "data": {
                "query": q, 
                "limit": limit,
                "suggestion": "Utilisez les endpoints /type/{entity_type} pour filtrer par type"
            }
        }
    except Exception as e:
        logger.error(f"❌ Erreur recherche: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la recherche")