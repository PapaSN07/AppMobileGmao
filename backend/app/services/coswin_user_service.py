import logging
from typing import List, Dict, Any, Optional
from sqlalchemy import text
from app.db.sqlalchemy.session import get_main_session, SQLAlchemyQueryExecutor

logger = logging.getLogger(__name__)

class CoswinUserService:
    """
    Service gérant l'accès aux utilisateurs Coswin depuis la table officielle coswin_user dans la base ODS.
    Respecte les principes SOLID (Single Responsibility) et DRY.
    """

    @staticmethod
    def get_user_by_code(code: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un utilisateur Coswin par son code agent / matricule (cwcu_code).
        """
        if not code:
            return None
        
        query = """
            SELECT pk_coswin_user, cwcu_code, cwcu_signature, cwcu_email, cwcu_entity, cwcu_preferred_group
            FROM coswin_user
            WHERE cwcu_code = :code OR cwcu_signature = :code
        """
        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                rows = executor.execute_query(query, params={"code": str(code).strip()})
                if rows:
                    r = rows[0]
                    return {
                        "pk": r[0],
                        "code": r[1],
                        "username": r[2],
                        "email": r[3],
                        "entity": r[4],
                        "group": r[5]
                    }
        except Exception as e:
            logger.error(f"Erreur lors de la recherche de l'utilisateur {code} dans coswin_user: {e}")
        return None

    @staticmethod
    def search_users(query_str: str = "", entity: Optional[str] = None, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Recherche des utilisateurs Coswin par nom ou matricule, filtrés optionnellement par entité.
        """
        sql = """
            SELECT pk_coswin_user, cwcu_code, cwcu_signature, cwcu_email, cwcu_entity, cwcu_preferred_group
            FROM coswin_user
            WHERE 1=1
        """
        params: Dict[str, Any] = {}

        if query_str and query_str.strip():
            sql += " AND (LOWER(cwcu_signature) LIKE :q OR LOWER(cwcu_code) LIKE :q OR LOWER(cwcu_email) LIKE :q)"
            params["q"] = f"%{query_str.strip().lower()}%"

        if entity and entity.strip():
            sql += " AND UPPER(cwcu_entity) = :entity"
            params["entity"] = entity.strip().upper()

        sql += f" ORDER BY cwcu_signature ASC"

        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                rows = executor.execute_query(sql, params=params)
                results = []
                for r in rows[:limit]:
                    results.append({
                        "pk": r[0],
                        "code": r[1],
                        "username": r[2],
                        "email": r[3],
                        "entity": r[4],
                        "group": r[5]
                    })
                return results
        except Exception as e:
            logger.error(f"Erreur recherche utilisateurs coswin_user: {e}")
            return []

    @staticmethod
    def validate_employee_code(code: str) -> bool:
        """
        Vérifie si un matricule/code utilisateur existe réellement dans coswin_user.
        """
        if not code:
            return False
        
        query = "SELECT 1 FROM coswin_user WHERE cwcu_code = :code OR cwcu_signature = :code"
        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                rows = executor.execute_query(query, params={"code": str(code).strip()})
                return len(rows) > 0
        except Exception as e:
            logger.error(f"Erreur validation matricule {code}: {e}")
            return False
