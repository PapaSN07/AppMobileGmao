from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.models import CentreChargeModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import COSTCENTRE_QUERY
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_centre_charges(entity: str, hierarchy_result: Dict[str, Any], limit: int = 260) -> Dict[str, Any]:
    """Récupère les centres de charge depuis la base de données."""

    cache_key = f"mobile_centre_charges_{entity}"
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
    
    query = COSTCENTRE_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdcc_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdcc_entity, mdcc_code"

            results = executor.execute_query(query, params=params, limit=limit)
            centre_charges = []
            
            for row in results:
                try:
                    centre_charge = CentreChargeModel.from_db_row(row)
                    
                    centre_charges.append(centre_charge.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping centre de charge: {e}")
                    continue

            response = {
                "centre_charges": centre_charges, 
                "count": len(centre_charges),# Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(centre_charges)} centres de charge récupérés")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur centres de charge: {e}")
        raise