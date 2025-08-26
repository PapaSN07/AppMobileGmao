from pydantic import BaseModel, Field
from typing import List

from app.models.models import AttributeValuesModel


class AttributeResponse(BaseModel):
    """Réponse pour les attributs d'équipement"""
    attr: List[AttributeValuesModel] = Field(..., description="Liste des valeurs d'un attribut")
    status: str = Field(..., description="Statut de la réponse")
    message: str = Field(..., description="Message de la réponse")

    class Config:
        from_attributes = True