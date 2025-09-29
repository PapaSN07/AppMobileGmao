from app.db.sqlalchemy.session import get_main_session, get_temp_session, SQLAlchemyQueryExecutor
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (EquipmentModel, EquipmentWithAttributesBuilder, AttributeValues)
from app.db.requests import (ATTRIBUTE_VALUES_QUERY, CHECK_ATTRIBUTE_EXISTS_QUERY, EQUIPMENT_ADD_QUERY, 
                            EQUIPMENT_ATTRIBUTE_ADD_QUERY, EQUIPMENT_BY_ID_QUERY, EQUIPMENT_INFINITE_QUERY, 
                            EQUIPMENT_LENGTH_ATTRIBUTS_QUERY_DISTINCT, 
                            EQUIPMENT_SPEC_ADD_QUERY, EQUIPMENT_T_SPECIFICATION_CODE_QUERY, FEEDER_QUERY, 
                            UPDATE_EQUIPMENT_ATTRIBUTE_QUERY, EQUIPMENT_ATTRIBUTS_VALUES_QUERY)
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
            for row in results:
                try:
                    # ✅ CORRECTION: Les feeders sont des équipements normaux
                    feeder = EquipmentModel.from_db_row(row)
                    feeders.append(feeder.to_dict())
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
            results = executor.execute_query(EQUIPMENT_ATTRIBUTS_VALUES_QUERY, params={'code': equipment_code})

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


def validate_equipment_for_insertion(equipment: EquipmentModel) -> tuple[bool, str]:
    """
    Valide un équipement avant insertion
    """
    try:
        # Vérifications obligatoires
        if not equipment.code is not None or len(equipment.code.strip()) == 0:
            return False, "Code équipement obligatoire"
        
        if not equipment.famille is not None:
            return False, "Famille équipement obligatoire"
            
        if not equipment.entity is not None:
            return False, "Entité obligatoire"
            
        if not equipment.zone is not None:
            return False, "Zone obligatoire"
        
        # ✅ CORRECTION: Vérifier dans les DEUX bases avec SQLAlchemy
        
        # 1. Vérifier dans la DB principale
        main_exists = False
        try:
            with get_main_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                main_check = executor.execute_query(
                    "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_code = :code", 
                    params={'code': equipment.code}
                )
                main_exists = main_check and main_check[0][0] > 0
        except Exception as e:
            logger.warning(f"Erreur vérification DB principale: {e}")
        
        # 2. Vérifier dans la DB temporaire
        temp_exists = False
        try:
            with get_temp_session() as session:
                executor = SQLAlchemyQueryExecutor(session)
                temp_check = executor.execute_query(
                    "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_code = :code", 
                    params={'code': equipment.code}
                )
                temp_exists = temp_check and temp_check[0][0] > 0
        except Exception as e:
            logger.warning(f"Erreur vérification DB temporaire: {e}")
        
        # ✅ Rejeter si l'équipement existe dans l'une ou l'autre des bases
        if main_exists or temp_exists:
            db_location = "principale" if main_exists else "temporaire"
            return False, f"Un équipement avec le code {equipment.code} existe déjà (DB {db_location})"
        
        return True, "Validation réussie"
        
    except Exception as e:
        logger.error(f"Erreur validation équipement: {e}")
        return False, f"Erreur validation: {str(e)}"


