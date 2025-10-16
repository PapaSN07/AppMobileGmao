from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import QueuePool
import logging
import urllib.parse

from app.core.config import (
    DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME,
    TEMP_DB_USERNAME, TEMP_DB_PASSWORD, TEMP_DB_HOST, TEMP_DB_PORT, TEMP_DB_NAME
)

logger = logging.getLogger(__name__)

# ===== DEUX BASES DÉCLARATIVES SÉPARÉES =====
# Base pour gmao_backend (lecture principale)
Base = declarative_base()

# Base pour gmao_mobile (insertion ClicClac)
BaseClicClac = declarative_base()

def _make_odbc_engine_url(user: str | None, password: str | None, host: str | None, port: str | None, database: str | None, driver: str = "ODBC Driver 18 for SQL Server"):
    """Construit une URL ODBC sécurisée avec encodage des caractères spéciaux"""
    dsn = f"DRIVER={{{driver}}};SERVER={host},{port};DATABASE={database};UID={user};PWD={password};TrustServerCertificate=yes;Encrypt=no"
    return "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(dsn)

def create_main_engine():
    """Crée l'engine pour gmao_backend (lecture)"""
    url = _make_odbc_engine_url(DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME)
    
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        echo=False,
        future=True
    )
    
    logger.info(f"✅ Engine principal créé (gmao_backend): {DB_NAME}")
    return engine

def create_temp_engine():
    """Crée l'engine pour gmao_mobile (insertion ClicClac)"""
    url = _make_odbc_engine_url(TEMP_DB_USERNAME, TEMP_DB_PASSWORD, TEMP_DB_HOST, TEMP_DB_PORT, TEMP_DB_NAME)
    
    engine = create_engine(
        url,
        poolclass=QueuePool,
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,
        echo=False,
        future=True
    )
    
    logger.info(f"✅ Engine temporaire créé (gmao_mobile): {TEMP_DB_NAME}")
    return engine

# Créer les engines
main_engine = create_main_engine()
temp_engine = create_temp_engine()

# Sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=main_engine, future=True)
SessionLocalTemp = sessionmaker(autocommit=False, autoflush=False, bind=temp_engine, future=True)

def get_db_session():
    """Session pour gmao_backend (lecture)"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_temp_session():
    """Session pour gmao_mobile (insertion ClicClac)"""
    db = SessionLocalTemp()
    try:
        yield db
    finally:
        db.close()

def create_all_tables():
    """Crée toutes les tables (à utiliser avec précaution)"""
    Base.metadata.create_all(bind=main_engine)
    BaseClicClac.metadata.create_all(bind=temp_engine)
    logger.info("✅ Tables créées dans les deux bases")