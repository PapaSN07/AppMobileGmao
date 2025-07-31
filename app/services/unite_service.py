from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_LONG
from app.core.cache import cache
from app.models.models import UniteModel
from app.db.requests import FUNCTION_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_unites() -> Dict[str, Any]:
    """Récupère toutes les unités depuis la base de données."""
    cached = cache.get_data_only("mobile_unites")
    if cached:
        return cached
    
    query = FUNCTION_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            unites = []
            for row in results:
                try:
                    unites.append(UniteModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping unité: {e}")
                    continue

            response = {"unites": unites, "count": len(unites)}
            cache.set("mobile_unites", response, CACHE_TTL_LONG)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur unités: {e}")
        raise