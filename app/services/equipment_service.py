from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (EquipmentModel, FeederModel)
from app.db.requests import (EQUIPMENT_INFINITE_QUERY, EQUIPMENT_BY_ID_QUERY, FEEDER_QUERY)
from app.core.cache import cache
from typing import Dict, Any, Optional
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
                    equipment = EquipmentModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    equipments.append(equipment.to_api_response())
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

def get_equipment_by_id(code: str) -> Optional[Dict[str, Any]]:
    """Détail équipement pour mobile avec feeder corrigé"""
    cache_key = f"mobile_eq_detail_{code}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = EQUIPMENT_BY_ID_QUERY
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(query, params={'code': code})
            
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

def get_feeders(entity: str) -> Dict[str, Any]:
    """Récupère la liste des feeders."""
    # Import local pour éviter les imports circulaires
    from app.services.entity_service import get_hierarchy
    
    cache_key = f"feeders_list_{entity}"
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

    query = FEEDER_QUERY
    params = {}

    try:
        with get_database_connection() as db:
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE ereq_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" AND EREQ_CATEGORY IN ('DEPART30KV', 'DEPART6,6KV')"
            query += f" ORDER BY ereq_code"
            
            results = db.execute_query(query, params=params)

            feeders = []
            for row in results:
                try:
                    feeder = FeederModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    feeders.append(feeder.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping feeder: {e}")
                    continue

            response = {"feeders": feeders, "count": len(feeders)}
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur récupération feeders: {e}")
        raise

def add_equipment(equipment_data: dict) -> bool:
    """
    Ajoute un nouvel équipement dans la base de données.
    Args:
        equipment_data: dict validé par AddEquipmentRequest
    Returns:
        True si succès, False sinon
    """
    try:
        with get_database_connection() as db:
            # Exemple d'insertion, à adapter selon ta table et tes champs
            query = """
                INSERT INTO equipment (
                    ereq_parent_equipment, feeder, feeder_description, ereq_code,
                    ereq_category, ereq_zone, ereq_entity, ereq_unite, ereq_centre_charge,
                    ereq_description, longitude, latitude
                ) VALUES (
                    :code_parent, :feeder, :feeder_description, :code,
                    :famille, :zone, :entity, :unite, :centre_charge,
                    :description, :longitude, :latitude
                )
            """
            params = {
                'code_parent': equipment_data.get('code_parent'),
                'feeder': equipment_data.get('feeder'),
                'feeder_description': equipment_data.get('feeder_description'),
                'code': equipment_data['code'],
                'famille': equipment_data['famille'],
                'zone': equipment_data['zone'],
                'entity': equipment_data['entity'],
                'unite': equipment_data['unite'],
                'centre_charge': equipment_data['centre_charge'],
                'description': equipment_data['description'],
                'longitude': equipment_data.get('longitude'),
                'latitude': equipment_data.get('latitude'),
                'cached_at': equipment_data['cached_at'],
                'is_sync': 1 if equipment_data['is_sync'] else 0
            }
            db.execute_update(query, params=params)
            # Pour les attributs, tu peux ajouter une boucle d'insertion si besoin
            return True
    except Exception as e:
        logger.error(f"Erreur ajout équipement: {e}")
        return False

