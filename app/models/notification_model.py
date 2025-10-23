from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class NotificationModel(BaseModel):
    """Modèle de notification pour WebSocket"""
    id: Optional[int] = None
    user_id: str = Field(..., description="ID de l'utilisateur destinataire (ou 'all' pour broadcast)")
    title: str = Field(..., description="Titre de la notification")
    message: str = Field(..., description="Contenu de la notification")
    type: str = Field(default="info", description="Type de notification: info, success, warning, error")
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())
    is_read: bool = Field(default=False)
    broadcast: bool = Field(default=False, description="True si notification pour tous, False si personnelle")  # ✅ AJOUT
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": 1,
                "user_id": "2",
                "title": "Nouvel équipement",
                "message": "Un équipement a été créé",
                "type": "success",
                "timestamp": "2023-10-21T12:00:00Z",
                "is_read": False,
                "broadcast": False
            }
        }