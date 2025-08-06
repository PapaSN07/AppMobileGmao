from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.models.models import ZoneModel
from app.db.requests import ZONE_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_zones(entity: str) -> Dict[str, Any]:
    """Récupère toutes les zones depuis la base de données."""
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    cache_key = f"mobile_zones_{entity}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached

    # Récupérer la hiérarchie de l'entité
    try:
        hierarchy_result = get_hierarchy(entity)
        hierarchy_entities = hierarchy_result.get('hierarchy', [])
        
        if not hierarchy_entities:
            # Si pas de hiérarchie, utiliser seulement l'entité fournie
            hierarchy_entities = [entity]
            logger.warning(f"Aucune hiérarchie trouvée pour {entity}, utilisation de l'entité seule")
        
        logger.info(f"Hiérarchie pour {entity}: {hierarchy_entities}")
        
    except Exception as e:
        logger.error(f"Erreur récupération hiérarchie pour {entity}: {e}")
        # En cas d'erreur, utiliser seulement l'entité fournie
        hierarchy_entities = [entity]
    
    query = ZONE_QUERY
    params = {}
    
    try:
        with get_database_connection() as db:
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdzo_entity IN ({placeholders})"

            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdzo_entity, mdzo_code"
            
            results = db.execute_query(query, params=params)
            zones = []
            
            for row in results:
                try:
                    zone = ZoneModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    zones.append(zone.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping zone: {e}")
                    continue

            response = {"zones": zones, "count": len(zones)}
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur zones: {e}")
        raise