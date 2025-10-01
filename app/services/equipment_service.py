from sqlalchemy import cast
from app.db.sqlalchemy.session import get_main_session, get_temp_session, SQLAlchemyQueryExecutor
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (AttributeCliClac, EquipmentCliClac, EquipmentModel, EquipmentWithAttributesBuilder, AttributeValues)
from app.db.requests import (ATTRIBUTE_VALUES_QUERY, EQUIPMENT_BY_ID_QUERY, EQUIPMENT_CLASSE_ATTRIBUTS_QUERY, EQUIPMENT_INFINITE_QUERY, FEEDER_QUERY, 
                            UPDATE_EQUIPMENT_ATTRIBUTE_QUERY)
from app.core.cache import cache, invalidate_equipment_insertion_cache
from typing import Dict, Any, List, Optional
import logging
from datetime import datetime

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
    
    # ORDER BY avec les bonnes colonnes
    base_query += " ORDER BY e.pk_equipment DESC"
    
    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session au lieu de l'ancienne DB
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            results = executor.execute_query(base_query, params=params)
            
            # ✅ CORRECTION: Utiliser le builder pour construire les équipements
            equipments = EquipmentWithAttributesBuilder.build_from_query_results(results)
            
            # Convertir en format API
            equipments_api = [eq.to_dict() for eq in equipments]
            
            response = {
                'equipments': equipments_api,
                'count': len(equipments_api),
                'entity_hierarchy': {
                    'requested_entity': entity,
                    'hierarchy_used': hierarchy_entities,
                    'hierarchy_count': len(hierarchy_entities)
                }
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ SQLAlchemy méthode: {len(equipments_api)} équipements récupérés en une requête")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur SQLAlchemy pour {entity}: {e}")
        raise


def get_attribute_values(specification: str, attribute_index: str) -> List[AttributeValues]:
    """Récupère les valeurs des attributs pour un équipement donné."""
    if not specification or not attribute_index:
        return []

    cache_key = f"attribute_values_{specification}_{attribute_index}"
    cached = cache.get_data_only(cache_key)
    
    if cached:
        try:
            # ✅ CORRECTION: Utiliser le bon modèle
            return [AttributeValues(**item) for item in cached]
        except Exception as e:
            logger.debug(f"Erreur reconstruction cache pour {specification}_{attribute_index}: {e}")

    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            results = executor.execute_query(ATTRIBUTE_VALUES_QUERY, params={
                'specification': specification, 
                'attribute_index': attribute_index
            })

            if not results:
                cache.set(cache_key, [], CACHE_TTL_SHORT)
                return []

            # ✅ CORRECTION: Créer les objets AttributeValues
            attributes = []
            for r in results:
                try:
                    attr = AttributeValues.from_db_row(r)
                    attributes.append(attr)
                except Exception as e:
                    logger.debug(f"Erreur création attribut depuis DB: {e}")
                    continue
            
            # Sérialiser pour le cache
            attributes_serialized = [attr.to_dict() for attr in attributes]
            cache.set(cache_key, attributes_serialized, CACHE_TTL_SHORT)
            
            return attributes

    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs pour {specification}_{attribute_index}: {e}")
        return []


def get_feeders(entity: str, hierarchy_result: Dict[str, Any]) -> Dict[str, Any]:
    """Récupère la liste des feeders."""
    
    cache_key = f"feeders_list_{entity}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # Récupérer la hiérarchie de l'entité
    try:
        hierarchy_entities = hierarchy_result.get('hierarchy', [])
        
        if not hierarchy_entities:
            hierarchy_entities = [entity]
            logger.warning(f"Aucune hiérarchie trouvée pour {entity}, utilisation de l'entité seule")
        
        logger.info(f"Hiérarchie pour {entity}: {hierarchy_entities}")
        
    except Exception as e:
        logger.error(f"Erreur récupération hiérarchie pour {entity}: {e}")
        hierarchy_entities = [entity]

    query = FEEDER_QUERY
    params = {}

    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE ereq_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" AND EREQ_CATEGORY IN ('DEPART30KV', 'DEPART6,6KV')"
            query += f" ORDER BY ereq_code"
            
            results = executor.execute_query(query, params=params)

            feeders = []
            for feeder_row in results:
                try:
                    # ✅ CORRECTION: Créer un dictionnaire au lieu d'un objet EquipmentModel
                    feeder_dict = {
                        'id': int(feeder_row[0]) if feeder_row[0] is not None else None,
                        'code': str(feeder_row[1]) if feeder_row[1] is not None else "",
                        'description': str(feeder_row[2]) if feeder_row[2] is not None else "",
                        'entity': str(feeder_row[3]) if feeder_row[3] is not None else ""
                    }
                    
                    feeders.append(feeder_dict)
                    logger.debug(f"Feeder ajouté: {feeder_dict['code']}")
                except Exception as e:
                    logger.error(f"❌ Erreur mapping feeder: {e}")
                    continue

            response = {"feeders": feeders, "count": len(feeders)}
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur récupération feeders: {e}")
        raise


