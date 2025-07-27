import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv('.env.prod')

# Configuration de la base de données Oracle
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME") 
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_SERVICE_NAME = os.getenv("DB_SERVICE_NAME")

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

# Vérification des variables obligatoires
required_vars = [DB_USERNAME, DB_PASSWORD, DB_HOST, DB_SERVICE_NAME]
if not all(required_vars):
    raise ValueError("Variables d'environnement de base de données manquantes dans .env.prod")

print(f"Configuration chargée - DB: {DB_HOST}:{DB_SERVICE_NAME}")