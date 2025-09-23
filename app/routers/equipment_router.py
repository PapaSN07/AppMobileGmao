from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import logging

from pydantic import ValidationError

from app.models.models import EquipmentModel
from app.schemas.responses.equipment_response import AttributeResponse, AttributeValueResponse
from app.services.equipment_service import (
    get_attribute_values,
    get_equipment_attributes_by_code_without_value,
    get_equipment_by_id,
    get_equipments_infinite,
    get_feeders,
    insert_equipment,
    update_equipment_partial
)
from app.services.centre_charge_service import get_centre_charges
from app.services.entity_service import get_entities
from app.services.famille_service import get_familles
from app.services.unite_service import get_unites
from app.services.zone_service import get_zones
from app.schemas.requests.equipment_request import AddEquipmentRequest, UpdateEquipmentRequest

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

@equipment_router.post("",
    summary="Ajouter un équipement",
    description="Ajoute un nouvel équipement dans la base"
)
async def add_equipment_mobile(request: AddEquipmentRequest) -> Dict[str, Any]:
    """Ajout d'un équipement via insert_equipment"""
    try:
        data = request.model_dump(exclude_none=True)
        
        # Simplifier la conversion des attributs
        attributes_converted = []
        if data.get('attributs'):
            for attr in data['attributs']:
                # Garder seulement les champs essentiels pour l'insertion
                attr_dict = {
                    'id': attr.get('id', ''),
                    'specification': attr.get('specification', ''),
                    'index': attr.get('index', ''),
                    'name': attr.get('name'),
                    'value': str(attr.get('value', '')) if attr.get('value') is not None else '',
                    'type': attr.get('type', 'string')
                }
                attributes_converted.append(attr_dict)

        # Mapper les champs du DTO vers les attributs attendus par EquipmentModel
        equipment = EquipmentModel(
            id = "", 
            code = data.get('code', ''),
            description = data.get('description', ''),
            codeParent = data.get('code_parent', ''),
            famille = data.get('famille', ''),
            zone = data.get('zone', ''),
            entity = data.get('entity', ''),
            unite = data.get('unite', ''),
            # service insert_equipment attend centreCharge (camelCase) — on mappe depuis centre_charge
            centreCharge = data.get('centre_charge', ''),
            longitude = data.get('longitude', ''),
            latitude = data.get('latitude', ''),
            feeder = data.get('feeder', ''),
            feederDescription = data.get('feeder', ''),
            # conserver les attributs fournis (optionnel) — insert_equipment crée les lignes attribute templates,
            # si tu veux des valeurs réelles, tu devras enrichir insert_equipment pour accepter 'attributs'
            attributes = attributes_converted
        )

        success, equipment_id = insert_equipment(equipment)
        if success:
            return {
                "status": "success",
                "message": "Équipement ajouté avec succès",
                "equipment_id": str(equipment_id),
                "attributes_count": len(attributes_converted)
            }
        else:
            raise HTTPException(status_code=500, detail="Erreur lors de l'ajout de l'équipement")
    except ValidationError as e:
        logger.error(f"❌ Erreur validation Pydantic: {e}")
        raise HTTPException(status_code=422, detail=f"Données invalides: {e}")
    except Exception as e:
        logger.error(f"❌ Erreur ajout équipement: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur ajout équipement: {str(e)}")

@equipment_router.patch("/{equipment_id}",
    summary="Modifier partiellement un équipement", 
    description="Modifie seulement les champs spécifiés d'un équipement et ses attributs"
)
async def update_equipment_partial_endpoint(
    equipment_id: str, 
    request: UpdateEquipmentRequest
) -> Dict[str, Any]:
    """Modification partielle d'un équipement avec ses attributs"""
    
    try:
        # Convertir la request en dictionnaire, en excluant les valeurs None
        updates = request.model_dump(exclude_none=True)
        
        if not updates:
            raise HTTPException(status_code=400, detail="Aucun champ à mettre à jour fourni")
        
        # Effectuer la mise à jour
        success = update_equipment_partial(equipment_id, updates)
        
        if success:
            # Récupérer l'équipement mis à jour pour la réponse
            updated_equipment = get_equipment_by_id(equipment_id)
            
            return {
                "status": "success", 
                "message": f"Équipement modifié avec succès ({len(updates)} champs)",
                "method": "PATCH",
                "updated_fields": list(updates.keys()),
                "equipment": updated_equipment.to_api_response() if updated_equipment else None
            }
        else:
            raise HTTPException(status_code=500, detail="Erreur lors de la modification")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur PATCH équipement: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur PATCH: {str(e)}")

@equipment_router.get("/values/{entity}",
    summary="Récupérer les valeurs des équipements",
    description="Récupère les valeurs des équipements pour l'entité spécifiée"
)
async def get_equipment_values(entity: str) -> Dict[str, Any]:
    """Récupération des valeurs des équipements"""
    
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    try:
        hierarchy_result = get_hierarchy(entity)
        cost_charges_result = get_centre_charges(entity, hierarchy_result)
        entities_result = get_entities(entity, hierarchy_result)
        familles_result = get_familles(entity, hierarchy_result)
        unites_result = get_unites(entity, hierarchy_result)
        zones_result = get_zones(entity, hierarchy_result)
        feeder_result = get_feeders(entity, hierarchy_result)

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

@equipment_router.get("/attributes",
    summary="Récupérer les attributs d'un équipement",
    description="Récupère la liste des attributs d'un équipement spécifique",
    response_model=AttributeResponse
)
async def get_equipment_attribute_values(
    specification: str = Query(..., description="Code de la spécification"),
    attribute_index: str = Query(..., description="Index de l'attribut")
    ) -> AttributeValueResponse:
    """Récupération des attributs d'un équipement"""
    try:
        attributes = get_attribute_values(specification, attribute_index)

        if not attributes:
            raise HTTPException(status_code=404, detail="Aucun attribut trouvé pour cet équipement")
        
        return AttributeValueResponse(
            attr=attributes,
            status="success",
            message="Attributs + Valeurs récupérés avec succès"
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs: {e}")
        raise HTTPException(status_code=500, detail="Erreur récupération attributs")

@equipment_router.get("/attributes/by-code",
    summary="Récupérer les attributs d'un équipement par son code de la famille",
    description="Récupère la liste des attributs d'un équipement spécifique par son code équipement qui est donnée par le code dans famille",
    response_model=AttributeResponse
)
async def get_equipment_attribute_values_by_code(
    codeFamille: str = Query(..., description="Code de l'équipement")
    ) -> AttributeResponse:
    """Récupération des attributs d'un équipement"""
    try:
        attributes = get_equipment_attributes_by_code_without_value(codeFamille)
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