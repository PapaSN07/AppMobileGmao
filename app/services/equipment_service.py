from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (EquipmentModel, FeederModel, EquipmentAttributeValueModel, AttributeValuesModel)
from app.db.requests import (ATTRIBUTE_VALUES_QUERY, EQUIPMENT_BY_ID_QUERY, EQUIPMENT_INFINITE_QUERY, FEEDER_QUERY, UPDATE_EQUIPMENT_ATTRIBUTE_QUERY)
from app.core.cache import cache
from typing import Dict, Any, List, Optional
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
    
    from app.services.entity_service import get_hierarchy
    
    cache_key = f"mobile_eq_{entity}_{zone}_{famille}_{search_term}"

    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # Récupérer la hiérarchie de l'entité
    try:
        hierarchy_result = get_hierarchy(entity)
        hierarchy_entities = hierarchy_result.get('hierarchy', [])
        
        if not hierarchy_entities:
            hierarchy_entities = [entity]
            logger.warning(f"Aucune hiérarchie trouvée pour {entity}, utilisation de l'entité seule")
        
        logger.info(f"Hiérarchie pour {entity}: {hierarchy_entities}")
        
    except Exception as e:
        logger.error(f"Erreur récupération hiérarchie pour {entity}: {e}")
        hierarchy_entities = [entity]
    
    # Query de base avec conditions
    base_query = EQUIPMENT_INFINITE_QUERY
    params = {}
    
    # Filtre par hiérarchie d'entités
    placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
    base_query += f" AND e.ereq_entity IN ({placeholders})"
    
    for i, entity_code in enumerate(hierarchy_entities):
        params[f'entity_{i}'] = entity_code
    
    # Autres filtres
    if zone:
        base_query += " AND e.ereq_zone = :zone"
        params['zone'] = zone
    if famille:
        base_query += " AND e.ereq_category = :famille" 
        params['famille'] = famille
    if search_term:
        base_query += " AND (LOWER(e.ereq_code) LIKE LOWER(:search) OR LOWER(e.ereq_description) LIKE LOWER(:search))"
        params['search'] = f"%{search_term}%"
    
    # CORRECTION : ORDER BY avec les bonnes colonnes
    base_query += " ORDER BY e.pk_equipment, attr_name"
    
    try:
        with get_database_connection() as db:
            results = db.execute_query(base_query, params=params)
            
            # CORRECTION : Traitement optimisé avec gestion des 19 colonnes
            equipments_dict = {}
            
            for row in results:
                try:
                    # CORRECTION : Vérifier la longueur de la row
                    if len(row) < 13:
                        logger.warning(f"Row incomplète: {len(row)} colonnes au lieu de 19 minimum")
                        continue
                    
                    # Les 13 premières colonnes sont pour l'équipement
                    equipment_row = row[:13]
                    equipment_id = str(row[0])
                    
                    # Si l'équipement n'existe pas encore, le créer
                    if equipment_id not in equipments_dict:
                        equipment = EquipmentModel.from_db_row(equipment_row)
                        equipment.attributes = []
                        equipments_dict[equipment_id] = equipment
                    
                    # CORRECTION : Ajouter l'attribut si il existe (colonnes 13-17)
                    # Vérifier qu'on a assez de colonnes et que attr_id n'est pas NULL
                    if len(row) >= 18 and row[13] is not None:  # attr_id
                        attr_row = (row[13], row[14], row[15], row[16], row[17])  # id, spec, index, name, value
                        try:
                            attribute = EquipmentAttributeValueModel.from_db_row(attr_row)
                            equipments_dict[equipment_id].attributes.append(attribute)
                        except Exception as e:
                            logger.debug(f"Erreur création attribut pour équipement {equipment_id}: {e}")
                    
                except Exception as e:
                    logger.error(f"❌ Erreur mapping row: {e}")
                    continue
            
            # Convertir en liste et sérialiser
            equipments = [eq.to_api_response() for eq in equipments_dict.values()]
            
            response = {
                'equipments': equipments,
                'count': len(equipments),
                'entity_hierarchy': {
                    'requested_entity': entity,
                    'hierarchy_used': hierarchy_entities,
                    'hierarchy_count': len(hierarchy_entities)
                }
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ Méthode optimisée: {len(equipments)} équipements récupérés en une requête")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur méthode optimisée pour {entity}: {e}")
        raise

