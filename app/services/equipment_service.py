from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.models.models import EquipmentModel
from app.services.famille_service import get_familles
from app.db.requests import (EQUIPMENT_INFINITE_QUERY, EQUIPMENT_BY_ID_QUERY)
from app.core.cache import cache
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

# === FONCTION PRINCIPALE POUR MOBILE ===

def get_equipments_infinite(
    entity: str,
    zone: Optional[str] = None,
    famille: Optional[str] = None,
    search_term: Optional[str] = None
) -> Dict[str, Any]:
    """Infinite scroll optimisé pour mobile avec hiérarchie d'entité obligatoire"""
    
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    # Cache key incluant l'entité
    cache_key = f"mobile_eq_{entity}_{zone}_{famille}_{search_term}"

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
    
    # Query de base avec conditions
    base_query = EQUIPMENT_INFINITE_QUERY
    params = {}
    
    # Filtre par hiérarchie d'entités (OBLIGATOIRE)
    placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
    base_query += f" AND ereq_entity IN ({placeholders})"
    
    for i, entity_code in enumerate(hierarchy_entities):
        params[f'entity_{i}'] = entity_code
    
    # Autres filtres optionnels
    if zone:
        base_query += " AND ereq_zone = :zone"
        params['zone'] = zone
    if famille:
        base_query += " AND ereq_category = :famille" 
        params['famille'] = famille
    if search_term:
        base_query += " AND (LOWER(ereq_code) LIKE LOWER(:search) OR LOWER(ereq_description) LIKE LOWER(:search))"
        params['search'] = f"%{search_term}%"
    
    # Ajouter ORDER BY et la limitation Oracle
    base_query += f" ORDER BY ereq_entity, pk_equipment)"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(base_query, params=params)
            
            equipments = []
            
            for row in results:
                try:
                    equipments.append(EquipmentModel.from_db_row(row))
                except Exception as e:
                    logger.error(f"❌ Erreur mapping: {e}")
                    continue
            
            response = {
                'equipments': equipments,
                'count': len(equipments),
                'entity_hierarchy': {
                    'requested_entity': entity,
                    'hierarchy_used': hierarchy_entities,
                    'hierarchy_count': len(hierarchy_entities)
                }
            }
            
            # Log pour debug
            logger.info(f"✅ Hiérarchie appliquée: {len(hierarchy_entities)} entités")
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur infinite scroll pour {entity}: {e}")
        raise

def get_equipment_by_id(equipment_id: str) -> Optional[Dict[str, Any]]:
    """Détail équipement pour mobile avec feeder corrigé"""
    cache_key = f"mobile_eq_detail_{equipment_id}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = EQUIPMENT_BY_ID_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query, params={'equipment_id': equipment_id})
            
            if not results:
                return None
            
            equipment = EquipmentModel.from_db_row(results[0])
            
            # Format adapté au Flutter
            detail = {
                'id': equipment.id,
                'codeParent': equipment.codeParent,
                'code': equipment.code,
                'famille': equipment.famille,
                'zone': equipment.zone,
                'entity': equipment.entity,
                'unite': equipment.unite,
                'centreCharge': equipment.centreCharge,
                'description': equipment.description,
                'longitude': equipment.longitude or '',
                'latitude': equipment.latitude or '',
                'feeder': equipment.feeder,
                'feederDescription': equipment.feederDescription,
                'attributs': [
                    {'name': 'Tension', 'value': '225kV', 'type': 'string'},
                    {'name': 'Puissance', 'value': '30MVA', 'type': 'string'}
                ]  # À adapter selon vos besoins
            }
            
            cache.set(cache_key, detail, CACHE_TTL_SHORT)
            return detail
            
    except Exception as e:
        logger.error(f"❌ Erreur détail équipement: {e}")
        raise