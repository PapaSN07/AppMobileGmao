from pydantic import BaseModel, Field

class LoginRequest(BaseModel):
    username: str = Field(..., description="Identifiant de l'utilisateur", min_length=1)
    password: str = Field(..., description="Mot de passe de l'utilisateur", min_length=1)

class LogoutRequest(BaseModel):
    username: str = Field(..., description="Identifiant de l'utilisateur", min_length=1)