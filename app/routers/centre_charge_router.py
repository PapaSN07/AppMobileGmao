from typing import Any, Dict
from fastapi import APIRouter, Query, HTTPException
from app.schemas.rest_response import create_simple_response
from app.services.centre_charge_service import get_centre_charges
import logging
import oracledb

from app.services.entity_service import get_hierarchy

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
centre_charge_router = APIRouter(
    prefix="/centre-charge",
    tags=["Centre de Charge - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===
@centre_charge_router.get("",
    summary="Liste des centres de charge",
    description="Récupère la liste des centres de charge pour mobile"
)
async def get_centre_charge_mobile(
    entity: str = Query(..., description="Entité obligatoire (hiérarchie automatique)")
) -> Dict[str, Any]:
    """Liste des centres de charge pour mobile"""
    try:
        # Récupérer la hiérarchie dans la fonction
        hierarchy_result = get_hierarchy(entity)
        result = get_centre_charges(entity=entity, hierarchy_result=hierarchy_result)
        
        return {
            "status": "success",
            "message": "Centres de charge récupérés avec succès",
            "data": {
                "centre_charges": result["centre_charges"],
                "pagination": {
                    "count": result["count"],
                    "total_available": result.get("total_available", result["count"])
                }
            }
        }
        
    except oracledb.DatabaseError as e:
        logger.error(f"❌ Erreur base de données: {e}")
        raise HTTPException(status_code=500, detail="Erreur base de données")
    except Exception as e:
        logger.error(f"❌ Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des centres de charge")