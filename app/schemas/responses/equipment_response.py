from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional


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