from app.db.database import OracleDatabase, get_database_connection, get_database_connection_temp
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (EquipmentModel, FeederModel, EquipmentAttributeValueModel, AttributeValuesModel)
from app.db.requests import (ATTRIBUTE_VALUES_QUERY, CHECK_ATTRIBUTE_EXISTS_QUERY, EQUIPMENT_ADD_QUERY, EQUIPMENT_ATTRIBUTE_ADD_QUERY, EQUIPMENT_BY_ID_QUERY, EQUIPMENT_INFINITE_QUERY, EQUIPMENT_LENGTH_ATTRIBUTS_QUERY, EQUIPMENT_LENGTH_ATTRIBUTS_QUERY_DISTINCT, EQUIPMENT_SPEC_ADD_QUERY, EQUIPMENT_T_SPECIFICATION_CODE_QUERY, FEEDER_QUERY, UPDATE_EQUIPMENT_ATTRIBUTE_QUERY)
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
    
    # CORRECTION : ORDER BY avec les bonnes colonnes
    base_query += " ORDER BY e.pk_equipment DESC"
    
    try:
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        
        with db_conn as db:
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
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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

def get_equipment_by_id(equipment_id: str) -> Optional[EquipmentModel]:
    """Récupère un équipement par son ID"""
    try:
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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
        
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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
        
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")
        with db_conn as db:
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

def get_equipment_attributes_by_code_without_value(equipment_code: str) -> List[EquipmentAttributeValueModel]:
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
        from app.db.requests import EQUIPMENT_CLASSE_ATTRIBUTS_QUERY
        
        db_conn = get_database_connection()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")

        with db_conn as db:
            results = db.execute_query(EQUIPMENT_CLASSE_ATTRIBUTS_QUERY, params={'code': equipment_code})
                        
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

