from app.db.database import get_database_connection
from app.models.models import EntityModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import (ENTITY_QUERY, HIERARCHIC)
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_entities(entity: str) -> Dict[str, Any]:
    """Récupère les entités depuis la base de données."""
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    # Inclure la limite dans la clé de cache
    cache_key = f"mobile_entities_{entity}"
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
    
    query = ENTITY_QUERY
    params = {}
    
    try:
        with get_database_connection() as db:
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE chen_code IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code
            
            query += f" ORDER BY chen_level, chen_code"

            results = db.execute_query(query, params=params)
            entities = []
            
            for row in results:
                try:
                    entity_model = EntityModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    entities.append(entity_model.to_api_response())
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