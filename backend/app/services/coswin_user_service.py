import logging
from typing import List, Dict, Any, Optional
from sqlalchemy import text
from app.db.sqlalchemy.session import get_main_session, SQLAlchemyQueryExecutor

logger = logging.getLogger(__name__)

class CoswinUserService:
    """
    Service gérant l'accès aux utilisateurs Coswin depuis la table officielle COSWIN_USER dans la base gmao_mutualise_ODS.
    Respecte strictement les principes SOLID (Single Responsibility) et DRY.
    """

    @staticmethod
    def _map_user_row(row: tuple) -> Dict[str, Any]:
        """
        Méthode utilitaire DRY pour formater un tuple SQL de la table COSWIN_USER (CWCU_*) en dictionnaire utilisateur.
        """
        if not row:
            return {}
        return {
            "pk": row[0],
            "code": str(row[1]).strip() if row[1] is not None else "",
            "username": str(row[2]).strip() if row[2] is not None else "",
            "email": str(row[3]).strip() if len(row) > 3 and row[3] is not None else "",
            "entity": str(row[4]).strip() if len(row) > 4 and row[4] is not None else "",
            "group": str(row[5]).strip() if len(row) > 5 and row[5] is not None else "USER"
        }

    @classmethod
    def get_user_by_code(cls, code: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un utilisateur Coswin par son code agent / matricule depuis COSWIN_USER (gmao_mutualise_ODS).
        """
        if not code or not str(code).strip():
            return None
        
        val = str(code).strip()

        query = """
            SELECT TOP 1 PK_COSWIN_USER as pk, CWCU_CODE as code, CWCU_SIGNATURE as username, 
                         CWCU_EMAIL as email, CWCU_ENTITY as entity, COALESCE(CWCU_PREFERRED_GROUP, 'USER') as preferred_group
            FROM dbo.COSWIN_USER
            WHERE LOWER(CWCU_CODE) = LOWER(:code) OR LOWER(CWCU_SIGNATURE) = LOWER(:code)
        """

        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                rows = executor.execute_query(query, params={"code": val})
                if rows:
                    return cls._map_user_row(rows[0])
        except Exception as e:
            logger.error(f"❌ Erreur lors de la recherche de l'utilisateur {code} dans gmao_mutualise_ODS.dbo.COSWIN_USER: {e}")
            raise e
        
        return None

    @classmethod
    def search_users(cls, query_str: str = "", entity: Optional[str] = None, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Recherche des utilisateurs Coswin directement dans la table gmao_mutualise_ODS.dbo.COSWIN_USER.
        """
        params: Dict[str, Any] = {}
        where_clause = "WHERE 1=1"

        if query_str and query_str.strip():
            q_val = f"%{query_str.strip().lower()}%"
            where_clause += " AND (LOWER(CWCU_SIGNATURE) LIKE :q OR LOWER(CWCU_CODE) LIKE :q OR LOWER(CWCU_EMAIL) LIKE :q)"
            params["q"] = q_val

        if entity and entity.strip():
            e_val = entity.strip().upper()
            where_clause += " AND UPPER(CWCU_ENTITY) = :entity"
            params["entity"] = e_val

        sql = f"""
            SELECT DISTINCT TOP {limit} PK_COSWIN_USER as pk, CWCU_CODE as code, CWCU_SIGNATURE as username, 
                   CWCU_EMAIL as email, CWCU_ENTITY as entity, COALESCE(CWCU_PREFERRED_GROUP, 'USER') as preferred_group
            FROM dbo.COSWIN_USER
            {where_clause}
            ORDER BY CWCU_SIGNATURE ASC
        """

        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                rows = executor.execute_query(sql, params=params)
                return [cls._map_user_row(r) for r in rows]
        except Exception as e:
            logger.error(f"❌ Erreur recherche utilisateurs dans gmao_mutualise_ODS.dbo.COSWIN_USER: {e}")
            raise e

    @classmethod
    def validate_employee_code(cls, code: str) -> bool:
        """
        Vérifie si un matricule/code utilisateur existe dans gmao_mutualise_ODS.dbo.COSWIN_USER.
        """
        user = cls.get_user_by_code(code)
        return user is not None
