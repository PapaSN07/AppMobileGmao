from app.db.database import get_database_connection
from app.models.models import CentreChargeModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import COSTCENTRE_QUERY
from app.core.cache import cache
from typing import Any, Dict, List
import logging

logger = logging.getLogger(__name__)

def get_centre_charges(limit: int = 20) -> Dict[str, Any]:
    """Récupère les centres de charge depuis la base de données."""
    cache_key = f"mobile_centre_charges_{limit}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = COSTCENTRE_QUERY
    
    try:
        with get_database_connection() as db:
            # CORRECTION: Appliquer la limite dans la requête SQL
            limited_query = f"""
            SELECT * FROM (
                {query}
            ) WHERE ROWNUM <= {limit}
            """
            
            results = db.execute_query(limited_query)
            centre_charges = []
            
            for row in results:
                try:
                    centre_charge = CentreChargeModel.from_db_row(row)
                    
                    centre_charges.append(centre_charge.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping centre de charge: {e}")
                    continue

            response = {
                "centre_charges": centre_charges, 
                "count": len(centre_charges),
                "total_available": _get_total_count()  # Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(centre_charges)} centres de charge récupérés")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur centres de charge: {e}")
        raise

def _get_total_count() -> int:
    """Récupère le nombre total de centres de charge"""
    try:
        with get_database_connection() as db:
            result = db.execute_query("SELECT COUNT(*) FROM coswin.costcentre")
            return result[0][0] if result else 0
    except Exception:
        return 0