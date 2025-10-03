
import logging

from fastapi import APIRouter

from app.services.equipment_service import get_all_equipment_web


logger = logging.getLogger(__name__)

# Routeur simplifié pour mobile
equipment_router_web = APIRouter(
    prefix="/equipments",
    tags=["Équipements GMAO - Web API"],
)

@equipment_router_web.get("",
    summary="Liste des équipements (web)",
    description="Récupère tous les équipements avec leurs attributs pour l'interface web",
)
async def get_equipments():
    """Récupère tous les équipements pour l'interface web"""
    try:
        # Appeler la fonction service
        result = get_all_equipment_web()
        
        # Retourner directement le résultat
        return {
            "success": True,
            "data": result["equipments"],
            "count": result["count"],
            "message": "Équipements récupérés avec succès"
        }
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des équipements: {e}")
        return {
            "success": False,
            "data": [],
            "count": 0,
            "message": f"Erreur: {str(e)}"
        }