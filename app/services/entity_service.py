from app.db.database import get_database_connection
from app.models.models import EntityModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import (ENTITY_QUERY, HIERARCHIC)
from app.core.cache import cache
from typing import Any, Dict, List
import logging

logger = logging.getLogger(__name__)

def get_entities(limit: int = 20, code: str = 'SDDV') -> Dict[str, Any]:
    """Récupère les entités depuis la base de données."""
    # Inclure la limite dans la clé de cache
    cache_key = f"mobile_entities_{limit}_{code}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = ENTITY_QUERY
    hierarchy = get_hierarchy(code).get('hierarchy', [])
    if hierarchy:
        placeholders = ','.join([f"'{h}'" for h in hierarchy])
    
    try:
        with get_database_connection() as db:
            # Appliquer la limite dans la requête SQL
            limited_query = f"""
            SELECT * FROM (
                {query}
            ) WHERE ROWNUM <= {limit}
            """
            
            results = db.execute_query(limited_query, {'placeholders': placeholders} if hierarchy else {})
            entities = []
            
            for row in results:
                try:
                    entity = EntityModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    entities.append(entity.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité: {e}")
                    continue

            response = {
                "entities": entities, 
                "count": len(entities),
                "total_available": _get_total_count()  # Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(entities)} entités récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
        raise

def get_hierarchy(entity_code: str) -> Dict[str, Any]:
    """Utilise la fonction Oracle sn_hierarchie pour récupérer la hiérarchie."""
    cache_key = f"entity_hierarchy_oracle_{entity_code}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    try:
        with get_database_connection() as db:
            # Appel direct de votre fonction Oracle
            results = db.execute_query(HIERARCHIC, {'entity': entity_code})
            
            if not results:
                return {
                    "entity_code": entity_code,
                    "hierarchy": [],
                    "count": 0,
                    "message": f"Aucune hiérarchie trouvée pour l'entité {entity_code}"
                }
            
            # Récupérer les détails complets pour chaque code retourné
            hierarchy = [row[0] for row in results]

            response = {
                "entity_code": entity_code,
                "hierarchy": hierarchy,
                "count": len(hierarchy),
                "generated_by": "oracle_function_sn_hierarchie"
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ Hiérarchie Oracle de {entity_code}: {len(hierarchy)} niveaux")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur hiérarchie Oracle: {e}")
        raise

def _get_total_count() -> int:
    """Récupère le nombre total d'entités"""
    try:
        with get_database_connection() as db:
            result = db.execute_query("SELECT COUNT(*) FROM coswin.entity")
            return result[0][0] if result else 0
    except Exception:
        return 0