def get_equipment_by_id(equipment_id: str) -> Optional[EquipmentModel]:
    """Récupère un équipement par son ID"""
    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            results = executor.execute_query(EQUIPMENT_BY_ID_QUERY, params={'equipment_id': equipment_id})
            
            if not results:
                return None
                
            # ✅ CORRECTION: Utiliser le builder pour un seul équipement
            equipment = EquipmentWithAttributesBuilder.build_single_from_query_results(results)
            
            return equipment
            
    except Exception as e:
        logger.error(f"❌ Erreur récupération équipement {equipment_id}: {e}")
        return None


def update_equipment_partial(equipment_id: str, updates: Dict[str, Any]) -> bool:
    """
    Met à jour partiellement un équipement et ses attributs
    """
    try:
        # Vérifier que l'équipement existe
        existing_equipment = get_equipment_by_id(equipment_id)
        if not existing_equipment:
            logger.error(f"Équipement {equipment_id} non trouvé")
            return False
        
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            
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
                    
                    executor.execute_update(update_query, params=params)
                    logger.info(f"✅ Équipement {equipment_id} mis à jour: {list(equipment_updates.keys())}")
            
            # 2. Mise à jour des attributs si fournis
            if 'attributs' in updates and updates['attributs']:
                success = update_equipment_attributes(getattr(existing_equipment, 'code', ''), updates['attributs'])
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
    """
    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            success_count = 0
            
            for attr in attributes:
                attr_name = attr.get('name', '')
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
                    
                    executor.execute_update(UPDATE_EQUIPMENT_ATTRIBUTE_QUERY, params=update_params)
                    success_count += 1
                    
                except Exception as e:
                    logger.error(f"Erreur mise à jour attribut {attr_name}: {e}")
                    continue
            
            logger.info(f"✅ {success_count}/{len(attributes)} attributs mis à jour pour {equipment_code}")
            return success_count > 0
            
    except Exception as e:
        logger.error(f"❌ Erreur mise à jour attributs pour {equipment_code}: {e}")
        return False


def get_equipment_attributes_by_code(equipment_code: str) -> List[Dict[str, Any]]:
    """Récupère les attributs d'un équipement par son code"""
    if not equipment_code:
        return []
        
    cache_key = f"equipment_attributes_{equipment_code}"
    cached = cache.get_data_only(cache_key)
    
    if cached:
        return cached

    try:
        # ✅ CORRECTION: Utiliser SQLAlchemy session
        with get_main_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            results = executor.execute_query(EQUIPMENT_CLASSE_ATTRIBUTS_QUERY, params={'code': equipment_code})

            if not results:
                cache.set(cache_key, [], CACHE_TTL_SHORT)
                return []

            attributes = []
            for r in results:
                try:
                    if len(r) >= 5:
                        # ✅ CORRECTION: Créer des dictionnaires simples au lieu d'objets
                        attr_dict = {
                            'id': str(r[0]) if r[0] else None,
                            'specification': r[1],
                            'index': r[2],
                            'name': r[3],
                            'value': r[4]
                        }
                        attributes.append(attr_dict)
                except Exception as e:
                    logger.debug(f"Erreur création attribut: {e}")
                    continue
            
            cache.set(cache_key, attributes, CACHE_TTL_SHORT)
            return attributes

    except Exception as e:
        logger.error(f"❌ Erreur récupération attributs pour équipement {equipment_code}: {e}")
        return []