def insert_equipment(equipment: EquipmentModel) -> tuple[bool, Optional[int]]:
    """
    Insère un nouvel équipement en utilisant SQLAlchemy avec requêtes SQL brutes.
    """
    logger.info(f"🔧 Insertion équipement SQLAlchemy: {equipment.code}")
    
    try:
        # Validation préalable
        is_valid, msg = validate_equipment_for_insertion(equipment)
        logger.info(f"Validation équipement avant insertion: {msg}")
        if not is_valid:
            logger.error(f"Validation échouée: {msg}")
            return (False, None)

        # ✅ CORRECTION: Utiliser SQLAlchemy session temporaire
        with get_temp_session() as session:
            executor = SQLAlchemyQueryExecutor(session)
            
            try:
                # 1) Utiliser une séquence Oracle au lieu de COUNT
                equipment_pk = _get_index_sqlalchemy(executor, 
                    "SELECT coswin_seq.NEXTVAL FROM DUAL", 
                    "SELECT COALESCE(MAX(pk_equipment), 0) + 1 FROM coswin.t_equipment"
                )
                
                if equipment_pk is None:
                    return (False, None)
                
                setattr(equipment, 'id', equipment_pk)
                
                # ✅ CORRECTION: Utiliser executor.execute_update au lieu de db.execute_update
                executor.execute_update(EQUIPMENT_ADD_QUERY, params={
                    'id': equipment.id,
                    'code': equipment.code,
                    'bar_code': equipment.code,
                    'description': equipment.description,
                    'category': equipment.famille,
                    'zone': equipment.zone,
                    'entity': equipment.entity,
                    'function': equipment.unite,
                    'costcentre': equipment.centreCharge,
                    'longitude': equipment.longitude,
                    'latitude': equipment.latitude,
                    'feeder': getattr(equipment, 'feeder', None),
                    'creation_date': datetime.now()
                }, commit=False)
                
                logger.info(f"1) Équipement {equipment.id} inséré en base (commit différé)")

                # 2) Récupérer cwsp_code (spec) pour la catégorie
                spec_rows = executor.execute_query(EQUIPMENT_T_SPECIFICATION_CODE_QUERY, 
                                                params={'category': equipment.famille})
                logger.info(f"2) Spécifications trouvées pour la catégorie {equipment.famille}: {len(spec_rows) if spec_rows else 0}")
                
                if not spec_rows:
                    logger.info(f"2) Aucune specification trouvée pour la catégorie {equipment.famille} -> insertion terminée sans specs")
                    # ✅ CORRECTION: commit automatique avec SQLAlchemy session
                    invalidate_equipment_insertion_cache(str(equipment.code), str(equipment.entity), str(equipment.famille))
                    return (True, equipment_pk)
                
                cwsp_code = spec_rows[0][0]

                # 3) INSERT equipment_specs avec PK fiable
                equipment_specs_pk = _get_index_sqlalchemy(executor,
                    "SELECT coswin_eq_specs_seq.NEXTVAL FROM DUAL", 
                    "SELECT COALESCE(MAX(pk_equipment_specs), 0) + 1 FROM coswin.equipment_specs"
                )
                
                if equipment_specs_pk is None:
                    return (False, None)
                
                executor.execute_update(EQUIPMENT_SPEC_ADD_QUERY, params={
                    'id': equipment_specs_pk,
                    'specification': cwsp_code,
                    'equipment': equipment.code,
                    'release_date': datetime.now(),
                    'release_number': 1
                }, commit=False)
                
                logger.info(f"3) equipment_specs inséré pour {equipment.code} et specification {cwsp_code} (commit différé)")

                # 4) Création d'attributs avec dédoublonnage
                attributes = equipment.attributes or []
                logger.info(f"4) Attributs fournis pour insertion: {len(attributes)}")
                
                # Requête corrigée pour éviter les doublons d'index
                attr_rows = executor.execute_query(EQUIPMENT_LENGTH_ATTRIBUTS_QUERY_DISTINCT, 
                                                    params={'category': equipment.famille})
                
                logger.info(f"Index d'attributs disponibles pour la famille {equipment.famille}: {len(attr_rows) if attr_rows else 0}")
                
                if attr_rows:
                    # Créer un mapping strict des valeurs fournies par index
                    provided_values = {}
                    seen_indexes = set()
                    
                    for attr in attributes:
                        try:
                            # Gérer les deux formats possibles (dict ou object)
                            if isinstance(attr, dict):
                                idx = str(attr.get("index", "")).strip()
                                value = attr.get("value")
                            else:
                                idx = str(getattr(attr, "index", "")).strip()
                                value = getattr(attr, "value", None)
                            
                            if idx and idx not in seen_indexes:
                                provided_values[idx] = value
                                seen_indexes.add(idx)
                                logger.debug(f"Valeur mappée pour index {idx}: {value}")
                            elif idx in seen_indexes:
                                logger.warning(f"Index {idx} en doublon ignoré")
                                
                        except Exception as e:
                            logger.error(f"Erreur traitement attribut: {e}")
                            continue
                    
                    # Créer UNE SEULE ligne par index de famille (dédoublonné)
                    created = 0
                    created_indexes = set()
                    
                    for attr_row in attr_rows:
                        try:
                            index_val = str(attr_row[0]).strip()
                            
                            # Vérifier qu'on ne crée pas de doublon
                            if index_val in created_indexes:
                                logger.warning(f"Index {index_val} déjà créé, ignoré")
                                continue
                            
                            # Récupérer la valeur fournie ou None
                            value = provided_values.get(index_val)
                            
                            # Vérifier que l'attribut n'existe pas déjà
                            existing_check = executor.execute_query(CHECK_ATTRIBUTE_EXISTS_QUERY, 
                                                                    params={'commonkey': equipment_specs_pk, 'indx': index_val})
                            
                            if existing_check and existing_check[0][0] > 0:
                                logger.warning(f"Attribut index {index_val} existe déjà pour commonkey {equipment_specs_pk}")
                                continue
                            
                            executor.execute_update(EQUIPMENT_ATTRIBUTE_ADD_QUERY, params={
                                'commonkey': equipment_specs_pk,
                                'indx': index_val,
                                'etat_value': value
                            }, commit=False)
                            
                            created += 1
                            created_indexes.add(index_val)
                            logger.debug(f"Attribut créé: index={index_val}, value={value}")
                            
                        except Exception as e:
                            logger.error(f"Erreur création attribut index {attr_row[0]}: {e}")
                            continue
                    
                    logger.info(f"✅ {created}/{len(attr_rows)} attributs créés pour {equipment.code}")
                else:
                    logger.info(f"Aucun attribut disponible pour la famille {equipment.famille}")
                
                # ✅ CORRECTION: Le commit se fait automatiquement à la fin du context manager

                # Invalider le cache après insertion réussie
                invalidate_equipment_insertion_cache(str(equipment.code), str(equipment.entity), str(equipment.famille))

                logger.info(f"✅ Équipement ID: {equipment_pk} - Code: {equipment.code} inséré avec succès SQLAlchemy")
                return (True, equipment_pk)

            except Exception as e:
                logger.error(f"Erreur lors de l'insertion équipement SQLAlchemy: {e}")
                # ✅ Le rollback se fait automatiquement avec SQLAlchemy session
                return (False, None)

    except Exception as e:
        logger.error(f"insert_equipment SQLAlchemy fatal error: {e}")
        return (False, None)


def _get_index_sqlalchemy(executor: SQLAlchemyQueryExecutor, seq_oracle: str, seq_fallback: str) -> Optional[int]:
    """Récupère le prochain index d'équipement en utilisant SQLAlchemy"""
    try:
        # Essayer d'utiliser une séquence Oracle (plus fiable)
        equipment_pk = executor.execute_scalar(seq_oracle)
        if equipment_pk:
            return int(equipment_pk)
        else:
            # Fallback avec MAX + 1 (plus fiable que COUNT)
            equipment_pk = executor.execute_scalar(seq_fallback)
            return int(equipment_pk) if equipment_pk else None
    except Exception:
        # Si séquence n'existe pas, utiliser MAX + 1
        try:
            equipment_pk = executor.execute_scalar(seq_fallback)
            return int(equipment_pk) if equipment_pk else None
        except Exception as e:
            logger.error(f"Impossible de récupérer pk_equipment: {e}")
            return None