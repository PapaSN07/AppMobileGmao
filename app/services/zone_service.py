from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.models.models import ZoneModel
from app.db.requests import ZONE_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_zones() -> Dict[str, Any]:
    """Récupère toutes les zones depuis la base de données."""
    cached = cache.get_data_only("mobile_zones")
    if cached:
        return cached
    
    query = ZONE_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            zones = []
            for row in results:
                try:
                    zones.append(ZoneModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping zone: {e}")
                    continue

            response = {"zones": zones, "count": len(zones)}
            cache.set("mobile_zones", response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur zones: {e}")
        raise