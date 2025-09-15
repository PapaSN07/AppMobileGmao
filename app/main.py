from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import time
import logging
import os

from fastapi.staticfiles import StaticFiles

from app.routers.equipment_router import equipment_router
from app.routers.user_router import authenticate_user_router
from app.routers.centre_charge_router import centre_charge_router
from app.routers.famille_router import famille_router
from app.routers.entity_router import entity_router
from app.routers.unite_router import unite_router
from app.routers.zone_router import zone_router
from app.core.cache import cache
from app.db.database import test_connection

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Démarrage
    logger.info("🚀 Démarrage Equipment Mobile API")
    
    db_connected = test_connection()
    logger.info(f"✅ DB: {'OK' if db_connected else 'KO'}")
    logger.info(f"✅ Redis: {'OK' if cache.is_available else 'KO'}")
    
    yield
    
    # Arrêt
    logger.info("🛑 Arrêt Equipment Mobile API")

# App FastAPI minimale
app = FastAPI(
    title="GMAO Mobile API",
    description="API optimisée pour application mobile Flutter",
    version="1.0.0",
    lifespan=lifespan
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Log de la requête entrante
    logger.info(f"📥 {request.method} {request.url}")
    
    response = await call_next(request)
    
    # Calculer le temps de traitement
    process_time = time.time() - start_time
    logger.info(f"📤 {request.method} {request.url} - {response.status_code} - {process_time:.2f}s")
    
    return response

# CORS pour mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",  # Pour développement, à restreindre en production
        # "http://localhost:*",
        # "http://127.0.0.1:*", 
        # "http://10.0.2.2:*",
        # "http://192.168.*.*:*"  # Pour réseaux locaux
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Créer le dossier static s'il n'existe pas
static_dir = "static"
if not os.path.exists(static_dir):
    os.makedirs(static_dir)

# Monter les fichiers statiques
app.mount("/static", StaticFiles(directory="static"), name="static")

# Route pour favicon.ico
@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    favicon_path = "static/favicon.ico"
    if os.path.exists(favicon_path):
        return FileResponse(favicon_path)
    else:
        # Retourner une réponse vide si pas de favicon
        return FileResponse("static/favicon.ico", status_code=404)

# Routes
@app.get("/")
async def root():
    return {
        "api": "GMAO Mobile API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "equipments": "/api/v1/equipments",
            "equipment_detail": "/api/v1/equipments/{equipment_id}",
            "feeders": "/api/v1/equipments/feeders/{famille}",
            "zones": "/api/v1/zones",
            "entities": "/api/v1/entities",
            "costcentres": "/api/v1/costcentres",
            "functions": "/api/v1/functions",
            "families": "/api/v1/families",
            "units": "/api/v1/units"
        },
    }

@app.get("/health")
async def health():
    """Health check global simple"""
    try:
        from app.db.database import get_database_connection
        from app.core.cache import cache
        
        # Test DB simple
        db_ok = True
        try:
            db_conn = get_database_connection()
            if db_conn is None:
                logger.error("Impossible d'obtenir une connexion à la base de données")
                raise Exception("Connexion DB manquante")
            with db_conn as db:
                db.execute_query("SELECT 1 FROM DUAL")
        except Exception as e:
            logger.error(f"DB Health check failed: {e}")
            db_ok = False
        
        return {
            "status": "healthy" if db_ok else "degraded",
            "database": db_ok,
            "cache": cache.is_available,
            "tables_status": "checking tables requires equipment health endpoint"
        }
    except Exception as e:
        logger.error(f"Global health check error: {e}")
        return {
            "status": "error", 
            "database": False,
            "cache": False,
            "error": str(e)
        }

# Inclusion du routeur
PREFIX = "/api/v1"
app.include_router(authenticate_user_router, prefix=PREFIX)
app.include_router(equipment_router, prefix=PREFIX)
app.include_router(entity_router, prefix=PREFIX)
app.include_router(centre_charge_router, prefix=PREFIX)
app.include_router(famille_router, prefix=PREFIX)
app.include_router(unite_router, prefix=PREFIX)
app.include_router(zone_router, prefix=PREFIX)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)