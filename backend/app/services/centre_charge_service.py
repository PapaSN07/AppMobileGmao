from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.costcentre_model import CentreChargeModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import COSTCENTRE_QUERY
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_centre_charges(entity: str) -> Dict[str, Any]:
    """Récupère les centres de charge depuis la base de données."""

    cache_key = f"mobile_centre_charges_{entity}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = COSTCENTRE_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)

            query += f" ORDER BY mdcc_entity, mdcc_code"

            results = executor.execute_query(query, params=params)
            centre_charges = []
            
            for row in results:
                try:
                    centre_charge = CentreChargeModel.from_db_row(row)
                    
                    centre_charges.append(centre_charge.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping centre de charge: {e}")
                    continue

            if not centre_charges:
                from sqlalchemy import text
                eq_rows = []
                try:
                    eq_rows = session.execute(text("SELECT DISTINCT ereq_costcentre FROM dbo.equipment WHERE ereq_costcentre IS NOT NULL AND ereq_costcentre != ''")).fetchall()
                except Exception:
                    pass
                if not eq_rows:
                    try:
                        eq_rows = session.execute(text("SELECT DISTINCT centre_charge FROM gmao_mobile.dbo.equipment WHERE centre_charge IS NOT NULL AND centre_charge != ''")).fetchall()
                    except Exception:
                        pass
                for r in eq_rows:
                    val = str(r[0])
                    centre_charges.append({
                        "code": val,
                        "description": val,
                        "entity": entity
                    })

            response = {
                "centre_charges": centre_charges, 
                "count": len(centre_charges),# Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(centre_charges)} centres de charge récupérés")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur centres de charge: {e}")
        raise