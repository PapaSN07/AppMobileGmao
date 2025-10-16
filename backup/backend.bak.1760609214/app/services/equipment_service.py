from sqlalchemy import cast
from app.db.sqlalchemy.session import get_main_session, get_temp_session, SQLAlchemyQueryExecutor
from app.core.config import CACHE_TTL_SHORT
from app.models.models import (AttributeClicClac, EquipmentClicClac, EquipmentModel, EquipmentWithAttributesBuilder, AttributeValues, HistoryAttributeClicClac, HistoryEquipmentClicClac)
from app.db.requests import (ATTRIBUTE_VALUES_QUERY, EQUIPMENT_BY_ID_QUERY, EQUIPMENT_CLASSE_ATTRIBUTS_QUERY, EQUIPMENT_INFINITE_QUERY, FEEDER_QUERY)
from app.core.cache import cache, invalidate_equipment_insertion_cache
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


def update_equipment_partial(equipment_id: str, updates: Dict[str, Any]) -> tuple[bool, Optional[int]]:
    """
    Crée un nouvel équipement dans la DB temporaire MSSQL (ClicClac) avec les mises à jour fournies.
    S'inspire de insert_equipment pour utiliser EquipmentClicClac et AttributeClicClac.
    """
    logger.info(f"🔧 Création équipement mis à jour ClicClac MSSQL depuis {equipment_id}")

    try:
        # Validation préalable : vérifier que les champs essentiels sont présents dans updates
        if not updates.get('code'):
            logger.error("Code équipement obligatoire dans les mises à jour")
            return (False, None)
        
        if not updates.get('famille'):
            logger.error("Famille équipement obligatoire dans les mises à jour")
            return (False, None)

        # Utiliser SQLAlchemy session temporaire (MSSQL)
        with get_temp_session() as session:
            try:
                # 1) Vérifier que l'équipement n'existe pas déjà dans ClicClac (par code)
                existing_equipment = session.query(EquipmentClicClac).filter_by(
                    code=updates['code']
                ).first()
                
                if existing_equipment:
                    logger.error(f"Équipement avec le code {updates['code']} existe déjà dans ClicClac")
                    return (False, None)

                # 2) Créer l'équipement ClicClac avec les données mises à jour
                new_equipment = EquipmentClicClac(
                    code=updates.get('code', ''),
                    code_parent=updates.get('code_parent', ''),
                    famille=updates.get('famille', ''),
                    zone=updates.get('zone', ''),
                    entity=updates.get('entity', ''),
                    unite=updates.get('unite', ''),
                    centre_charge=updates.get('centre_charge', ''),
                    description=updates.get('description', ''),
                    longitude=str(updates.get('longitude')) if updates.get('longitude') else None,
                    latitude=str(updates.get('latitude')) if updates.get('latitude') else None,
                    feeder=updates.get('feeder', ''),
                    feeder_description=updates.get('feeder_description', ''),
                    info=updates.get('info', ''),
                    etat=updates.get('etat', 'NORMAL'),
                    type=updates.get('type', '0. Technique'),
                    localisation=updates.get('localisation', ''),
                    niveau=updates.get('niveau', 1),
                    n_serie=updates.get('n_serie', ''),
                    created_by=updates.get('created_by', ''),
                    judged_by=updates.get('judged_by', ''),
                    is_update=True,  # Marquer comme mise à jour
                    is_new=False,
                    is_approved=updates.get('is_approved', False)
                )
                
                session.add(new_equipment)
                session.flush()  # Pour obtenir l'ID auto-généré

                equipment_id_new = int(new_equipment.id) if new_equipment.id is not None else None # type: ignore
                logger.info(f"1) Équipement mis à jour {equipment_id_new} - {new_equipment.code} créé dans ClicClac")

                # 3) Créer les attributs si fournis dans updates
                attributes_data = updates.get('attributs', [])
                created_attributes = 0
                
                if attributes_data:
                    for attr_data in attributes_data:
                        try:
                            new_attribute = AttributeClicClac(
                                specification=attr_data.get('specification', ''),
                                famille=updates['famille'],
                                indx=int(attr_data.get('index', 0)),
                                attribute_name=attr_data.get('name', ''),
                                value=str(attr_data.get('value', '')) if attr_data.get('value') is not None else None,
                                code=updates['code'],
                                description=attr_data.get('description') or updates.get('description'),
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
                logger.info(f"✅ Équipement mis à jour ClicClac ID: {equipment_id_new} - Code: {updates['code']} créé avec succès")
                logger.info(f"✅ {created_attributes} attributs créés")

                # Invalider le cache (si applicable pour ClicClac)
                invalidate_equipment_insertion_cache(
                    str(updates['code']), 
                    str(updates.get('entity', '')), 
                    str(updates.get('famille', ''))
                )

                return (True, equipment_id_new)

            except Exception as e:
                logger.error(f"Erreur lors de la création équipement mis à jour ClicClac: {e}")
                session.rollback()
                return (False, None)

    except Exception as e:
        logger.error(f"update_equipment_partial fatal error: {e}")
        return (False, None)


def update_equipment_existing(equipment_id: str, updates: Dict[str, Any]) -> tuple[bool, Optional[str]]:
    """
    Met à jour un équipement existant dans la DB temporaire MSSQL (ClicClac) avec PATCH.
    Ne change que les champs qui ont réellement changé.
    Met à jour les attributs fournis (liste complète supposée).
    """
    logger.info(f"🔧 Mise à jour PATCH équipement ClicClac MSSQL ID: {equipment_id}")

    try:
        # Utiliser SQLAlchemy session temporaire (MSSQL)
        with get_temp_session() as session:
            # 1) Récupérer l'équipement existant
            existing_equipment = session.query(EquipmentClicClac).filter(EquipmentClicClac.id == equipment_id).first()
            
            if not existing_equipment:
                logger.error(f"Équipement avec ID {equipment_id} introuvable dans ClicClac")
                return (False, "Équipement introuvable")

            # 2) Mapper les clés camelCase vers snake_case pour correspondre au modèle
            field_mapping = {
                'centreCharge': 'centre_charge',
                'feederDescription': 'feeder_description',
                'codeParent': 'code_parent',
                'createdAt': 'created_at',
                'updatedAt': 'updated_at',
                'createdBy': 'created_by',
                'judgedBy': 'judged_by',
                'isUpdate': 'is_update',
                'isNew': 'is_new',
                'isApproved': 'is_approved',
                'isRejected': 'is_rejected',
            }
            
            # 3) Mettre à jour seulement les champs qui ont changé
            updated_fields = []
            for camel_key, snake_key in field_mapping.items():
                if camel_key in updates and hasattr(existing_equipment, snake_key):
                    new_value = updates[camel_key]
                    current_value = getattr(existing_equipment, snake_key)
                    if current_value != new_value:  # Comparaison simple (None-safe)
                        setattr(existing_equipment, snake_key, new_value)
                        updated_fields.append(snake_key)
                        logger.debug(f"Champ {snake_key} mis à jour: {current_value} -> {new_value}")
            
            # Champs sans mapping (famille, unite, etc.)
            direct_fields = ['famille', 'unite', 'zone', 'entity', 'feeder', 'localisation', 'code', 'description', 'commentaire']
            for field in direct_fields:
                if field in updates and hasattr(existing_equipment, field):
                    new_value = updates[field]
                    current_value = getattr(existing_equipment, field)
                    if current_value != new_value:
                        setattr(existing_equipment, field, new_value)
                        updated_fields.append(field)
                        logger.debug(f"Champ {field} mis à jour: {current_value} -> {new_value}")

            # 4) Mettre à jour les attributs (supposer liste complète)
            attributes_data = updates.get('attributes', [])
            if attributes_data:
                # Supprimer les anciens attributs pour cet équipement (pour simplifier, ou comparer IDs)
                session.query(AttributeClicClac).filter(AttributeClicClac.code == existing_equipment.code).delete()
                
                # Ajouter les nouveaux attributs
                for attr_data in attributes_data:
                    try:
                        new_attribute = AttributeClicClac(
                            specification=attr_data.get('specification', ''),
                            famille=existing_equipment.famille,
                            indx=int(attr_data.get('indx', 0)),
                            attribute_name=attr_data.get('attributeName', ''),  # Note: frontend envoie 'attributeName'
                            value=str(attr_data.get('value', '')) if attr_data.get('value') is not None else None,
                            code=existing_equipment.code,
                            description=attr_data.get('description') or existing_equipment.description,
                            is_copy_ot=attr_data.get('isCopyOt', False)  # Note: frontend envoie 'isCopyOt'
                        )
                        session.add(new_attribute)
                        logger.debug(f"Attribut mis à jour: {attr_data.get('attributeName')} = {attr_data.get('value')}")
                    except Exception as e:
                        logger.error(f"Erreur création attribut {attr_data.get('attributeName', 'N/A')}: {e}")
                        continue

            # 5) Commit si des changements ont été faits
            if updated_fields or attributes_data:
                session.commit()
                logger.info(f"✅ Équipement {equipment_id} mis à jour avec succès (champs: {updated_fields})")
                
                # Invalider le cache
                invalidate_equipment_insertion_cache(
                    str(existing_equipment.code), 
                    str(existing_equipment.entity), 
                    str(existing_equipment.famille)
                )
                
                return (True, f"Mise à jour réussie pour {len(updated_fields)} champs et {len(attributes_data)} attributs")
            else:
                logger.info(f"Aucun changement détecté pour l'équipement {equipment_id}")
                return (True, "Aucun changement")

    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour PATCH équipement {equipment_id}: {e}")
        return (False, f"Erreur: {str(e)}")


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


def insert_equipment(equipment: EquipmentClicClac) -> tuple[bool, Optional[int]]:
    """
    Insère un nouvel équipement dans la DB temporaire MSSQL (ClicClac).
    Structure différente : utilise EquipmentClicClac et AttributeClicClac
    """
    logger.info(f"🔧 Insertion équipement ClicClac MSSQL: {equipment.code}")
    
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
                existing_equipment = session.query(EquipmentClicClac).filter_by(
                    code=equipment.code
                ).first()
                
                if existing_equipment:
                    logger.error(f"Équipement avec le code {equipment.code} existe déjà")
                    return (False, None)

                # 2) Créer l'équipement ClicClac
                new_equipment = EquipmentClicClac(
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
                            new_attribute = AttributeClicClac(
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
                logger.info(f"✅ Équipement ClicClac ID: {equipment_id} - Code: {equipment.code} inséré avec succès")
                logger.info(f"✅ {created_attributes} attributs créés")

                # Invalider le cache
                invalidate_equipment_insertion_cache(
                    str(equipment.code), 
                    str(equipment.entity), 
                    str(equipment.famille)
                )

                return (True, equipment_id)

            except Exception as e:
                logger.error(f"Erreur lors de l'insertion équipement ClicClac: {e}")
                session.rollback()
                return (False, None)

    except Exception as e:
        logger.error(f"insert_equipment fatal error: {e}")
        return (False, None)


def get_all_equipment_web() -> Dict[str, Any]:
    """Récupère tous les équipements pour l'interface web (non paginé)"""
    try:
        # Utiliser SQLAlchemy session
        with get_temp_session() as session:
            equipments = session.query(EquipmentClicClac).all()
            
            equipments_formatted = []
            for r in equipments:
                attr = session.query(AttributeClicClac).filter_by(code=r.code).all()
                setattr(r, 'attributes', attr)
                equipments_formatted.append(r.to_dict_SDDV())

            return {"equipments": equipments_formatted, "count": len(equipments_formatted)}

    except Exception as e:
        logger.error(f"❌ Erreur récupération tous équipements web: {e}")
        return {"equipments": [], "count": 0}


def archive_equipments(equipment_ids: List[str]) -> tuple[bool, str, int, List[str]]:
    """
    Archive les équipements spécifiés de la DB temporaire MSSQL (ClicClac) vers l'historique.
    Pour chaque équipement :
    - Récupère l'équipement et ses attributs.
    - Insère dans HistoryEquipmentClicClac et HistoryAttributeClicClac.
    - Supprime de EquipmentClicClac et AttributeClicClac.
    Retourne : (success, message, archived_count, failed_ids)
    """
    logger.info(f"🔧 Archivage équipements ClicClac MSSQL IDs: {equipment_ids}")

    archived_count = 0
    failed_ids = []

    try:
        with get_temp_session() as session:
            for equipment_id in equipment_ids:
                try:
                    # 1) Récupérer l'équipement existant
                    equipment = session.query(EquipmentClicClac).filter(EquipmentClicClac.id == equipment_id).first()
                    
                    if not equipment:
                        logger.warning(f"Équipement ID {equipment_id} introuvable, ignoré")
                        failed_ids.append(equipment_id)
                        continue
                    
                    # 2) Récupérer les attributs associés (peut être vide)
                    attributes = session.query(AttributeClicClac).filter(AttributeClicClac.code == equipment.code).all()
                    
                    # 3) Créer l'entrée historique pour l'équipement
                    history_equipment = HistoryEquipmentClicClac(
                        commentaire=equipment.commentaire,
                        equipment_id=equipment.id,  # ✅ Plus de contrainte FK, juste une référence
                        code_parent=equipment.code_parent,
                        code=equipment.code,
                        famille=equipment.famille,
                        zone=equipment.zone,
                        entity=equipment.entity,
                        unite=equipment.unite,
                        centre_charge=equipment.centre_charge,
                        description=equipment.description,
                        longitude=equipment.longitude,
                        latitude=equipment.latitude,
                        feeder=equipment.feeder,
                        feeder_description=equipment.feeder_description,
                        info=equipment.info,
                        etat=equipment.etat,
                        type=equipment.type,
                        localisation=equipment.localisation,
                        niveau=equipment.niveau,
                        n_serie=equipment.n_serie,
                        created_at=equipment.created_at,
                        updated_at=equipment.updated_at,
                        created_by=equipment.created_by,
                        judged_by=equipment.judged_by,
                        is_update=equipment.is_update,
                        is_new=equipment.is_new,
                        is_approved=equipment.is_approved,
                        is_rejected=equipment.is_rejected
                    )
                    
                    session.add(history_equipment)
                    session.flush()  # Pour obtenir l'ID de l'historique
                    
                    logger.info(f"✅ Équipement historique créé avec ID: {history_equipment.id}")
                    
                    # 4) Créer les entrées historiques pour les attributs (si présents)
                    for attr in attributes:
                        history_attribute = HistoryAttributeClicClac(
                            history_id=history_equipment.id,
                            attribute_id=attr.id,  # ✅ Plus de contrainte FK, juste une référence
                            attribute_name=attr.attribute_name,
                            value=attr.value,
                            code=attr.code,
                            description=attr.description
                        )
                        session.add(history_attribute)
                        logger.debug(f"Attribut historique créé: {attr.attribute_name}")
                    
                    # 5) Supprimer les attributs originaux
                    session.query(AttributeClicClac).filter(AttributeClicClac.code == equipment.code).delete(synchronize_session='fetch')
                    logger.debug(f"Attributs originaux supprimés pour {equipment.code}")
                    
                    # 6) Supprimer l'équipement original
                    session.delete(equipment)
                    logger.debug(f"Équipement original {equipment.code} supprimé")
                    
                    # 7) Commit final pour cet équipement (persistance atomique)
                    session.commit()
                    
                    archived_count += 1
                    logger.info(f"✅ Équipement {equipment_id} ({equipment.code}) archivé avec {len(attributes)} attributs")
                    
                except Exception as e:
                    logger.error(f"❌ Erreur archivage équipement {equipment_id}: {e}", exc_info=True)
                    session.rollback()
                    failed_ids.append(equipment_id)
                    continue
            
            message = f"{archived_count} équipements archivés avec succès"
            if failed_ids:
                message += f", {len(failed_ids)} échecs (IDs: {failed_ids})"
            
            return (True, message, archived_count, failed_ids)
    
    except Exception as e:
        logger.error(f"❌ Erreur globale archivage équipements: {e}", exc_info=True)
        return (False, f"Erreur interne: {str(e)}", archived_count, failed_ids)
    

def get_all_equipment_histories() -> List[Dict[str, Any]]:
    """
    Récupère tous les historiques d'équipements, y compris leurs attributs.
    Retourne une liste de dictionnaires avec chaque historique et ses attributs associés.
    """
    logger.info("🔍 Récupération de tous les historiques d'équipements")

    try:
        with get_temp_session() as session:
            # 1) Récupérer tous les historiques d'équipement
            history_equipments = session.query(HistoryEquipmentClicClac).order_by(
                HistoryEquipmentClicClac.date_history_created_at.desc()
            ).all()
            
            if not history_equipments:
                logger.info("Aucun historique trouvé")
                return []
            
            history_list = []
            
            # 2) Pour chaque historique d'équipement, récupérer ses attributs
            for hist_eq in history_equipments:
                # Récupérer les attributs associés
                attributes = session.query(HistoryAttributeClicClac).filter(
                    HistoryAttributeClicClac.history_id == hist_eq.id
                ).all()
                
                # Convertir en dict
                hist_dict = hist_eq.to_dict()
                hist_dict['attributes'] = [attr.to_dict() for attr in attributes]
                
                history_list.append(hist_dict)
                logger.debug(f"Historique {hist_eq.id} récupéré avec {len(attributes)} attributs")
            
            logger.info(f"✅ {len(history_list)} historiques récupérés")
            return history_list
    
    except Exception as e:
        logger.error(f"❌ Erreur récupération tous les historiques: {e}")
        return []