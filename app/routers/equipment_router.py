from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import logging

from app.services.equipment_service import (
    get_equipments_infinite,
    get_zones,
    get_familles,
    get_entities,
    get_equipment_by_id,
    get_equipment_stats,
    refresh_reference_data
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
    limit: int = Query(20, ge=10, le=50, description="Nombre d'éléments (10-50)"),
    cursor: Optional[str] = Query(None, description="Curseur de pagination"),
    zone: Optional[str] = Query(None, description="Filtre zone"),
    famille: Optional[str] = Query(None, description="Filtre famille"),
    search: Optional[str] = Query(None, description="Recherche textuelle")
) -> Dict[str, Any]:
    """Endpoint principal optimisé pour mobile avec infinite scroll et hiérarchie"""
    try:
        result = get_equipments_infinite(
            entity=entity,
            cursor=cursor,
            limit=limit,
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

# === DONNÉES DE RÉFÉRENCE ===

@equipment_router.get("/reference/sync")
async def sync_reference_data() -> Dict[str, Any]:
    """Synchronisation des données de référence pour mobile"""
    try:
        zones = get_zones()
        familles = get_familles()
        entities = get_entities()
        stats = get_equipment_stats()
        
        return {
            "zones": zones["zones"],
            "familles": familles["familles"], 
            "entities": entities["entities"],
            "stats": {
                "total_equipments": stats["total_count"],
                "last_updated": stats["last_updated"]
            },
            "cache_version": "1.0"
        }
    except Exception as e:
        logger.error(f"❌ Erreur sync: {e}")
        raise HTTPException(status_code=500, detail="Erreur synchronisation")

# === ADMINISTRATION MINIMALE ===

@equipment_router.post("/admin/refresh")
async def refresh_data() -> Dict[str, Any]:
    """Rafraîchissement des données"""
    try:
        result = refresh_reference_data()
        return {"status": "success", "message": "Données rafraîchies"}
    except Exception as e:
        logger.error(f"❌ Erreur refresh: {e}")
        raise HTTPException(status_code=500, detail="Erreur rafraîchissement")