def get_attribute_values(specification: str, attribute_index: str) -> List[AttributeValuesModel]:
    """Récupère les valeurs des attributs pour un équipement donné."""
    if not specification or not attribute_index:
        return []

    cache_key = f"attribute_values_{specification}_{attribute_index}"
    cached = cache.get_data_only(cache_key)
    
    if cached:
        try:
            # Reconstruire les objets AttributeValuesModel depuis le cache
            return [AttributeValuesModel(**item) for item in cached]
        except Exception as e:
            logger.debug(f"Erreur reconstruction cache pour {specification}_{attribute_index}: {e}")
            # Si erreur de reconstruction, continuer avec la DB

    try:
        with get_database_connection() as db:
            results = db.execute_query(ATTRIBUTE_VALUES_QUERY, params={'specification': specification, 'attribute_index': attribute_index})

            if not results:
                # Mettre en cache une liste vide pour éviter les requêtes répétées
                cache.set(cache_key, [], CACHE_TTL_SHORT)
                return []

            # Créer les objets EquipmentAttributeValueModel
            attributes = []
            for r in results:
                try:
                    attr = AttributeValuesModel.from_db_row(r)
                    attributes.append(attr)
                except Exception as e:
                    logger.debug(f"Erreur création attribut depuis DB: {e}")
                    continue
            
            # Sérialiser pour le cache
            attributes_serialized = [attr.model_dump() for attr in attributes]
            cache.set(cache_key, attributes_serialized, CACHE_TTL_SHORT)
            
            return attributes

    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs pour {specification}_{attribute_index}: {e}")
        return []

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

def get_equipment_by_id(equipment_id: str) -> Optional[EquipmentModel]:
    """Récupère un équipement par son ID"""
    try:
        with get_database_connection() as db:
            results = db.execute_query(EQUIPMENT_BY_ID_QUERY, params={'equipment_id': equipment_id})
            
            if not results:
                return None
                
            # Créer l'équipement depuis la première row
            equipment = EquipmentModel.from_db_row(results[0])
            
            # Récupérer les attributs séparément
            equipment.attributes = get_equipment_attributes_by_code(equipment.code)
            
            return equipment
            
    except Exception as e:
        logger.error(f"❌ Erreur récupération équipement {equipment_id}: {e}")
        return None

def update_equipment_partial(equipment_id: str, updates: Dict[str, Any]) -> bool:
    """
    Met à jour partiellement un équipement et ses attributs
    
    Args:
        equipment_id: ID de l'équipement à modifier
        updates: Dictionnaire des champs à mettre à jour
        
    Returns:
        True si succès, False sinon
    """
    try:
        # Vérifier que l'équipement existe
        existing_equipment = get_equipment_by_id(equipment_id)
        if not existing_equipment:
            logger.error(f"Équipement {equipment_id} non trouvé")
            return False
            
        with get_database_connection() as db:
            # 1. Mise à jour des champs de base de l'équipement
            equipment_fields = {
                'code_parent', 'code', 'famille', 'zone', 'entity', 
                'unite', 'centre_charge', 'description', 'longitude', 
                'latitude', 'feeder'
            }
            
            # Filtrer les champs d'équipement à mettre à jour
            equipment_updates = {k: v for k, v in updates.items() if k in equipment_fields and v is not None}
            
            if equipment_updates:
                # Construire la requête de mise à jour dynamiquement
                set_clauses = []
                params = {'equipment_id': equipment_id}
                
                field_mapping = {
                    'code_parent': 'ereq_parent_equipment',
                    'code': 'ereq_code',
                    'famille': 'ereq_category',
                    'zone': 'ereq_zone',
                    'entity': 'ereq_entity',
                    'unite': 'ereq_function',
                    'centre_charge': 'ereq_costcentre',
                    'description': 'ereq_description',
                    'longitude': 'ereq_longitude',
                    'latitude': 'ereq_latitude',
                    'feeder': 'ereq_string2'
                }
                
                for field, value in equipment_updates.items():
                    db_field = field_mapping.get(field, field)
                    set_clauses.append(f"{db_field} = :{field}")
                    params[field] = value
                
                if set_clauses:
                    update_query = f"""
                        UPDATE coswin.t_equipment 
                        SET {', '.join(set_clauses)}
                        WHERE pk_equipment = :equipment_id
                    """
                    
                    db.execute_update(update_query, params=params)
                    logger.info(f"✅ Équipement {equipment_id} mis à jour: {list(equipment_updates.keys())}")
            
            # 2. Mise à jour des attributs si fournis
            if 'attributs' in updates and updates['attributs']:
                success = update_equipment_attributes(existing_equipment.code, updates['attributs'])
                if not success:
                    logger.warning(f"Erreur partielle lors de la mise à jour des attributs pour {equipment_id}")
            
            # 3. Invalider le cache
            cache_patterns = [
                f"mobile_eq_*",
                f"equipment_attributes_{existing_equipment.code}",
                f"equipment_*_{equipment_id}"
            ]
            
            for pattern in cache_patterns:
                cache.clear_pattern(pattern)
            
            logger.info(f"✅ Mise à jour complète de l'équipement {equipment_id}")
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur mise à jour équipement {equipment_id}: {e}")
        return False

