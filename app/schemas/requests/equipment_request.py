from pydantic import BaseModel, Field
from typing import List, Optional, Any

class EquipmentAttribute(BaseModel):
    id: str
    specification: str
    index: str
    name: str
    value: Any
    type: str
    
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
    attributs: Optional[List[EquipmentAttribute]] = Field(None, description="Valeurs d'attributs optionnelles")

class UpdateEquipmentRequest(BaseModel):
    """Schéma pour la modification d'un équipement"""
    code_parent: Optional[str] = None
    feeder: Optional[str] = None
    feeder_description: Optional[str] = None
    code: Optional[str] = None
    famille: Optional[str] = None
    zone: Optional[str] = None
    entity: Optional[str] = None
    unite: Optional[str] = None
    centre_charge: Optional[str] = None
    description: Optional[str] = None
    longitude: Optional[str] = None
    latitude: Optional[str] = None
    attributs: Optional[List[EquipmentAttribute]] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "description": "Nouvelle description de l'équipement",
                "zone": "Z2",
                "attributs": [
                    {
                        "name": "Tension",
                        "value": "230V",
                        "type": "string"
                    },
                    {
                        "name": "Puissance",
                        "value": "100",
                        "type": "number"
                    }
                ]
            }
        }