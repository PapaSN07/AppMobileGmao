import logging

from fastapi import APIRouter

from app.services.equipment_service import archive_equipments, get_all_equipment_web, update_equipment_existing
from app.schemas.requests.equipment_request import ArchiveEquipmentRequest, UpdateEquipmentRequest 
from app.schemas.responses.equipment_response import ArchiveEquipmentResponse, UpdateEquipmentResponse


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

@equipment_router_web.patch("/{equipment_id}",
    summary="Mettre à jour un équipement (PATCH)",
    description="Met à jour un équipement existant dans la DB temporaire, seulement les champs changés",
)
async def update_equipment(equipment_id: str, request: UpdateEquipmentRequest):
    """Met à jour un équipement existant avec PATCH"""
    try:
        success, message = update_equipment_existing(equipment_id, request.model_dump(exclude_unset=True))
        
        if success:
            return UpdateEquipmentResponse(
                success=True,
                message=message or "Équipement mis à jour avec succès",
                data={"id": equipment_id},  # Retourner l'ID de l'équipement mis à jour
                error_code=None
            )
        else:
            return UpdateEquipmentResponse(
                success=False,
                message=message or "Échec de la mise à jour de l'équipement",
                error_code="UPDATE_FAILED",
                data=None
            )
    except Exception as e:
        logger.error(f"❌ Erreur dans PATCH update_equipment: {e}")
        return UpdateEquipmentResponse(
            success=False,
            message=f"Erreur interne: {str(e)}",
            error_code="INTERNAL_ERROR",
            data=None
        )

@equipment_router_web.post("/archive",
    summary="Archiver des équipements",
    description="Archive les équipements spécifiés de la DB temporaire vers l'historique",
)
async def archive_equipments_endpoint(request: ArchiveEquipmentRequest):
    """Archive les équipements spécifiés"""
    try:
        success, message, archived_count, failed_ids = archive_equipments(
            request.equipment_ids
        )
        
        if success:
            return ArchiveEquipmentResponse(
                success=True,
                message=message,
                archived_count=archived_count,
                failed_ids=failed_ids if failed_ids else None,
                error_code=None
            )
        else:
            return ArchiveEquipmentResponse(
                success=False,
                message=message,
                archived_count=archived_count,
                error_code="ARCHIVE_FAILED",
                failed_ids=failed_ids if failed_ids else None
            )
    except Exception as e:
        logger.error(f"❌ Erreur dans archive_equipments_endpoint: {e}")
        return ArchiveEquipmentResponse(
            success=False,
            message=f"Erreur interne: {str(e)}",
            archived_count=0,
            error_code="INTERNAL_ERROR",
            failed_ids=None
        )