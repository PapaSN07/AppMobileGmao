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
    summary="Liste les ordres de travail (filtrés, paginés)",
    description=(
        "Récupère une PAGE d'ordres de travail depuis l'API Coswin, filtrée "
        "par technicien (scope='mine') ou service (scope='service'). "
        "Retourne les OT de la page + un paginationContext pour charger la "
        "page suivante via le bouton 'Suivant' dans l'app. "
        "Les OT clôturés sont exclus par défaut."
    ),
    response_model=RestResponse
)

async def get_all_workorders(
    scope: str = Query(
        "mine",
        description="'mine' (mes OT, nécessite supervisorCode) | 'service' (nécessite requestEntity) | 'all_open' (tous)",
    ),
    supervisorCode: Optional[str] = Query(
        None, description="Code agent Coswin (wowoSupervisor) — requis si scope='mine'"
    ),
    requestEntity: Optional[str] = Query(
        None, description="Code service Coswin (wowoRequestEntity), ex: 'SDDV', 'DTAE' — requis si scope='service'"
    ),
    excludeClosed: bool = Query(
        True, description="Exclut les OT clôturés (wowoUserStatus == 'CL'). Activé par défaut."
    ),
    paginationContext: Optional[str] = Query(
        None, description="Token Coswin pour charger la page suivante (fourni par la réponse précédente)."
    ),
):
    """
    Récupère UNE PAGE d'ordres de travail filtrée.

    **Paramètres:**
    - scope='mine' + supervisorCode: "mes OT" (filtre wowoSupervisor)
    - scope='service' + requestEntity: OT d'un service (filtre wowoRequestEntity)
    - scope='all_open': tous les OT, sans filtre technicien/service
    - excludeClosed: exclut les OT au statut "CL" (clôturé), activé par défaut
    - paginationContext: token renvoyé par la page précédente pour charger la suivante

    **Retour:**
    - workorders: liste des OT de cette page
    - paginationContext: token pour la page suivante (null si fin)
    - hasMore: true s'il reste des pages disponibles
    """
    try:
        result = await ot_service.get_all_workorders(
            scope=scope,
            supervisor_code=supervisorCode,
            request_entity=requestEntity,
            exclude_closed=excludeClosed,
            pagination_context=paginationContext,
        )

        workorders = result["workorders"]
        return RestResponse(
            success=True,
            data={
                "workorders": workorders,
                "paginationContext": result["paginationContext"],
                "hasMore": result["hasMore"],
            },
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


# ========== OT TAB DATA ==========

@ot_router.get(
    "/workorders/{code}/actions",
    summary="Actions d'un ordre de travail",
    description="Récupère les actions associées à un ordre de travail",
    response_model=RestResponse,
)
async def get_actions_by_workorder(code: str):
    """Récupère les actions d'un ordre de travail."""
    try:
        actions = await ot_service.get_actions_by_workorder(code)
        return RestResponse(
            success=True,
            data=actions,
            message=f"{len(actions)} actions récupérées pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des actions de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des actions: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/allocatedemployees",
    summary="Employés alloués à un ordre de travail",
    description="Récupère la liste des employés alloués à un ordre de travail",
    response_model=RestResponse,
)
async def get_allocated_employees_by_workorder(code: str):
    """Récupère les employés alloués d'un ordre de travail."""
    try:
        employees = await ot_service.get_allocated_employees_by_workorder(code)
        return RestResponse(
            success=True,
            data=employees,
            message=f"{len(employees)} employés alloués récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des employés alloués de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des employés alloués: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/employeefeedbacks",
    summary="Commentaires employés d'un ordre de travail",
    description="Récupère les feedbacks saisis sur un ordre de travail",
    response_model=RestResponse,
)
async def get_employee_feedbacks_by_workorder(code: str):
    """Récupère les commentaires employés d'un ordre de travail."""
    try:
        feedbacks = await ot_service.get_employee_feedbacks_by_workorder(code)
        return RestResponse(
            success=True,
            data=feedbacks,
            message=f"{len(feedbacks)} commentaires récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des commentaires de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des commentaires: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/stockused",
    summary="Stock utilisé d'un ordre de travail",
    description="Récupère le stock utilisé sur un ordre de travail",
    response_model=RestResponse,
)
async def get_stock_used_by_workorder(code: str):
    """Récupère le stock utilisé sur un ordre de travail."""
    try:
        stock_used = await ot_service.get_stock_used_by_workorder(code)
        return RestResponse(
            success=True,
            data=stock_used,
            message=f"{len(stock_used)} lignes de stock récupérées pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du stock utilisé de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération du stock utilisé: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/attributes",
    summary="Attributs d'un ordre de travail",
    description="Récupère les attributs associés à un ordre de travail",
    response_model=RestResponse,
)
async def get_attributes_by_workorder(code: str):
    """Récupère les attributs d'un ordre de travail."""
    try:
        attributes = await ot_service.get_attributes_by_workorder(code)
        return RestResponse(
            success=True,
            data=attributes,
            message=f"{len(attributes)} attributs récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des attributs de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des attributs: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/facilitiesused",
    summary="Moyens utilisés d'un ordre de travail",
    description="Récupère les moyens (véhicules, outils) affectés à un ordre de travail",
    response_model=RestResponse,
)
async def get_facilities_used_by_workorder(code: str):
    """Récupère les moyens utilisés d'un ordre de travail."""
    try:
        facilities = await ot_service.get_facilities_used_by_workorder(code)
        return RestResponse(
            success=True,
            data=facilities,
            message=f"{len(facilities)} moyens récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des moyens de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des moyens: {str(e)}"
        )


@ot_router.get(
    "/workorders/{code}/services",
    summary="Services utilisés d'un ordre de travail",
    description="Récupère les services (sous-traitance, prestations) associés à un ordre de travail",
    response_model=RestResponse,
)
async def get_services_by_workorder(code: str):
    """Récupère les services utilisés d'un ordre de travail."""
    try:
        services = await ot_service.get_services_used_by_workorder(code)
        return RestResponse(
            success=True,
            data=services,
            message=f"{len(services)} services récupérés pour l'OT {code}"
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des services de l'OT {code}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de la récupération des services: {str(e)}"
        )
