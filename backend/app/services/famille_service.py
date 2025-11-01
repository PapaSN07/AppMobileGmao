from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.famille_model import FamilleModel
from app.db.requests import CATEGORY_QUERY
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_familles(entity: str, hierarchy_result: Dict[str, Any]) -> Dict[str, Any]:
    """Récupère toutes les familles depuis la base de données."""
    
    cached = cache.get_data_only("mobile_familles")
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
    
    query = CATEGORY_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            hierarchy_entities.append('INFO_PARTAGEE') # Ajout de l'entité partagée
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdct_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdct_level, mdct_code"

            results = db.execute_query(query, params=params)
            familles = []
            for row in results:
                try:
                    famille = FamilleModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    familles.append(famille.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping famille: {e}")
                    continue

            response = {"familles": familles, "count": len(familles)}
            cache.set("mobile_familles", response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur familles: {e}")
        raise