from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class AttributeValue(BaseModel):
    """Modèle Pydantic pour les valeurs d'attributs"""
    id: Optional[str] = Field(None, description="ID de la valeur d'attribut")
    specification: Optional[str] = Field(None, description="Code de spécification")
    attribute_index: Optional[str] = Field(None, description="Index de l'attribut")
    value: Optional[str] = Field(None, description="Valeur de l'attribut")

    class Config:
        from_attributes = True


class EquipmentAttribute(BaseModel):
    """Modèle Pydantic pour les attributs d'équipement"""
    id: Optional[str] = Field(None, description="ID de l'attribut")
    specification: Optional[str] = Field(None, description="Code de spécification")
    index: Optional[str] = Field(None, description="Index de l'attribut")
    name: Optional[str] = Field(None, description="Nom de l'attribut")
    value: Optional[str] = Field(None, description="Valeur de l'attribut")
    type: Optional[str] = Field("string", description="Type de l'attribut")

    class Config:
        from_attributes = True


class AttributeValueResponse(BaseModel):
    """Réponse pour les attributs avec leurs valeurs d'équipement"""
    attr: List[Dict[str, Any]] = Field(..., description="Liste des valeurs d'un attribut")
    status: str = Field(..., description="Statut de la réponse")
    message: str = Field(..., description="Message de la réponse")

    class Config:
        from_attributes = True


class AttributeResponse(BaseModel):
    """Réponse pour les attributs d'équipement"""
    attr: List[Dict[str, Any]] = Field(..., description="Liste des attributs")
    status: str = Field(..., description="Statut de la réponse")
    message: str = Field(..., description="Message de la réponse")

    class Config:
        from_attributes = True


# ✅ NOUVEAU: Modèles de réponse pour l'équipement complet
class EquipmentResponse(BaseModel):
    """Réponse pour un équipement complet"""
    id: Optional[str] = Field(None, description="ID de l'équipement")
    code: Optional[str] = Field(None, description="Code de l'équipement")
    codeParent: Optional[str] = Field(None, description="Code parent")
    description: Optional[str] = Field(None, description="Description")
    famille: Optional[str] = Field(None, description="Famille d'équipement")
    zone: Optional[str] = Field(None, description="Zone")
    entity: Optional[str] = Field(None, description="Entité")
    unite: Optional[str] = Field(None, description="Unité")
    centreCharge: Optional[str] = Field(None, description="Centre de charge")
    longitude: Optional[str] = Field(None, description="Longitude")
    latitude: Optional[str] = Field(None, description="Latitude")
    feeder: Optional[str] = Field(None, description="Feeder")
    feederDescription: Optional[str] = Field(None, description="Description du feeder")
    attributes: List[Dict[str, Any]] = Field(default_factory=list, description="Attributs de l'équipement")

    class Config:
        from_attributes = True


class EquipmentListResponse(BaseModel):
    """Réponse pour une liste d'équipements"""
    equipments: List[Dict[str, Any]] = Field(..., description="Liste des équipements")
    count: int = Field(..., description="Nombre d'équipements")
    entity_hierarchy: Optional[Dict[str, Any]] = Field(None, description="Hiérarchie d'entité utilisée")
    status: str = Field("success", description="Statut de la réponse")
    message: str = Field("", description="Message de la réponse")

    class Config:
        from_attributes = True


class UpdateEquipmentResponse(BaseModel):
    """Réponse pour la mise à jour d'un équipement"""
    success: bool = Field(..., description="Indique si la mise à jour a réussi")
    message: str = Field(..., description="Message de la réponse")
    data: Optional[Dict[str, Any]] = Field(None, description="Données de l'équipement mis à jour (via to_dict_SDDV())")
    error_code: Optional[str] = Field(None, description="Code d'erreur si échec (ex. 'EQUIPMENT_NOT_FOUND')")

    class Config:
        from_attributes = True

