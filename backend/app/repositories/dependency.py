import logging
from fastapi import Depends
from sqlalchemy.orm import Session

from app.core import config
from app.db.sqlalchemy.engine import get_mock_db_session
from app.repositories.base import AbstractWorkOrderRepository
from app.repositories.local_sql import LocalSQLWorkOrderRepository
from app.repositories.coswin_api import CoswinAPIWorkOrderRepository

logger = logging.getLogger(__name__)

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
