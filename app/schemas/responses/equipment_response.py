from pydantic import BaseModel, Field
from typing import Any, Dict, List


class AttributeResponse(BaseModel):
    """Réponse pour les attributs d'équipement"""
    attr: List[Dict[str, Any]] = Field(..., description="Liste des attributs")
    status: str = Field(..., description="Statut de la réponse")
    message: str = Field(..., description="Message de la réponse")

    class Config:
        from_attributes = True