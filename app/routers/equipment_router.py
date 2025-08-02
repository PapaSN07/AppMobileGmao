from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import logging

from app.services.equipment_service import (
    get_equipments_infinite,
    get_equipment_by_id,
    get_feeders
)

logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
equipment_router = APIRouter(
    prefix="/equipments",
    tags=["Équipements GMAO - Mobile API"],
)

# === ENDPOINTS CORE POUR MOBILE ===

@equipment_router.get("/", 
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
        
        return {
            "status": "success",
            "message": f"Équipements récupérés avec succès pour l'entité {entity}",
            "data": result
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")

@equipment_router.get("/{equipment_id}",
    summary="Récupérer un équipement par ID",
    description="Récupère les détails complets d'un équipement spécifique"
)
async def get_equipment_detail(equipment_id: str) -> Dict[str, Any]:
    """Détails d'un équipement"""
    try:
        equipment = get_equipment_by_id(equipment_id)
        if not equipment:
            raise HTTPException(status_code=404, detail="Équipement non trouvé")
        return {"equipment": equipment}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur détail: {e}")
        raise HTTPException(status_code=500, detail="Erreur récupération équipement")

@equipment_router.get("/feeders/{famille}",
    summary="Récupérer les feeders",
    description="Récupère la liste des équipements de type feeder"
)
async def get_feeders_mobile(famille: str) -> Dict[str, Any]:
    """Liste des feeders"""
    try:
        result = get_feeders(famille)
        return {
            "status": "success",
            "message": f"Feeders récupérés pour la catégorie {famille}",
            "data": result
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération feeders: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur récupération feeders: {str(e)}")
    