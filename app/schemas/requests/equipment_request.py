from click import command
from pydantic import BaseModel, Field
from typing import List, Optional, Any, Dict

class EquipmentAttribute(BaseModel):
    id: Optional[str] = Field(None, description="ID de l'attribut (optionnel, utilisé pour les mises à jour)")
    specification: Optional[str] = Field(None, description="Spécification / cwsp_code de l'attribut")
    index: Optional[str] = Field(None, description="Index de l'attribut")
    name: Optional[str] = Field(None, description="Nom de l'attribut")
    value: Optional[str] = Field(None, description="Valeur de l'attribut")
    type: Optional[str] = Field(None, description="Type de l'attribut")

    class Config:
        json_schema_extra = {
            "example": {
                'id': "attr_001",
                "specification": "4",
                "index": "1",
                "name": "Tension",
                "value": "230V",
                "type": "string"
            }
        }

class AddEquipmentRequest(BaseModel):
    code: str = Field(..., description="Code unique de l'équipement")
    description: Optional[str] = Field(None, description="Description")
    famille: str = Field(..., description="Famille / catégorie (ereq_category)")
    zone: str = Field(..., description="Zone")
    entity: str = Field(..., description="Entité")
    unite: Optional[str] = Field(None, description="Unité / fonction")
    centre_charge: Optional[str] = Field(None, description="Centre de charge (snake_case); sera mappé vers centreCharge côté service")
    longitude: Optional[str] = Field(None, description="Longitude")
    latitude: Optional[str] = Field(None, description="Latitude")
    feeder: Optional[str] = Field(None, description="Feeder code")
    feeder_description: Optional[str] = Field(None, description="Description du feeder")
    code_parent: Optional[str] = Field(None, description="Code de l'équipement parent")
    created_by: Optional[str] = Field(None, description="Utilisateur créant l'équipement")
    attributs: Optional[List[EquipmentAttribute]] = Field(None, description="Valeurs d'attributs optionnelles")

class UpdateEquipmentRequest(BaseModel):
    """Schéma pour la modification d'un équipement"""
    famille: Optional[str] = Field(None, description="Famille de l'équipement")
    unite: Optional[str] = Field(None, description="Unité")
    centreCharge: Optional[str] = Field(None, description="Centre de charge")  # Note: camelCase depuis frontend
    zone: Optional[str] = Field(None, description="Zone")
    entity: Optional[str] = Field(None, description="Entité")
    feeder: Optional[str] = Field(None, description="Feeder")
    feederDescription: Optional[str] = Field(None, description="Description du feeder")
    localisation: Optional[str] = Field(None, description="Localisation")
    codeParent: Optional[str] = Field(None, description="Code parent")
    code: Optional[str] = Field(None, description="Code de l'équipement")
    description: Optional[str] = Field(None, description="Description")
    created_at: Optional[str] = Field(None, description="Date de création (ISO)")
    updated_at: Optional[str] = Field(None, description="Date de mise à jour (ISO)")
    created_by: Optional[str] = Field(None, description="Créé par")
    judged_by: Optional[str] = Field(None, description="Juré par")
    is_update: Optional[bool] = Field(None, description="Est une mise à jour")
    is_new: Optional[bool] = Field(None, description="Est nouveau")
    is_approved: Optional[bool] = Field(None, description="Est approuvé")
    is_rejected: Optional[bool] = Field(None, description="Est rejeté")
    attributes: Optional[List[Dict[str, Any]]] = Field(None, description="Liste des attributs")
    commentaire: Optional[str] = Field(None, description="Commentaire sur l'équipement")

class ArchiveEquipmentRequest(BaseModel):
    equipment_ids: List[str] = Field(..., description="Liste des IDs des équipements à archiver")