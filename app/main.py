from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import logging
import time
from typing import Dict, Any
import uvicorn

# Imports des modules de l'application
from app.routers.equipment_router import equipment_router
from app.core.config import (
    DB_HOST, DB_SERVICE_NAME, 
    REDIS_HOST, REDIS_PORT,
    DEFAULT_LIMIT, MAX_LIMIT
)
from app.core.cache import cache, get_cache_stats
from app.db.database import test_connection

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('app.log')
    ]
)
logger = logging.getLogger(__name__)

# Gestionnaire de contexte pour le cycle de vie de l'application
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gestionnaire du cycle de vie de l'application FastAPI.
    Gère le démarrage et l'arrêt de l'application.
    """
    # === DÉMARRAGE DE L'APPLICATION ===
    logger.info("🚀 Démarrage de l'application Equipment Management API")
    
    try:
        # Vérification de la connexion à la base de données
        logger.info("🔍 Vérification de la connexion à la base de données...")
        db_connected = test_connection()
        
        if db_connected:
            logger.info(f"✅ Connexion DB réussie: {DB_HOST}:{DB_SERVICE_NAME}")
        else:
            logger.warning(f"⚠️ Connexion DB échouée: {DB_HOST}:{DB_SERVICE_NAME}")
        
        # Vérification du cache Redis
        logger.info("🗄️ Vérification de la connexion Redis...")
        if cache.is_available:
            logger.info(f"✅ Redis connecté: {REDIS_HOST}:{REDIS_PORT}")
            cache_stats = get_cache_stats()
            logger.info(f"📊 Cache: {cache_stats.get('keys_count', 0)} clés en mémoire")
        else:
            logger.warning(f"⚠️ Redis non disponible: {REDIS_HOST}:{REDIS_PORT}")
        
        # Préchargement des données de référence (optionnel)
        try:
            from app.services.equipment_service import get_zones, get_familles, get_entities
            logger.info("📋 Préchargement des données de référence...")
            
            # Charger les zones, familles et entités en cache
            zones = get_zones()
            familles = get_familles()
            entities = get_entities()
            
            logger.info(f"✅ Données préchargées: {zones['count']} zones, {familles['count']} familles, {entities['count']} entités")
            
        except Exception as e:
            logger.warning(f"⚠️ Erreur préchargement données: {e}")
        
        logger.info("🎉 Application démarrée avec succès!")
        
        # Point de rendement - l'application fonctionne ici
        yield
        
    except Exception as e:
        logger.error(f"❌ Erreur critique au démarrage: {e}")
        raise
    
    # === ARRÊT DE L'APPLICATION ===
    logger.info("🛑 Arrêt de l'application Equipment Management API")
    
    try:
        # Nettoyage des ressources si nécessaire
        logger.info("🧹 Nettoyage des ressources...")
        
        # Pas besoin de fermer Redis explicitement (connexions automatiques)
        # Les connexions DB sont gérées par le context manager
        
        logger.info("✅ Arrêt propre de l'application")
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'arrêt: {e}")

# Création de l'application FastAPI
app = FastAPI(
    title="Equipment Management API",
    description="""
    ## API de Gestion des Équipements Senelec
    
    Cette API permet de gérer et consulter les équipements de l'infrastructure électrique de Senelec.
    
    ### Fonctionnalités principales :
    
    * **Recherche d'équipements** avec filtres avancés et pagination
    * **Données de référence** (zones, familles, entités)
    * **Statistiques** et métriques des équipements
    * **Cache Redis** pour des performances optimales
    * **API REST** complète et documentée
    
    ### Bases de données :
    
    * **Oracle Database** : Données métier (Coswin)
    * **Redis** : Cache et performances
    
    ### Endpoints principaux :
    
    * `/api/v1/equipments/` - Recherche avec filtres
    * `/api/v1/equipments/reference/` - Données de référence
    * `/api/v1/equipments/stats/` - Statistiques
    * `/api/v1/equipments/admin/` - Administration
    
    """,
    version="1.0.0",
    contact={
        "name": "Équipe DSI Senelec",
        "email": "dsi@senelec.sn",
    },
    license_info={
        "name": "Propriétaire Senelec",
    },
    lifespan=lifespan
)

# === MIDDLEWARE ===

# CORS Middleware pour permettre les requêtes cross-origin (applications mobiles)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # React/Vue local dev
        "http://localhost:8080",  # Vue CLI
        "http://localhost:8100",  # Ionic dev
        "http://127.0.0.1:8100",  # Ionic dev alternative
        "*"  # Pour le développement - à restreindre en production
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
)

# Trusted Host Middleware pour la sécurité
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=[
        "localhost",
        "127.0.0.1",
        "*.senelec.sn",  # Domaines Senelec
        "*"  # Pour le développement - à restreindre en production
    ]
)

# Middleware custom pour le logging des requêtes
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """
    Middleware pour logger toutes les requêtes HTTP.
    """
    start_time = time.time()
    
    # Informations de la requête
    client_ip = request.client.host if request.client else "unknown"
    method = request.method
    url = str(request.url)
    user_agent = request.headers.get("user-agent", "unknown")
    
    logger.info(f"📥 {method} {url} - IP: {client_ip} - User-Agent: {user_agent[:100]}")
    
    # Traitement de la requête
    try:
        response = await call_next(request)
        
        # Calcul du temps de traitement
        process_time = time.time() - start_time
        
        # Log de la réponse
        logger.info(f"📤 {method} {url} - Status: {response.status_code} - Time: {process_time:.3f}s")
        
        # Ajouter le temps de traitement dans les headers
        response.headers["X-Process-Time"] = str(process_time)
        
        return response
        
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f"❌ {method} {url} - Error: {str(e)} - Time: {process_time:.3f}s")
        raise

# === GESTION D'ERREURS GLOBALE ===

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """
    Gestionnaire d'erreurs HTTP personnalisé.
    """
    logger.warning(f"⚠️ HTTP {exc.status_code}: {exc.detail} - URL: {request.url}")
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "status_code": exc.status_code,
            "message": exc.detail,
            "timestamp": time.time(),
            "path": str(request.url.path)
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """
    Gestionnaire d'erreurs générales.
    """
    logger.error(f"❌ Erreur inattendue: {str(exc)} - URL: {request.url}")
    
    return JSONResponse(
        status_code=500,
        content={
            "error": True,
            "status_code": 500,
            "message": "Erreur interne du serveur",
            "timestamp": time.time(),
            "path": str(request.url.path)
        }
    )

# === ROUTES PRINCIPALES ===

# Route racine
@app.get("/", tags=["Système"])
async def read_root():
    """
    Endpoint racine de l'API.
    """
    return {
        "application": "Equipment Management API",
        "version": "1.0.0",
        "status": "running",
        "description": "API de gestion des équipements Senelec",
        "documentation": "/docs",
        "health_check": "/health",
        "api_base": "/api/v1"
    }

# Health check global
@app.get("/health", tags=["Système"])
async def health_check():
    """
    Endpoint de vérification de santé globale de l'application.
    """
    try:
        # Vérification de la base de données
        db_status = test_connection()
        
        # Vérification du cache
        cache_status = cache.is_available
        cache_info = get_cache_stats() if cache_status else {}
        
        # Déterminer le statut global
        overall_status = "healthy" if (db_status and cache_status) else "degraded"
        if not db_status:
            overall_status = "unhealthy"
        
        health_data = {
            "status": overall_status,
            "timestamp": time.time(),
            "services": {
                "database": {
                    "status": "connected" if db_status else "disconnected",
                    "host": DB_HOST,
                    "service": DB_SERVICE_NAME
                },
                "cache": {
                    "status": "available" if cache_status else "unavailable",
                    "host": REDIS_HOST,
                    "port": REDIS_PORT,
                    "keys_count": cache_info.get("keys_count", 0),
                    "memory_usage": cache_info.get("memory_usage", "unknown")
                }
            },
            "configuration": {
                "default_limit": DEFAULT_LIMIT,
                "max_limit": MAX_LIMIT,
                "cache_enabled": cache_status
            }
        }
        
        status_code = 200 if overall_status == "healthy" else 503
        
        return JSONResponse(
            status_code=status_code,
            content=health_data
        )
        
    except Exception as e:
        logger.error(f"❌ Erreur health check: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "timestamp": time.time(),
                "error": str(e)
            }
        )

# Informations système
@app.get("/info", tags=["Système"])
async def system_info():
    """
    Informations détaillées sur le système.
    """
    import sys
    import platform
    from datetime import datetime
    
    return {
        "application": {
            "name": "Equipment Management API",
            "version": "1.0.0",
            "environment": "development",  # À changer selon l'environnement
        },
        "system": {
            "python_version": sys.version,
            "platform": platform.platform(),
            "architecture": platform.architecture(),
        },
        "database": {
            "type": "Oracle",
            "host": DB_HOST,
            "service": DB_SERVICE_NAME,
            "connected": test_connection()
        },
        "cache": {
            "type": "Redis",
            "host": REDIS_HOST,
            "port": REDIS_PORT,
            "available": cache.is_available
        },
        "api": {
            "docs_url": "/docs",
            "redoc_url": "/redoc",
            "openapi_url": "/openapi.json"
        },
        "timestamp": datetime.now().isoformat()
    }

# === INCLUSION DES ROUTEURS ===

# Inclusion du routeur des équipements
app.include_router(
    equipment_router,
    prefix="/api/v1/equipments",
    tags=["Équipements"]
)

# Route pour les métriques (optionnel - pour monitoring)
@app.get("/metrics", tags=["Monitoring"])
async def get_metrics():
    """
    Endpoint pour les métriques de monitoring.
    """
    try:
        cache_stats = get_cache_stats()
        db_connected = test_connection()
        
        return {
            "database": {
                "connected": db_connected,
                "connection_string": f"{DB_HOST}:1521/{DB_SERVICE_NAME}"
            },
            "cache": cache_stats,
            "application": {
                "status": "running",
                "uptime_check": "healthy" if db_connected else "degraded"
            }
        }
    except Exception as e:
        return {"error": str(e), "status": "error"}

# === CONFIGURATION POUR LE DÉVELOPPEMENT ===

if __name__ == "__main__":
    """
    Point d'entrée pour le développement local.
    """
    logger.info("🚀 Démarrage en mode développement...")
    
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        log_level="info",
        access_log=True,
        reload_includes=["*.py"],
        reload_excludes=["*.pyc", "__pycache__"]
    )