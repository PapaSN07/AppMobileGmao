import os
from typing import Optional
from pydantic import BaseSettings
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

class Settings(BaseSettings):
    """Configuration de l'application GMAO"""
    
    # Configuration Base de données Oracle
    DB_NAME: str = os.getenv("DB_NAME", "Coswin_DDOT")
    DB_USERNAME: str = os.getenv("DB_USERNAME", "smdt")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "Smdt2025")
    DB_HOST: str = os.getenv("DB_HOST", "10.101.3.171")
    DB_SERVICE_NAME: str = os.getenv("DB_SERVICE_NAME", "CWPROD")
    DB_PORT: int = int(os.getenv("DB_PORT", "1521"))
    
    # Configuration des limites et pagination
    DEFAULT_LIMIT: int = int(os.getenv("DEFAULT_LIMIT", "10"))
    MAX_LIMIT: int = int(os.getenv("MAX_LIMIT", "1000"))
    DEFAULT_PAGE_SIZE: int = int(os.getenv("DEFAULT_PAGE_SIZE", "10"))
    MAX_PAGE_SIZE: int = int(os.getenv("MAX_PAGE_SIZE", "100"))
    
    # Configuration Redis
    REDIS_HOST: str = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT: int = int(os.getenv("REDIS_PORT", "6379"))
    REDIS_DB: int = int(os.getenv("REDIS_DB", "0"))
    
    # Configuration de l'application
    APP_NAME: str = "GMAO Backend API"
    VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    
    @property
    def oracle_dsn(self) -> str:
        """Construire la chaîne de connexion Oracle"""
        return f"{self.DB_HOST}:{self.DB_PORT}/{self.DB_SERVICE_NAME}"
    
    @property
    def redis_url(self) -> str:
        """Construire l'URL Redis"""
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Instance globale des paramètres
settings = Settings()