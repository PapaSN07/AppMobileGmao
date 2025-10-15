from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.unite_model import UniteModel
from app.db.requests import FUNCTION_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_unites(entity: str, hierarchy_result: Dict[str, Any]) -> Dict[str, Any]:
    """Récupère toutes les unités depuis la base de données."""
    
    cache_key = f"mobile_unites_{entity}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # Récupérer la hiérarchie de l'entité
    try:
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
    
    query = FUNCTION_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdfn_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdfn_entity, mdfn_code"

            results = db.execute_query(query, params=params)
            unites = []
            for row in results:
                try:
                    unite = UniteModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    unites.append(unite.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping unité: {e}")
                    continue

            response = {"unites": unites, "count": len(unites)}
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
        
    except Exception as e:
        logger.error(f"❌ Erreur unités: {e}")
        raise