class ArchiveEquipmentResponse(BaseModel):
    success: bool = Field(..., description="Indique si l'archivage a réussi")
    message: str = Field(..., description="Message de la réponse")
    archived_count: int = Field(..., description="Nombre d'équipements archivés")
    error_code: Optional[str] = Field(None, description="Code d'erreur si échec")
    failed_ids: Optional[List[str]] = Field(None, description="Liste des IDs qui ont échoué (si partiellement réussi)")
    
class AllEquipmentHistoriesResponse(BaseModel):
    """Réponse pour la liste de tous les historiques d'équipements"""
    data: List[Dict[str, Any]] = Field(..., description="Liste de tous les historiques avec attributs")
    count: int = Field(..., description="Nombre total d'historiques")
    status: str = Field("success", description="Statut de la réponse")
    message: str = Field("", description="Message de la réponse")

    class Config:
        from_attributes = True


class EquipmentHistoryAttribute(BaseModel):
    """Attribut d'un équipement historisé"""
    id: Optional[str] = None
    specification: Optional[str] = None
    famille: Optional[str] = None
    indx: Optional[int] = Field(None, alias='index')
    attribute_name: Optional[str] = Field(None, alias='name')
    value: Optional[str] = None
    code: Optional[str] = None
    description: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    is_copy_ot: Optional[bool] = False
    
    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "id": "123",
                "specification": "TRANSFO-SPEC-001",
                "famille": "TRANSFORMATEURS",
                "index": 1,
                "name": "Puissance",
                "value": "630 kVA",
                "code": "TRANSFO-001",
                "description": "Puissance nominale du transformateur",
                "is_copy_ot": False
            }
        }

class EquipmentHistoryItem(BaseModel):
    """Un équipement dans l'historique (archivé ou en cours)"""
    id: str
    code: str
    famille: Optional[str] = None
    zone: Optional[str] = None
    entity: Optional[str] = None
    unite: Optional[str] = None
    centre_charge: Optional[str] = None
    description: Optional[str] = None
    feeder: Optional[str] = None
    feeder_description: Optional[str] = None
    localisation: Optional[str] = None
    code_parent: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    created_by: Optional[str] = None
    judged_by: Optional[str] = None
    is_update: Optional[bool] = False
    is_new: Optional[bool] = False
    is_approved: Optional[bool] = False
    is_rejected: Optional[bool] = False
    is_deleted: Optional[bool] = False
    commentaire: Optional[str] = None
    status: str = Field(..., description="Status: 'archived' ou 'in_progress'")
    attributes: List[EquipmentHistoryAttribute] = []
    
    # Champs spécifiques aux historiques archivés
    equipment_id: Optional[str] = None
    date_history_created_at: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": "456",
                "code": "TRANSFO-001",
                "famille": "TRANSFORMATEURS",
                "zone": "ZONE1",
                "entity": "HCAU",
                "description": "Transformateur 630 kVA",
                "created_by": "nafissatou.diack",
                "status": "archived",
                "attributes": [
                    {
                        "name": "Puissance",
                        "value": "630 kVA"
                    }
                ],
                "date_history_created_at": "2025-10-27T10:00:00Z"
            }
        }

class PrestataireHistoryResponse(BaseModel):
    """Réponse contenant tous les historiques d'un prestataire"""
    success: bool
    message: str
    data: List[EquipmentHistoryItem]
    count: int
    prestataire: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "45 historiques récupérés pour le prestataire nafissatou.diack",
                "data": [
                    {
                        "id": "456",
                        "code": "TRANSFO-001",
                        "status": "archived",
                        "created_by": "nafissatou.diack",
                        "date_history_created_at": "2025-10-27T10:00:00Z"
                    },
                    {
                        "id": "123",
                        "code": "TRANSFO-002",
                        "status": "in_progress",
                        "created_by": "nafissatou.diack",
                        "created_at": "2025-10-28T14:30:00Z"
                    }
                ],
                "count": 45,
                "prestataire": "nafissatou.diack"
            }
        }