def validate_equipment_for_insertion(equipment: EquipmentModel) -> tuple[bool, str]:
    """
    Valide un équipement avant insertion
    """
    try:
        # Vérifications obligatoires
        if not equipment.code or len(equipment.code.strip()) == 0:
            return False, "Code équipement obligatoire"
        
        if not equipment.famille:
            return False, "Famille équipement obligatoire"
            
        if not equipment.entity:
            return False, "Entité obligatoire"
            
        if not equipment.zone:
            return False, "Zone obligatoire"
        
        # ✅ CORRECTION : Vérifier dans les DEUX bases de données
        
        # 1. Vérifier dans la DB principale
        main_exists = False
        try:
            main_db_conn = get_database_connection()
            if main_db_conn is not None:
                with main_db_conn as db:
                    main_check = db.execute_query(
                        "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_code = :code", 
                        params={'code': equipment.code}
                    )
                    main_exists = main_check and main_check[0][0] > 0
        except Exception as e:
            logger.warning(f"Erreur vérification DB principale: {e}")
        
        # 2. Vérifier dans la DB temporaire
        temp_exists = False
        try:
            temp_db_conn = get_database_connection_temp()
            if temp_db_conn is not None:
                with temp_db_conn as db:
                    temp_check = db.execute_query(
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
    Insère un nouvel équipement en utilisant les méthodes existantes de la couche DB.
    """
    logger.info(f"🔧 Insertion équipement: {equipment.code}")
    
    try:
        # Validation préalable
        is_valid, msg = validate_equipment_for_insertion(equipment)
        logger.info(f"Validation équipement avant insertion: {msg}")
        if not is_valid:
            logger.error(f"Validation échouée: {msg}")
            return (False, None)

        db_conn = get_database_connection_temp()
        if db_conn is None:
            logger.error("Impossible d'obtenir une connexion à la base de données")
            raise Exception("Connexion DB manquante")

        with db_conn as db:
            try:
                # Démarrer transaction si disponible
                if hasattr(db, "begin_transaction"):
                    try:
                        logger.info("Démarrage d'une transaction explicite")
                        db.begin_transaction()
                    except Exception:
                        logger.debug("begin_transaction non opérationnel, continuation sans appel explicite")

                # 1) ✅ CORRECTION: Utiliser une séquence Oracle au lieu de COUNT
                equipment_pk = _get_index(db, "SELECT coswin_seq.NEXTVAL FROM DUAL", "SELECT COALESCE(MAX(pk_equipment), 0) + 1 FROM coswin.t_equipment")[1]
                
                equipment.id = str(equipment_pk)
                
                db.execute_update(EQUIPMENT_ADD_QUERY, params={
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
                spec_rows = db.execute_query(EQUIPMENT_T_SPECIFICATION_CODE_QUERY, params={'category': equipment.famille})
                logger.info(f"2) Spécifications trouvées pour la catégorie {equipment.famille}: {len(spec_rows) if spec_rows else 0}")
                
                if not spec_rows:
                    logger.info(f"2) Aucune specification trouvée pour la catégorie {equipment.famille} -> insertion terminée sans specs")
                    if hasattr(db, "commit_transaction"):
                        db.commit_transaction()
                    # ✅ CORRECTION: Invalider le cache après insertion
                    invalidate_equipment_insertion_cache(equipment.code, equipment.entity, equipment.famille)
                    return (True, equipment_pk)
                
                cwsp_code = spec_rows[0][0]

                # 3) INSERT equipment_specs avec PK fiable
                equipment_specs_pk = _get_index(db, "SELECT coswin_eq_specs_seq.NEXTVAL FROM DUAL", "SELECT COALESCE(MAX(pk_equipment_specs), 0) + 1 FROM coswin.equipment_specs")[1]
                
                db.execute_update(EQUIPMENT_SPEC_ADD_QUERY, params={
                    'id': equipment_specs_pk,
                    'specification': cwsp_code,
                    'equipment': equipment.code,
                    'release_date': datetime.now(),
                    'release_number': 1
                }, commit=False)
                logger.info(f"3) equipment_specs inséré pour {equipment.code} et specification {cwsp_code} (commit différé)")

                # 4) ✅ CORRECTION: Création d'attributs avec dédoublonnage
                attributes = equipment.attributes or []
                logger.info(f"4) Attributs fournis pour insertion: {len(attributes)}")
                
                # ✅ Requête corrigée pour éviter les doublons d'index
                attr_rows = db.execute_query(EQUIPMENT_LENGTH_ATTRIBUTS_QUERY_DISTINCT, params={'category': equipment.famille})
                
                logger.info(f"Index d'attributs disponibles pour la famille {equipment.famille}: {len(attr_rows) if attr_rows else 0}")
                
                if attr_rows:
                    # ✅ Créer un mapping strict des valeurs fournies par index
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
                    
                    # ✅ Créer UNE SEULE ligne par index de famille (dédoublonné)
                    created = 0
                    created_indexes = set()
                    
                    for attr_row in attr_rows:
                        try:
                            index_val = str(attr_row[0]).strip()
                            
                            # ✅ Vérifier qu'on ne crée pas de doublon
                            if index_val in created_indexes:
                                logger.warning(f"Index {index_val} déjà créé, ignoré")
                                continue
                            
                            # Récupérer la valeur fournie ou None
                            value = provided_values.get(index_val)
                            
                            # ✅ Vérifier que l'attribut n'existe pas déjà
                            existing_check = db.execute_query(CHECK_ATTRIBUTE_EXISTS_QUERY, params={'commonkey': equipment_specs_pk, 'indx': index_val})
                            
                            if existing_check and existing_check[0][0] > 0:
                                logger.warning(f"Attribut index {index_val} existe déjà pour commonkey {equipment_specs_pk}")
                                continue
                            
                            db.execute_update(EQUIPMENT_ATTRIBUTE_ADD_QUERY, params={
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
                
                # Commit de la transaction
                if hasattr(db, "commit_transaction"):
                    db.commit_transaction()
                    logger.info("Transaction commitée avec succès")

                # ✅ CORRECTION: Invalider le cache après insertion réussie
                invalidate_equipment_insertion_cache(equipment.code, equipment.entity, equipment.famille)

                logger.info(f"✅ Équipement ID: {equipment_pk} - Code: {equipment.code} inséré avec succès")
                return (True, equipment_pk)

            except Exception as e:
                logger.error(f"Erreur lors de l'insertion équipement: {e}")
                try:
                    if hasattr(db, "rollback_transaction"):
                        db.rollback_transaction()
                except Exception:
                    logger.debug("Rollback non disponible ou a échoué")
                return (False, None)

    except Exception as e:
        logger.error(f"insert_equipment fatal error: {e}")
        return (False, None)

def _get_index(db: OracleDatabase, seq_oracle: str, seq_fallback: str) -> tuple[bool, Optional[int]]:
    """Récupère le prochain index d'équipement en utilisant une séquence ou MAX + 1"""
    equipment_pk = None
    try:
        # Essayer d'utiliser une séquence Oracle (plus fiable)
        pk_rows = db.execute_query(seq_oracle)
        if pk_rows:
            equipment_pk = pk_rows[0][0]
        else:
            # Fallback avec MAX + 1 (plus fiable que COUNT)
            pk_rows = db.execute_query(seq_fallback)
            equipment_pk = pk_rows[0][0]
    except Exception:
        # Si séquence n'existe pas, utiliser MAX + 1
        pk_rows = db.execute_query(seq_fallback)
        if not pk_rows:
            logger.error("Impossible de récupérer pk_equipment")
            if hasattr(db, "rollback_transaction"):
                db.rollback_transaction()
            return (False, None)
        equipment_pk = pk_rows[0][0]

    return (True, equipment_pk)