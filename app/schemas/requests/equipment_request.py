from pydantic import BaseModel, Field
from typing import List, Optional, Any

class EquipmentAttribute(BaseModel):
    name: str
    value: Any
    type: str
    
    class Config:
        schema_extra = {
            "example": {
                "name": "Tension",
                "value": "230V",
                "type": "string"
            }
        }

class AddEquipmentRequest(BaseModel):
    id: str
    code_parent: Optional[str] = None
    feeder: Optional[str] = None
    feeder_description: Optional[str] = None
    code: str
    famille: str
    zone: str
    entity: str
    unite: str
    centre_charge: str
    description: str
    longitude: Optional[str] = None
    latitude: Optional[str] = None
    attributs: List[EquipmentAttribute]
    cached_at: str
    is_sync: bool

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
        schema_extra = {
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