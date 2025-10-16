from typing import Optional

class AuthenticationError(Exception):
    """Exception de base pour les erreurs d'authentification."""
    def __init__(self, message: str, status_code: int = 401, error_code: Optional[str] = None):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code  # Code personnalisé pour le frontend (ex. "USER_NOT_FOUND")
        super().__init__(self.message)

class UserNotFoundError(AuthenticationError):
    """Utilisateur inexistant (username/email incorrect)."""
    def __init__(self, username: str):
        super().__init__(
            message=f"Utilisateur '{username}' introuvable.",
            status_code=401,
            error_code="USER_NOT_FOUND"
        )

class InvalidPasswordError(AuthenticationError):
    """Mot de passe incorrect."""
    def __init__(self, username: str):
        super().__init__(
            message=f"Mot de passe incorrect pour '{username}'.",
            status_code=401,
            error_code="INVALID_PASSWORD"
        )

class DatabaseError(AuthenticationError):
    """Erreur de base de données."""
    def __init__(self, message: str):
        super().__init__(
            message=message,
            status_code=500,
            error_code="DATABASE_ERROR"
        )