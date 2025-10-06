from pydantic import BaseModel
from typing import Any, Dict, Optional, List

class AddUserResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Dict[str, Any]] = None  # Données de l'utilisateur créé (via to_dict())
    error_code: Optional[str] = None  # Code d'erreur si échec (ex. "USER_EXISTS")

class UserResponse(BaseModel):
    id: Optional[str] = None
    username: str
    email: str
    role: str
    supervisor: Optional[str] = None
    urlName: Optional[str] = None  # Correspond à url_image
    isConnected: Optional[bool] = None  # Correspond à is_connected
    isEnabled: Optional[bool] = None
    createdAt: Optional[str] = None  # Correspond à created_at (ISO format)
    updatedAt: Optional[str] = None
    address: Optional[str] = None
    company: Optional[str] = None

class GetAllUsersResponse(BaseModel):
    success: bool
    message: str
    data: List[UserResponse]  # Liste d'utilisateurs
    count: int
    error_code: Optional[str] = None

class UpdateUserResponse(BaseModel):
    success: bool
    message: str
    data: Optional[UserResponse] = None  # Utilisateur mis à jour
    error_code: Optional[str] = None

class DeleteUserResponse(BaseModel):
    success: bool
    message: str
    error_code: Optional[str] = None