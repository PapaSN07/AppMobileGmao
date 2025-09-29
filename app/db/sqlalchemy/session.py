from contextlib import contextmanager
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Generator, Dict, Any, List, Optional
from .engine import MainSessionLocal, TempSessionLocal
import logging

logger = logging.getLogger(__name__)

@contextmanager
def get_main_session() -> Generator[Session, None, None]:
    """Générateur de session pour la DB principale"""
    session = MainSessionLocal()
    try:
        yield session
    except Exception as e:
        session.rollback()
        logger.error(f"❌ Erreur session principale: {e}")
        raise
    finally:
        session.close()

@contextmanager
def get_temp_session() -> Generator[Session, None, None]:
    """Générateur de session pour la DB temporaire"""
    session = TempSessionLocal()
    try:
        yield session
    except Exception as e:
        session.rollback()
        logger.error(f"❌ Erreur session temporaire: {e}")
        raise
    finally:
        session.close()

class SQLAlchemyQueryExecutor:
    """Classe pour exécuter des requêtes SQL brutes avec SQLAlchemy"""
    
    def __init__(self, session: Session):
        self.session = session
    
    def execute_query(self, query: str, params: Optional[Dict[str, Any]] = None, limit: Optional[int] = None) -> List[tuple]:
        """Exécute une requête SQL brute et retourne les résultats"""
        try:
            if limit is not None:
                query = f"{query} LIMIT {limit}"
            result = self.session.execute(text(query), params or {})
            return [tuple(row) for row in result.fetchall()]
        except Exception as e:
            logger.error(f"❌ Erreur exécution requête: {e}")
            raise
    
    def execute_update(self, query: str, params: Optional[Dict[str, Any]] = None, commit: bool = True) -> int:
        """Exécute une requête UPDATE/INSERT/DELETE"""
        try:
            result = self.session.execute(text(query), params or {})
            affected_rows = getattr(result, 'rowcount', 0)
            
            if commit:
                self.session.commit()
                logger.info(f"📝 {affected_rows} ligne(s) affectée(s) (commit effectué)")
            else:
                logger.info(f"📝 {affected_rows} ligne(s) affectée(s) (commit différé)")
            
            return affected_rows
        except Exception as e:
            if commit:
                self.session.rollback()
            logger.error(f"❌ Erreur mise à jour: {e}")
            raise
    
    def execute_scalar(self, query: str, params: Optional[Dict[str, Any]] = None):
        """Exécute une requête et retourne un seul résultat"""
        try:
            result = self.session.execute(text(query), params or {})
            return result.scalar()
        except Exception as e:
            logger.error(f"❌ Erreur scalar: {e}")
            raise