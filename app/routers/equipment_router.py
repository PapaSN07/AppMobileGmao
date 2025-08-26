from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import logging

from app.schemas.responses.equipment_response import AttributeResponse
from app.services.equipment_service import (
    get_attributes_value,
    get_equipments_infinite,
    get_feeders,
    add_equipment
)
from app.services.centre_charge_service import get_centre_charges
from app.services.entity_service import get_entities
from app.services.famille_service import get_familles
from app.services.unite_service import get_unites
from app.services.zone_service import get_zones
from app.schemas.requests.equipment_request import AddEquipmentRequest

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

@equipment_router.get("/values/{entity}",
    summary="Récupérer les valeurs des équipements",
    description="Récupère les valeurs des équipements pour l'entité spécifiée"
)
async def get_equipment_values(entity: str) -> Dict[str, Any]:
    """Récupération des valeurs des équipements"""
    try:
        cost_charges_result = get_centre_charges(entity)
        entities_result = get_entities(entity)
        familles_result = get_familles(entity)
        unites_result = get_unites(entity)
        zones_result = get_zones(entity)
        feeder_result = get_feeders(entity)

        # Vérification des résultats
        if not cost_charges_result or not entities_result or not familles_result or not unites_result or not zones_result:
            raise HTTPException(status_code=404, detail="Aucune donnée trouvée pour l'entité spécifiée")
        
        return {
            "status": "success",
            "message": f"Valeurs récupérées pour l'entité {entity}",
            "data": {
                "entities": entities_result.get('entities', []),
                "unites": unites_result.get('unites', []),
                "zones": zones_result.get('zones', []),
                "familles": familles_result.get('familles', []),
                "cost_charges": cost_charges_result.get('centre_charges', []),
                "feeders": feeder_result.get('feeders', [])
            }
        }
    
    except Exception as e:
        logger.error(f"❌ Erreur récupération valeurs: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération valeurs: {str(e)}")

@equipment_router.post("",
    summary="Ajouter un équipement",
    description="Ajoute un nouvel équipement dans la base"
)
async def add_equipment_mobile(request: AddEquipmentRequest) -> Dict[str, Any]:
    """Ajout d'un équipement"""
    try:
        success = add_equipment(request.model_dump())
        if success:
            return {
                "status": "success",
                "message": "Équipement ajouté avec succès"
            }
        else:
            raise HTTPException(status_code=500, detail="Erreur lors de l'ajout de l'équipement")
    except Exception as e:
        logger.error(f"❌ Erreur ajout équipement: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur ajout équipement: {str(e)}")

@equipment_router.get("/attributes/{code}",
    summary="Récupérer les attributs d'un équipement",
    description="Récupère la liste des attributs d'un équipement spécifique",
    response_model=AttributeResponse
)
async def get_equipment_attributes(code: str) -> AttributeResponse:
    """Récupération des attributs d'un équipement"""
    try:
        attributes = get_attributes_value(code)
        if not attributes:
            raise HTTPException(status_code=404, detail="Aucun attribut trouvé pour cet équipement")
        
        return AttributeResponse(
            attr=attributes,
            status="success",
            message="Attributs récupérés avec succès"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs: {e}")
        raise HTTPException(status_code=500, detail="Erreur récupération attributs")

# === FIN ENDPOINTS CORE POUR MOBILE ===