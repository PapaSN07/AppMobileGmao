import logging
from fastapi import Depends
from sqlalchemy.orm import Session

from app.core import config
from app.db.sqlalchemy.engine import get_mock_db_session
from app.repositories.base import AbstractWorkOrderRepository
from app.repositories.local_sql import LocalSQLWorkOrderRepository
from app.repositories.coswin_api import CoswinAPIWorkOrderRepository

logger = logging.getLogger(__name__)

# =====================================================================
# CONFIGURATION ACTIVE (Injection Coswin API / Production)
# =====================================================================
def get_workorder_repository(
    db: Session = Depends(get_mock_db_session)
) -> AbstractWorkOrderRepository:
    """Fournit dynamiquement le repository configuré."""
    if config.DATA_SOURCE == "local":
        logger.info("Injecting LocalSQLWorkOrderRepository (coswin_mock)")
        return LocalSQLWorkOrderRepository(db)
    else:
        logger.info("Injecting CoswinAPIWorkOrderRepository (Senelec API)")
        return CoswinAPIWorkOrderRepository()


# =====================================================================
# CODE D'ORIGINE / ALTERNATIF PERSO (Sauvegardé en commentaire)
# Pour réactiver cette version, décommentez le bloc ci-dessous :
# =====================================================================
# def get_workorder_repository_local(db: Session = Depends(get_mock_db_session)) -> AbstractWorkOrderRepository:
#     """Version locale originale conservée en secours."""
#     logger.info("Injecting LocalSQLWorkOrderRepository (coswin_mock) - Backup Perso")
#     return LocalSQLWorkOrderRepository(db)

