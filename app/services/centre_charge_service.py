from app.db.database import get_database_connection
from app.models.models import CentreChargeModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import COSTCENTRE_QUERY
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def get_centre_charges(entity: str, limit: int = 260) -> Dict[str, Any]:
    """Récupère les centres de charge depuis la base de données."""
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy

    cache_key = f"mobile_centre_charges_{entity}"
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
    
    query = COSTCENTRE_QUERY
    params = {}
    
    try:
        with get_database_connection() as db:
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdcc_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdcc_entity, mdcc_code"
            
            results = db.execute_query(query, params=params, limit=limit)
            centre_charges = []
            
            for row in results:
                try:
                    centre_charge = CentreChargeModel.from_db_row(row)
                    
                    centre_charges.append(centre_charge.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping centre de charge: {e}")
                    continue

            response = {
                "centre_charges": centre_charges, 
                "count": len(centre_charges),
                "total_available": _get_total_count()  # Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(centre_charges)} centres de charge récupérés")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur centres de charge: {e}")
        raise

def _get_total_count() -> int:
    """Récupère le nombre total de centres de charge"""
    try:
        with get_database_connection() as db:
            result = db.execute_query("SELECT COUNT(*) FROM coswin.costcentre")
            return result[0][0] if result else 0
    except Exception:
        return 0