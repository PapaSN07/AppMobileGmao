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
    limit: int = 20,
    cursor: Optional[str] = None,
    zone: Optional[str] = None,
    famille: Optional[str] = None,
    search_term: Optional[str] = None
) -> Dict[str, Any]:
    """Infinite scroll optimisé pour mobile avec hiérarchie d'entité obligatoire"""
    
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    # Cache key incluant l'entité
    cache_key = f"mobile_eq_{entity}_{cursor}_{limit}_{zone}_{famille}_{search_term}"

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
    
    # Cursor pagination
    if cursor:
        base_query += " AND pk_equipment > :cursor"
        params['cursor'] = cursor
    
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
    base_query += f" ORDER BY ereq_entity, pk_equipment) WHERE ROWNUM <= {limit + 1}"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(base_query, params=params)

            # Vérifier s'il y a plus de données
            has_more = len(results) > limit
            if has_more:
                results = results[:-1]  # Enlever le dernier élément
            
            equipments = []
            next_cursor = None
            
            for row in results:
                try:
                    equipment = EquipmentModel.from_db_row(row)
                    equipments.append(equipment.to_mobile_dict())
                    next_cursor = equipment.id
                except Exception as e:
                    logger.error(f"❌ Erreur mapping: {e}")
                    continue
            
            response = {
                'equipments': equipments,
                'pagination': {
                    'next_cursor': next_cursor if has_more else None,
                    'has_more': has_more,
                    'count': len(equipments),
                    'requested_limit': limit
                },
                'filters_applied': bool(zone or famille or search_term),
                'entity_hierarchy': {
                    'requested_entity': entity,
                    'hierarchy_used': hierarchy_entities,
                    'hierarchy_count': len(hierarchy_entities)
                }
            }
            
            # Log pour debug
            logger.info(f"✅ Infinite scroll pour {entity}: {len(equipments)} équipements récupérés sur {limit} demandés")
            logger.info(f"✅ Hiérarchie appliquée: {len(hierarchy_entities)} entités")
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur infinite scroll pour {entity}: {e}")
        raise

# === DONNÉES DE RÉFÉRENCE SIMPLIFIÉES ===

def get_zones() -> Dict[str, Any]:
    """Liste des zones pour mobile"""
    cached = cache.get_data_only("mobile_zones")
    if cached:
        return cached
    
    query = "SELECT DISTINCT ereq_zone, COUNT(*) as count FROM coswin.t_equipment WHERE ereq_zone IS NOT NULL GROUP BY ereq_zone ORDER BY ereq_zone"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            zones = [{"name": row[0], "count": row[1]} for row in results]
            
            response = {"zones": zones, "count": len(zones)}
            cache.set("mobile_zones", response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur zones: {e}")
        raise

def get_entities() -> Dict[str, Any]:
    """Liste des entités pour mobile"""
    cached = cache.get_data_only("mobile_entities")
    if cached:
        return cached
    
    query = "SELECT DISTINCT ereq_entity, COUNT(*) as count FROM coswin.t_equipment WHERE ereq_entity IS NOT NULL GROUP BY ereq_entity ORDER BY ereq_entity"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query)
            entities = [{"name": row[0], "count": row[1]} for row in results]
            
            response = {"entities": entities, "count": len(entities)}
            cache.set("mobile_entities", response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
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

def get_equipment_stats() -> Dict[str, Any]:
    """Statistiques basiques pour mobile"""
    cached = cache.get_data_only("mobile_stats")
    if cached:
        return cached
    
    queries = {
        'total_count': "SELECT COUNT(*) FROM coswin.t_equipment",
        'with_coordinates': "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_longitude IS NOT NULL AND ereq_latitude IS NOT NULL"
    }
    
    try:
        with get_database_connection() as db:
            stats = {}
            for key, query in queries.items():
                result = db.execute_query(query)
                stats[key] = result[0][0] if result else 0
            
            stats['last_updated'] = db.execute_query("SELECT SYSDATE FROM DUAL")[0][0]
            
            cache.set("mobile_stats", stats, CACHE_TTL_SHORT)
            return stats
            
    except Exception as e:
        logger.error(f"❌ Erreur stats: {e}")
        raise

def refresh_reference_data():
    """Rafraîchir données de référence"""
    try:
        cache.delete("mobile_zones")
        cache.delete("mobile_familles") 
        cache.delete("mobile_entities")
        cache.delete("mobile_stats")
        
        zones = get_zones()
        familles = get_familles()
        entities = get_entities()
        stats = get_equipment_stats()
        
        return {
            'status': 'success',
            'zones_count': zones['count'],
            'familles_count': familles['count'],
            'entities_count': entities['count'],
            'total_equipments': stats['total_count']
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur refresh: {e}")
        return {'status': 'error', 'error': str(e)}