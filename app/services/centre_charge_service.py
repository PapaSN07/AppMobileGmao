from app.db.database import get_database_connection
from app.models.models import CentreChargeModel
from app.core.config import CACHE_TTL_LONG
from app.db.requests import COSTCENTRE_QUERY
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_centre_charges() -> Dict[str, Any]:
    """Récupère toutes les charges de centre depuis la base de données."""
    cached = cache.get_data_only("mobile_centre_charges")
    if cached:
        return cached
    
    query = COSTCENTRE_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            centre_charges = []
            for row in results:
                try:
                    centre_charges.append(CentreChargeModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping charge de centre: {e}")
                    continue

            response = {"centre_charges": centre_charges, "count": len(centre_charges)}
            cache.set("mobile_centre_charges", response, CACHE_TTL_LONG)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur charges de centre: {e}")
        raise