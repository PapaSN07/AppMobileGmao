from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_LONG
from app.db.requests import ENTITY_QUERY
from app.models.models import EntityModel
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_entities() -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    cached = cache.get_data_only("mobile_entities")
    if cached:
        return cached
    
    query = ENTITY_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            
            entities = []
            
            for row in results:
                try:
                    entities.append(EntityModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité: {e}")
                    continue
            
            response = {"entities": entities, "count": len(entities)}
            cache.set("mobile_entities", response, CACHE_TTL_LONG)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
        raise