from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_LONG
from app.core.cache import cache
from app.models.models import FamilleModel
from app.db.requests import CATEGORY_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_familles() -> Dict[str, Any]:
    """Récupère toutes les familles depuis la base de données."""
    cached = cache.get_data_only("mobile_familles")
    if cached:
        return cached
    
    query = CATEGORY_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            familles = []
            for row in results:
                try:
                    familles.append(FamilleModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping famille: {e}")
                    continue

            response = {"familles": familles, "count": len(familles)}
            cache.set("mobile_familles", response, CACHE_TTL_LONG)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur familles: {e}")
        raise