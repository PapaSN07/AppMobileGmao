"""
Router pour les Ordres de Travail (OT) - API Mobile
Intégration avec l'API Coswin OT
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
import logging

from app.services.ot_service import ot_service
from app.schemas.rest_response import RestResponse

logger = logging.getLogger(__name__)

ot_router = APIRouter(
    prefix="/ot",
    tags=["Ordres de Travail - Mobile API"],
)


# ========== WORKORDERS ==========

@ot_router.get(
    "/workorders",
    summary="Liste tous les ordres de travail",
    description="Récupère tous les ordres de travail depuis l'API Coswin",
    response_model=RestResponse
)
async def get_all_workorders(
    limit: Optional[int] = Query(None, description="Nombre maximum de résultats"),
    offset: Optional[int] = Query(None, description="Offset pour la pagination"),
    status: Optional[str] = Query(None, description="Filtrer par statut (ex: OPEN, CLOSED)")
):
    """
    Récupère la liste de tous les ordres de travail
    
    **Paramètres:**
    - limit: Nombre maximum de résultats à retourner
    - offset: Offset pour la pagination
    - status: Filtrer par statut de l'ordre de travail
    
    **Retour:**
    - Liste des ordres de travail avec leurs détails
    """
    try:
        workorders = await ot_service.get_all_workorders(
            limit=limit,
            offset=offset,
            status=status
        )
        
        return RestResponse(
            success=True,
            data=workorders,
            message=f"{len(workorders)} ordres de travail récupérés"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des ordres de travail: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des ordres de travail: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}",
    summary="Détails d'un ordre de travail",
    description="Récupère les détails d'un ordre de travail par son code",
    response_model=RestResponse
)
async def get_workorder_by_code(code: str):
    """
    Récupère les détails complets d'un ordre de travail
    
    **Paramètres:**
    - code: Code de l'ordre de travail (ex: '2025248525')
    
    **Retour:**
    - Détails complets de l'ordre de travail incluant:
      - Informations générales (wowoCode, wowoUserStatus, etc.)
      - Équipement associé (wowoEquipment)
      - Description des travaux (mdjbDescription)
      - Dates (wowoAskDate, wowoPlannedStartDate, etc.)
      - Localisation (wowoLocation)
      - Priorité et statut
    """
    try:
        workorder = await ot_service.get_workorder_by_code(code)
        
        return RestResponse(
            success=True,
            data=workorder,
            message=f"Ordre de travail {code} récupéré avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération de l'ordre de travail: {str(e)}"
        )


@ot_router.post(
    "/workorders",
    summary="Créer un ordre de travail",
    description="Crée un nouvel ordre de travail dans Coswin",
    response_model=RestResponse
)
async def create_workorder(workorder_data: Dict[str, Any]):
    """
    Crée un nouvel ordre de travail
    
    **Corps de la requête:**
    - Objet JSON contenant les données de l'ordre de travail
    - Voir la documentation API Coswin pour les champs requis
    
    **Retour:**
    - Ordre de travail créé avec son code
    """
    try:
        created_workorder = await ot_service.create_workorder(workorder_data)
        
        return RestResponse(
            success=True,
            data=created_workorder,
            message="Ordre de travail créé avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la création de l'OT: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la création de l'ordre de travail: {str(e)}"
        )


@ot_router.put(
    "/workorders/{code}",
    summary="Mettre à jour un ordre de travail",
    description="Met à jour un ordre de travail existant",
    response_model=RestResponse
)
async def update_workorder(code: str, workorder_data: Dict[str, Any]):
    """
    Met à jour un ordre de travail existant
    
    **Paramètres:**
    - code: Code de l'ordre de travail à mettre à jour
    
    **Corps de la requête:**
    - Objet JSON contenant les nouvelles données
    
    **Retour:**
    - Ordre de travail mis à jour
    """
    try:
        updated_workorder = await ot_service.update_workorder(code, workorder_data)
        
        return RestResponse(
            success=True,
            data=updated_workorder,
            message=f"Ordre de travail {code} mis à jour avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la mise à jour de l'ordre de travail: {str(e)}"
        )


@ot_router.delete(
    "/workorders/{code}",
    summary="Supprimer un ordre de travail",
    description="Supprime un ordre de travail",
    response_model=RestResponse
)
async def delete_workorder(code: str):
    """
    Supprime un ordre de travail
    
    **Paramètres:**
    - code: Code de l'ordre de travail à supprimer
    
    **Retour:**
    - Confirmation de suppression
    """
    try:
        result = await ot_service.delete_workorder(code)
        
        return RestResponse(
            success=True,
            data=result,
            message=f"Ordre de travail {code} supprimé avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la suppression de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la suppression de l'ordre de travail: {str(e)}"
        )


# ========== EQUIPMENT ==========

@ot_router.get(
    "/equipment",
    summary="Liste tous les équipements",
    description="Récupère tous les équipements depuis l'API Coswin",
    response_model=RestResponse
)
async def get_all_equipment():
    """Récupère la liste de tous les équipements"""
    try:
        equipment = await ot_service.get_all_equipment()
        
        return RestResponse(
            success=True,
            data=equipment,
            message=f"{len(equipment)} équipements récupérés"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des équipements: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des équipements: {str(e)}"
        )


@ot_router.get(
    "/equipment/{code}",
    summary="Détails d'un équipement",
    description="Récupère les détails d'un équipement par son code",
    response_model=RestResponse
)
async def get_equipment_by_code(code: str):
    """Récupère les détails d'un équipement"""
    try:
        equipment = await ot_service.get_equipment_by_code(code)
        
        return RestResponse(
            success=True,
            data=equipment,
            message=f"Équipement {code} récupéré avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération de l'équipement {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération de l'équipement: {str(e)}"
        )