def update_equipment_attributes(equipment_code: str, attributes: List[Dict[str, Any]]) -> bool:
    """
    Met à jour les attributs d'un équipement
    
    Args:
        equipment_code: Code de l'équipement
        attributes: Liste des attributs à mettre à jour
        
    Returns:
        True si succès, False sinon
    """
    try:
        with get_database_connection() as db:
            success_count = 0
            
            for attr in attributes:
                attr_name = attr.get('name')
                attr_value = str(attr.get('value', ''))
                
                if not attr_name:
                    logger.warning(f"Attribut sans nom ignoré pour {equipment_code}")
                    continue
                
                try:
                    # Essayer de mettre à jour l'attribut existant
                    update_params = {
                        'equipment_code': equipment_code,
                        'attribute_name': attr_name,
                        'value': attr_value
                    }
                    
                    db.execute_update(UPDATE_EQUIPMENT_ATTRIBUTE_QUERY, params=update_params)
                    
                    success_count += 1
                    
                except Exception as e:
                    logger.error(f"Erreur mise à jour attribut {attr_name}: {e}")
                    continue
            
            logger.info(f"✅ {success_count}/{len(attributes)} attributs mis à jour pour {equipment_code}")
            return success_count > 0
            
    except Exception as e:
        logger.error(f"❌ Erreur mise à jour attributs pour {equipment_code}: {e}")
        return False

def get_equipment_attributes_by_code(equipment_code: str) -> List[EquipmentAttributeValueModel]:
    """Récupère les attributs d'un équipement par son code"""
    if not equipment_code:
        return []
        
    cache_key = f"equipment_attributes_{equipment_code}"
    cached = cache.get_data_only(cache_key)
    
    if cached:
        try:
            return [EquipmentAttributeValueModel(**item) for item in cached]
        except Exception as e:
            logger.debug(f"Erreur reconstruction cache pour {equipment_code}: {e}")

    try:
        from app.db.requests import EQUIPMENT_ATTRIBUTS_VALUES_QUERY
        
        with get_database_connection() as db:
            results = db.execute_query(EQUIPMENT_ATTRIBUTS_VALUES_QUERY, params={'code': equipment_code})

            if not results:
                cache.set(cache_key, [], CACHE_TTL_SHORT)
                return []

            attributes = []
            for r in results:
                try:
                    if len(r) >= 5:
                        attr = EquipmentAttributeValueModel.from_db_row(r)
                        attributes.append(attr)
                except Exception as e:
                    logger.debug(f"Erreur création attribut: {e}")
                    continue
            
            attributes_serialized = [attr.model_dump() for attr in attributes]
            cache.set(cache_key, attributes_serialized, CACHE_TTL_SHORT)
            
            return attributes

    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs pour équipement {equipment_code}: {e}")
        return []