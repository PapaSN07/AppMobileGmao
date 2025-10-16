from pydantic import BaseModel
from typing import Any, Dict, Optional

class AuthResponse(BaseModel):
    success: bool
    data: Dict[str, Any]
    count: int
    message: str
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    error_code: Optional[str] = None  # Nouveau champ pour les erreurs (si utilisé dans les réponses de succès/échec)