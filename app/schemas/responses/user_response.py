from pydantic import BaseModel
from typing import Any, Dict, Optional

class AddUserResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Dict[str, Any]] = None  # Données de l'utilisateur créé (via to_dict())
    error_code: Optional[str] = None  # Code d'erreur si échec (ex. "USER_EXISTS")