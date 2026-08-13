import os
from pathlib import Path
from dotenv import load_dotenv

# Charger uniquement la base .env.prod pour le runtime du backend.
_base_dir = Path(__file__).resolve().parents[2]
_env_prod_path = _base_dir / '.env.prod'

load_dotenv(_env_prod_path, override=True)

# Configuration de la base de données Oracle
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME") 
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "1430")

# Configuration de la base de données Oracle
TEMP_DB_NAME = os.getenv("TEMP_DB_NAME")
TEMP_DB_USERNAME = os.getenv("TEMP_DB_USERNAME")
TEMP_DB_PASSWORD = os.getenv("TEMP_DB_PASSWORD")
TEMP_DB_HOST = os.getenv("TEMP_DB_HOST")
TEMP_DB_PORT = os.getenv("TEMP_DB_PORT", "1521")

# Configuration des limites
DEFAULT_LIMIT = int(os.getenv("DEFAULT_LIMIT", 10))
MAX_LIMIT = int(os.getenv("MAX_LIMIT", 1000))
DEFAULT_PAGE_SIZE = int(os.getenv("DEFAULT_PAGE_SIZE", 10))
MAX_PAGE_SIZE = int(os.getenv("MAX_PAGE_SIZE", 100))

# Configuration Redis
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

# Configuration du cache
CACHE_TTL_SHORT = 300    # 5 minutes
CACHE_TTL_MEDIUM = 1800  # 30 minutes  
CACHE_TTL_LONG = 3600    # 1 heure

# Configuration JWT
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-prod")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", 30))
JWT_REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("JWT_REFRESH_TOKEN_EXPIRE_DAYS", 7))

# Configuration mot de passe par défaut pour les prestataires
DEFAULT_PASSWORD_PRESTATAIRE = os.getenv("DEFAULT_PASSWORD_PRESTATAIRE", "changeMe123!")

# Configuration API OT (Coswin)
OT_API_BASE_URL = os.getenv("OT_API_BASE_URL", "http://10.101.1.102:8083/ws/rest")
OT_API_USERNAME = os.getenv("OT_API_USERNAME", "coswinws")
OT_API_PASSWORD = os.getenv("OT_API_PASSWORD", "supervisor")
OT_DATASOURCE = os.getenv("OT_DATASOURCE", "Coswin")
OT_CWUSER = os.getenv("OT_CWUSER", "coswinws")

DATA_SOURCE = os.getenv("DATA_SOURCE", "coswin").lower()
# Mode local OT: permet de continuer les tests sans dependre de l'API Coswin.
OT_USE_LOCAL_MOCK = (os.getenv("OT_USE_LOCAL_MOCK", "false").lower() == "true") or (DATA_SOURCE == "local")
# Chemin optionnel du fichier JSON local OT. Si vide, un chemin par defaut est utilise.
OT_LOCAL_JSON_PATH = os.getenv("OT_LOCAL_JSON_PATH", "")

# Vérification des variables obligatoires
required_vars = [DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT, TEMP_DB_USERNAME, TEMP_DB_PASSWORD, TEMP_DB_HOST, TEMP_DB_PORT]
if not all(required_vars):
    raise ValueError("Variables d'environnement de base de données manquantes dans .env.prod")

print(f"Configuration chargée - DB: {DB_HOST}:{DB_PORT}/{DB_NAME}, TEMP DB: {TEMP_DB_HOST}:{TEMP_DB_PORT}/{TEMP_DB_NAME}")