def insert_equipment(equipment: EquipmentCliClac) -> tuple[bool, Optional[int]]:
    """
    Insère un nouvel équipement dans la DB temporaire MSSQL (CliClac).
    Structure différente : utilise EquipmentCliClac et AttributeCliClac
    """
    logger.info(f"🔧 Insertion équipement CliClac MSSQL: {equipment.code}")
    
    try:
        # Validation préalable
        if equipment.code is None or equipment.code.strip() == "":
            logger.error("Code équipement obligatoire")
            return (False, None)
        
        if equipment.famille is None or equipment.famille.strip() == "":
            logger.error("Famille équipement obligatoire")
            return (False, None)

        # Utiliser SQLAlchemy session temporaire (MSSQL)
        with get_temp_session() as session:
            try:
                # 1) Vérifier que l'équipement n'existe pas déjà
                existing_equipment = session.query(EquipmentCliClac).filter_by(
                    code=equipment.code
                ).first()
                
                if existing_equipment:
                    logger.error(f"Équipement avec le code {equipment.code} existe déjà")
                    return (False, None)

                # 2) Créer l'équipement CliClac
                new_equipment = EquipmentCliClac(
                    code=equipment.code,
                    code_parent=equipment.code_parent,
                    famille=equipment.famille,
                    zone=equipment.zone,
                    entity=equipment.entity,
                    unite=equipment.unite,
                    centre_charge=equipment.centre_charge,
                    description=equipment.description,
                    longitude=str(equipment.longitude),
                    latitude=str(equipment.latitude),
                    feeder=equipment.feeder,
                    feeder_description=equipment.feeder_description,
                    info=equipment.info,
                    etat=equipment.etat,
                    type=equipment.type,
                    localisation=equipment.localisation,
                    niveau=equipment.niveau,
                    n_serie=equipment.n_serie,
                    created_by=equipment.created_by,
                    judged_by=equipment.judged_by,
                    is_update=equipment.is_update,
                    is_new=equipment.is_new,
                    is_approved=equipment.is_approved
                )
                
                session.add(new_equipment)
                session.flush()  # Pour obtenir l'ID auto-généré

                # ✅ CORRECTION: Utiliser l'attribut .code au lieu de ['code']
                equipment_id = int(new_equipment.id) if new_equipment.id is not None else None # type: ignore
                logger.info(f"1) Équipement {equipment_id} - {new_equipment.code} inséré")

                # 3) Créer les attributs si fournis
                attributes_data = equipment.attributes
                created_attributes = 0
                
                if attributes_data:
                    for attr_data in attributes_data:
                        try:
                            # ✅ CORRECTION: Utiliser 'attribute_name' au lieu de 'name'
                            new_attribute = AttributeCliClac(
                                specification=attr_data.get('specification', ''),
                                famille=equipment.famille,
                                indx=int(attr_data.get('index', 0)),  # ✅ 'index' depuis le request
                                attribute_name=attr_data.get('name', ''),  # ✅ 'name' depuis le request
                                value=str(attr_data.get('value', '')) if attr_data.get('value') is not None else None,
                                code=equipment.code,
                                description=attr_data.get('description') or equipment.description,
                                is_copy_ot=attr_data.get('is_copy_ot', False)
                            )
                            
                            session.add(new_attribute)
                            created_attributes += 1
                            logger.debug(f"Attribut créé: {attr_data.get('name')} = {attr_data.get('value')}")
                            
                        except Exception as e:
                            logger.error(f"Erreur création attribut {attr_data.get('name', 'N/A')}: {e}")
                            continue

                # 4) Commit final
                session.commit()
                # ✅ CORRECTION: Utiliser equipment.code au lieu de equipment['code']
                logger.info(f"✅ Équipement CliClac ID: {equipment_id} - Code: {equipment.code} inséré avec succès")
                logger.info(f"✅ {created_attributes} attributs créés")

                # Invalider le cache
                invalidate_equipment_insertion_cache(
                    str(equipment.code), 
                    str(equipment.entity), 
                    str(equipment.famille)
                )

                return (True, equipment_id)

            except Exception as e:
                logger.error(f"Erreur lors de l'insertion équipement CliClac: {e}")
                session.rollback()
                return (False, None)

    except Exception as e:
        logger.error(f"insert_equipment fatal error: {e}")
        return (False, None)