# ========== LOCATIONS ==========

@ot_router.get(
    "/locations",
    summary="Liste tous les emplacements",
    description="Récupère tous les emplacements depuis l'API Coswin",
    response_model=RestResponse
)
async def get_all_locations():
    """Récupère la liste de tous les emplacements"""
    try:
        locations = await ot_service.get_all_locations()
        
        return RestResponse(
            success=True,
            data=locations,
            message=f"{len(locations)} emplacements récupérés"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des emplacements: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des emplacements: {str(e)}"
        )


@ot_router.get(
    "/locations/{code}",
    summary="Détails d'un emplacement",
    description="Récupère les détails d'un emplacement par son code",
    response_model=RestResponse
)
async def get_location_by_code(code: str):
    """Récupère les détails d'un emplacement"""
    try:
        location = await ot_service.get_location_by_code(code)
        
        return RestResponse(
            success=True,
            data=location,
            message=f"Emplacement {code} récupéré avec succès"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération de l'emplacement {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération de l'emplacement: {str(e)}"
        )


# ========== OPERATIONS ==========

@ot_router.get(
    "/workorders/{code}/operations",
    summary="Opérations d'un ordre de travail",
    description="Récupère les opérations associées à un ordre de travail",
    response_model=RestResponse
)
async def get_operations_by_workorder(code: str):
    """Récupère les opérations d'un ordre de travail"""
    try:
        operations = await ot_service.get_operations_by_workorder(code)
        
        return RestResponse(
            success=True,
            data=operations,
            message=f"{len(operations)} opérations récupérées pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des opérations de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des opérations: {str(e)}"
        )


# ========== PARTS (Pièces de rechange) ==========

@ot_router.get(
    "/workorders/{code}/parts",
    summary="Pièces de rechange d'un ordre de travail",
    description="Récupère les pièces de rechange associées à un ordre de travail",
    response_model=RestResponse
)
async def get_parts_by_workorder(code: str):
    """Récupère les pièces de rechange d'un ordre de travail"""
    try:
        parts = await ot_service.get_parts_by_workorder(code)
        
        return RestResponse(
            success=True,
            data=parts,
            message=f"{len(parts)} pièces récupérées pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des pièces de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des pièces: {str(e)}"
        )


# ========== DOCUMENTS ==========

@ot_router.get(
    "/workorders/{code}/documents",
    summary="Documents d'un ordre de travail",
    description="Récupère les documents associés à un ordre de travail",
    response_model=RestResponse
)
async def get_documents_by_workorder(code: str):
    """Récupère les documents d'un ordre de travail"""
    try:
        documents = await ot_service.get_documents_by_workorder(code)
        
        return RestResponse(
            success=True,
            data=documents,
            message=f"{len(documents)} documents récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des documents de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des documents: {str(e)}"
        )


# ========== WORKFORCE ==========

@ot_router.get(
    "/workorders/{code}/workforce",
    summary="Main d'œuvre d'un ordre de travail",
    description="Récupère la main d'œuvre affectée à un ordre de travail",
    response_model=RestResponse
)
async def get_workforce_by_workorder(code: str):
    """Récupère la main d'œuvre affectée à un ordre de travail"""
    try:
        workforce = await ot_service.get_workforce_by_workorder(code)
        
        return RestResponse(
            success=True,
            data=workforce,
            message=f"{len(workforce)} personnes affectées à l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération de la main d'œuvre de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération de la main d'œuvre: {str(e)}"
        )
