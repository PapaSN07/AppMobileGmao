from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import time
import logging
import os

from fastapi.security import HTTPBearer
from fastapi.staticfiles import StaticFiles

from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session, get_temp_session, test_connection
from app.routers.auth_router import authenticate_user_router
from app.routers.mobile.equipment_router import equipment_router
from app.routers.web.equipment_router import equipment_router_web
from app.routers.web.user_router import user_router_web
from app.routers.mobile.centre_charge_router import centre_charge_router
from app.routers.mobile.famille_router import famille_router
from app.routers.mobile.entity_router import entity_router
from app.routers.web.entity_router import entity_router_web
from app.routers.mobile.unite_router import unite_router
from app.routers.mobile.zone_router import zone_router
from app.routers.mobile.ot_router import ot_router
from app.core.cache import cache
from app.routers.websocket_router import router_ws
from app.routers.notification_router import router_notification
from app.routers.web.statistique_router import statistique_router_web
from app.services.jwt_service import jwt_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

security = HTTPBearer()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Démarrage
    logger.info("🚀 Démarrage Equipment Mobile API")
    
    # Test DB Principale
    try:
        with get_main_session() as session:
            db_connected = test_connection(session)
            if db_connected:
                logger.info("✅ DB Principale Oracle: OK")
            else:
                logger.warning("⚠️ DB Principale Oracle: KO (mode dégradé)")
    except Exception as e:
        logger.warning(f"⚠️ DB Principale Oracle: KO - {str(e)[:100]}")
    
    # Test DB Temporaire
    try:
        with get_temp_session() as session:
            db_connected = test_connection(session)
            if db_connected:
                logger.info("✅ DB Temporaire MSSQL: OK")
            else:
                logger.warning("⚠️ DB Temporaire MSSQL: KO (mode dégradé)")
    except Exception as e:
        logger.warning(f"⚠️ DB Temporaire MSSQL: KO - {str(e)[:100]}")
    
    logger.info(f"✅ Redis: {'OK' if cache.is_available else 'KO'}")
    
    yield
    
    # Arrêt
    logger.info("🛑 Arrêt Equipment Mobile API")

# App FastAPI minimale
app = FastAPI(
    title="GMAO Mobile API",
    description="API optimisée pour application mobile Flutter",
    version="1.0.0",
    lifespan=lifespan,
    # Configuration Swagger pour l'authentification
    swagger_ui_parameters={
        "persistAuthorization": True,  # Garde l'auth entre les rechargements
    }
)

app.openapi_tags = [
    {"name": "auth", "description": "Authentification"},
]

# Configuration OpenAPI pour les headers personnalisés
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    from fastapi.openapi.utils import get_openapi
    
    openapi_schema = get_openapi(
        title="GMAO - SENELEC API",
        version="1.0.0",
        description="API senelec pour application mobile Flutter + Angular Web",
        routes=app.routes,
    )
    
    # Ajouter les schémas de sécurité
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        },
    }
    
    # Appliquer la sécurité globalement
    openapi_schema["security"] = [
        {"BearerAuth": []},
    ]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

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
    allow_methods=["GET", "POST", "PUT", "DELETE"],
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
        from app.core.cache import cache
        
        # Test DB simple
        db_ok = True
        try:
            with get_main_session() as session:
                db = SQLAlchemyQueryExecutor(session)
                db.execute_query("SELECT 1")
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

# Inclusion du routeur pour le mobile & web
PREFIX = "/api/v1"
app.include_router(authenticate_user_router, prefix=PREFIX)

# Inclusion du routeur pour le mobile
PREFIX_MOBILE = "/api/v1/mobile"
app.include_router(equipment_router, prefix=PREFIX_MOBILE)
app.include_router(entity_router, prefix=PREFIX_MOBILE)
app.include_router(centre_charge_router, prefix=PREFIX_MOBILE)
app.include_router(famille_router, prefix=PREFIX_MOBILE)
app.include_router(unite_router, prefix=PREFIX_MOBILE)
app.include_router(zone_router, prefix=PREFIX_MOBILE)
app.include_router(ot_router, prefix=PREFIX_MOBILE)

# Inclusion du routeur pour le web
PREFIX_WEB = "/api/v1/web"
app.include_router(equipment_router_web, prefix=PREFIX_WEB)
app.include_router(user_router_web, prefix=PREFIX_WEB)
app.include_router(entity_router_web, prefix=PREFIX_WEB)
app.include_router(statistique_router_web, prefix=PREFIX_WEB)

# Inclusion du routeur pour les websockets
app.include_router(router_ws, tags=["WebSocket - Notifications"])
app.include_router(router_notification, tags=["Notifications"])

if __name__ == "__main__":
    import uvicorn
    import os

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8003"))

    uvicorn.run(app, host=host, port=port)