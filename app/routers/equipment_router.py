from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import logging

from app.services.equipment_service import (
    get_equipments_infinite,
    get_equipment_by_id,
    get_feeders
)
from app.services.centre_charge_service import get_centre_charges
from app.services.entity_service import get_entities
from app.services.famille_service import get_familles
from app.services.unite_service import get_unites
from app.services.zone_service import get_zones

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
equipment_router = APIRouter(
    prefix="/equipments",
    tags=["Équipements GMAO - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===

@equipment_router.get("", 
    summary="Infinite scroll pour mobile avec hiérarchie",
    description="Endpoint principal pour l'infinite scroll mobile avec hiérarchie d'entité obligatoire"
)
async def get_equipments_mobile(
    entity: str = Query(..., description="Entité obligatoire (hiérarchie automatique)"),
    zone: Optional[str] = Query(None, description="Filtre zone"),
    famille: Optional[str] = Query(None, description="Filtre famille"),
    search: Optional[str] = Query(None, description="Recherche textuelle")
) -> Dict[str, Any]:
    """Endpoint principal optimisé pour mobile avec infinite scroll et hiérarchie"""
    try:
        result = get_equipments_infinite(
            entity=entity,
            zone=zone,
            famille=famille,
            search_term=search
        )
        
        return result
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")

@equipment_router.get("/{code}",
    summary="Récupérer un équipement par code",
    description="Récupère les détails complets d'un équipement spécifique"
)
async def get_equipment_detail(code: str) -> Dict[str, Any]:
    """Détails d'un équipement"""
    try:
        equipment = get_equipment_by_id(code)
        if not equipment:
            raise HTTPException(status_code=404, detail="Équipement non trouvé")
        return {"equipment": equipment}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur détail: {e}")
        raise HTTPException(status_code=500, detail="Erreur récupération équipement")

@equipment_router.get("/feeders/{entity}",
    summary="Récupérer les feeders",
    description="Récupère la liste des équipements de type feeder"
)
async def get_feeders_mobile(entity: str) -> Dict[str, Any]:
    """Liste des feeders"""
    try:
        result = get_feeders(entity)
        return {
            "status": "success",
            "message": f"Feeders récupérés pour l'entité {entity}",
            "data": result
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération feeders: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération feeders: {str(e)}")

@equipment_router.get("/values/{entity}",
    summary="Récupérer les valeurs des équipements",
    description="Récupère les valeurs des équipements pour l'entité spécifiée"
)
async def get_equipment_values(entity: str) -> Dict[str, Any]:
    """Récupération des valeurs des équipements"""
    try:
        # ✅ Correction : Suppression des await (fonctions synchrones)
        cost_charges_result = get_centre_charges(entity)
        entities_result = get_entities(entity)
        familles_result = get_familles(entity)
        unites_result = get_unites(entity)
        zones_result = get_zones(entity)
        
        return {
            "status": "success",
            "message": f"Valeurs récupérées pour l'entité {entity}",
            "data": {
                "entities": entities_result.get('entities', []),
                "unites": unites_result.get('unites', []),
                "zones": zones_result.get('zones', []),
                "familles": familles_result.get('familles', []),
                "cost_charges": cost_charges_result.get('centre_charges', [])
            }
        }
    
    except Exception as e:
        logger.error(f"❌ Erreur récupération valeurs: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération valeurs: {str(e)}")
# === FIN ENDPOINTS CORE POUR MOBILE ===