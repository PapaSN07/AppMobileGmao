from app.db.database import get_database_connection
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (EquipmentModel, FeederModel, EquipmentAttributeValueModel)
from app.db.requests import (EQUIPMENT_ATTRIBUTS_VALUES_QUERY, EQUIPMENT_INFINITE_QUERY, FEEDER_QUERY)
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

def get_attributes_value(code: str) -> List[EquipmentAttributeValueModel]:
    """Récupère les valeurs des attributs pour un équipement donné."""
    if not code:
        return []
        
    cache_key = f"equipment_attributes_{code}"
    cached = cache.get_data_only(cache_key)
    
    if cached:
        try:
            # Reconstruire les objets EquipmentAttributeValueModel depuis le cache
            return [EquipmentAttributeValueModel(**item) for item in cached]
        except Exception as e:
            logger.debug(f"Erreur reconstruction cache pour {code}: {e}")
            # Si erreur de reconstruction, continuer avec la DB

    try:
        with get_database_connection() as db:
            results = db.execute_query(EQUIPMENT_ATTRIBUTS_VALUES_QUERY, params={'code': code})
            
            if not results:
                # Mettre en cache une liste vide pour éviter les requêtes répétées
                cache.set(cache_key, [], CACHE_TTL_SHORT)
                return []

            # Créer les objets EquipmentAttributeValueModel
            attributes = []
            for r in results:
                try:
                    attr = EquipmentAttributeValueModel.from_db_row(r)
                    attributes.append(attr)
                except Exception as e:
                    logger.debug(f"Erreur création attribut depuis DB: {e}")
                    continue
            
            # Sérialiser pour le cache
            attributes_serialized = [attr.model_dump() for attr in attributes]
            cache.set(cache_key, attributes_serialized, CACHE_TTL_SHORT)
            
            return attributes

    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs pour {code}: {e}")
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

