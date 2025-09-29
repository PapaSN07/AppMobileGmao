from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import QueuePool
import logging
from app.core.config import (
    DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT, DB_SERVICE_NAME,
    TEMP_DB_USERNAME, TEMP_DB_PASSWORD, TEMP_DB_HOST, TEMP_DB_PORT, TEMP_DB_SERVICE_NAME
)

logger = logging.getLogger(__name__)

# Base pour les modèles SQLAlchemy
Base = declarative_base()

# Configuration des engines
def create_main_engine():
    """Crée l'engine pour la DB principale"""
    url = f"oracle+cx_oracle://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/?service_name={DB_SERVICE_NAME}"
    
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        echo=False,  # Mettre à True pour voir les requêtes SQL
        future=True
    )
    
    logger.info("✅ Engine principal créé")
    return engine

def create_temp_engine():
    """Crée l'engine pour la DB temporaire"""
    url = f"oracle+cx_oracle://{TEMP_DB_USERNAME}:{TEMP_DB_PASSWORD}@{TEMP_DB_HOST}:{TEMP_DB_PORT}/?service_name={TEMP_DB_SERVICE_NAME}"
    
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,
        echo=False,
        future=True
    )
    
    logger.info("✅ Engine temporaire créé")
    return engine

# Engines globaux
main_engine = create_main_engine()
temp_engine = create_temp_engine()

# Sessions makers
MainSessionLocal = sessionmaker(bind=main_engine, autoflush=False, autocommit=False)
TempSessionLocal = sessionmaker(bind=temp_engine, autoflush=False, autocommit=False)