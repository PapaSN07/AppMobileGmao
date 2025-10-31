from pydantic import BaseModel, Field, EmailStr
from typing import Optional

class AddUserRequest(BaseModel):
    username: str = Field(..., description="Nom d'utilisateur unique", min_length=3, max_length=150)
    password: Optional[str] = Field(None, description="Mot de passe", min_length=6)
    email: EmailStr = Field(..., description="Adresse email unique")
    supervisor: Optional[int] = Field(None, description="ID du superviseur (optionnel)")
    address: Optional[str] = Field(None, description="Adresse de l'utilisateur", max_length=512)
    company: Optional[str] = Field(None, description="Entreprise de l'utilisateur", max_length=255)
    url_image: Optional[str] = Field(None, description="URL de l'image de profil", max_length=512)
    role: str = Field("user", description="Rôle de l'utilisateur", max_length=100)
    is_enabled: bool = Field(..., description="Utilisateur activé par défaut")

class UpdateUserRequest(BaseModel):
    username: Optional[str] = Field(None, description="Nom d'utilisateur", min_length=3, max_length=150)
    email: Optional[EmailStr] = Field(None, description="Adresse email")
    role: Optional[str] = Field(None, description="Rôle de l'utilisateur", max_length=100)
    password: Optional[str] = Field(None, description="Nouveau mot de passe", min_length=6)
    supervisor: Optional[int] = Field(None, description="ID du superviseur")
    url_image: Optional[str] = Field(None, description="URL de l'image de profil", max_length=512)
    is_connected: Optional[bool] = Field(None, description="Statut de connexion")
    is_enabled: Optional[bool] = Field(None, description="Utilisateur activé")
    is_first_time: Optional[bool] = Field(None, description="Indique si c'est la première connexion")
    address: Optional[str] = Field(None, description="Adresse de l'utilisateur")
    company: Optional[str] = Field(None, description="Entreprise de l'utilisateur")