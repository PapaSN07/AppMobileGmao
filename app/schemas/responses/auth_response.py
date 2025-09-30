from pydantic import BaseModel
from typing import Any, Dict

class AuthResponse(BaseModel):
    success: bool
    data: Dict[str, Any]
    count: int
    message: str
    access_token: str
    refresh_token: str
    token_type: str = "bearer"