import logging
from typing import Any, Dict

from fastapi import APIRouter, HTTPException
import pymssql

from app.services.entity_service import get_all_entities

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
entity_router_web  = APIRouter(
    prefix="/entity",
    tags=["Entité - Web API"],
)

@entity_router_web .get("",
    summary="Liste des entités",
    description="Récupère la liste des entités entières sans filtre pour mobile"
)
async def get_all_entity_web() -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    try:
        result = get_all_entities()

        return {
            "status": "success",
            "message": "Entités récupérées avec succès",
            "data": result['entities']
        }
    except pymssql.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des entités")