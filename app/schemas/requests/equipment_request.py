from pydantic import BaseModel, Field
from typing import List, Optional, Any

class EquipmentAttribute(BaseModel):
    name: str
    value: Any
    type: str

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