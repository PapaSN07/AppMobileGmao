from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import time
import logging

from app.routers.equipment_router import equipment_router
from app.routers.user_router import authenticate_user_router
from app.core.config import REDIS_HOST, REDIS_PORT
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
        "http://localhost:*",
        "http://127.0.0.1:*", 
        "http://10.0.2.2:*",
        "http://192.168.*.*:*",  # Pour réseaux locaux
        "*"  # Pour développement, à restreindre en production
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# Routes
@app.get("/")
async def root():
    return {
        "api": "GMAO Mobile API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": "/api/v1/equipments"
    }

@app.get("/health")
async def health():
    db_ok = test_connection()
    return {
        "status": "healthy" if db_ok else "degraded",
        "database": db_ok,
        "cache": cache.is_available
    }

# Inclusion du routeur
PREFIX = "/api/v1"
app.include_router(equipment_router, prefix=PREFIX)
app.include_router(authenticate_user_router, prefix=PREFIX)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)