from app.db.database import OracleDatabase, PaginationResult
from app.core.config import DEFAULT_LIMIT, MAX_LIMIT, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE, CACHE_TTL_MEDIUM, CACHE_TTL_LONG
from app.models.models import EquipmentModel, ZoneModel, FamilleModel, EntityModel, EquipmentFilterModel
from app.core.cache import cache, cache_equipment_list, get_cached_equipment_list, cache_zones_list, get_cached_zones_list, cache_familles_list, get_cached_familles_list, cache_entities_list, get_cached_entities_list
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

def get_equipments(limit: Optional[int] = DEFAULT_LIMIT) -> List[Dict[str, Any]]:
    """
    Récupère les équipements avec limitation optionnelle.
    
    Args:
        limit: Nombre maximum d'équipements à retourner
        
    Returns:
        Liste des équipements au format dictionnaire
        
    Raises:
        ValueError: Si la limite est invalide
        ConnectionError: Si problème de connexion DB
    """
    # Validation de la limite
    if limit is not None:
        if limit < 1 or limit > MAX_LIMIT:
            raise ValueError(f"Le paramètre 'limit' doit être compris entre 1 et {MAX_LIMIT}.")
    
    # Vérifier le cache d'abord
    cache_key = f"equipment_simple_limit_{limit}"
    cached_result = cache.get_data_only(cache_key)
    if cached_result:
        logger.info(f"📋 Cache hit pour get_equipments avec limit={limit}")
        return cached_result
    
    # Requête SQL principale
    query = """
    SELECT 
        pk_equipment, -- id
        ereq_parent_equipment, -- codeParent
        ereq_code, -- code
        ereq_category, -- famille
        ereq_zone, -- zone
        ereq_entity, -- entité
        ereq_function, -- unité
        ereq_costcentre, -- centre de charge
        ereq_description, -- description
        ereq_longitude, -- longitude
        ereq_latitude, -- latitude
        (SELECT pk_equipment FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
    FROM coswin.t_equipment
    ORDER BY pk_equipment
    """
    
    try:
        with OracleDatabase() as db:
            # Exécuter la requête avec limite
            results = db.execute_query(query, limit=limit)
            
            # Mapper les résultats avec EquipmentModel
            equipments = []
            for row in results:
                try:
                    equipment = EquipmentModel.from_db_row(row)
                    equipments.append(equipment.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping équipement {row}: {e}")
                    continue
            
            # Mettre en cache
            cache.set(cache_key, equipments, CACHE_TTL_MEDIUM)
            
            logger.info(f"✅ Récupéré {len(equipments)} équipements avec limit={limit}")
            return equipments
            
    except Exception as e:
        logger.error(f"❌ Erreur get_equipments: {e}")
        raise


def get_equipments_paginated(page: int = 1, page_size: int = DEFAULT_PAGE_SIZE) -> Dict[str, Any]:
    """
    Récupère les équipements avec pagination.
    
    Args:
        page: Numéro de la page (commence à 1)
        page_size: Nombre d'éléments par page
        
    Returns:
        Dictionnaire avec équipements et métadonnées de pagination
        
    Raises:
        ValueError: Si les paramètres de pagination sont invalides
    """
    # Validation des paramètres
    if page_size < 1 or page_size > MAX_PAGE_SIZE:
        raise ValueError(f"Le paramètre 'page_size' doit être compris entre 1 et {MAX_PAGE_SIZE}.")
    
    if page < 1:
        raise ValueError("Le paramètre 'page' doit être supérieur à 0.")
    
    # Vérifier le cache
    cache_key = f"equipment_paginated_page_{page}_size_{page_size}"
    cached_result = cache.get_data_only(cache_key)
    if cached_result:
        logger.info(f"📋 Cache hit pour pagination page={page}, size={page_size}")
        return cached_result
    
    # Requête SQL principale
    query = """
    SELECT 
        pk_equipment, -- id
        ereq_parent_equipment, -- codeParent
        ereq_code, -- code
        ereq_category, -- famille
        ereq_zone, -- zone
        ereq_entity, -- entité
        ereq_function, -- unité
        ereq_costcentre, -- centre de charge
        ereq_description, -- description
        ereq_longitude, -- longitude
        ereq_latitude, -- latitude
        (SELECT pk_equipment FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
    FROM coswin.t_equipment
    ORDER BY pk_equipment
    """
    
    try:
        with OracleDatabase() as db:
            # Exécuter avec pagination
            pagination_result = db.execute_query_with_pagination(
                query, 
                page=page, 
                page_size=page_size
            )
            
            # Mapper les données
            formatted_data = []
            for row in pagination_result.data:
                try:
                    equipment = EquipmentModel.from_db_row(row)
                    formatted_data.append(equipment.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping équipement {row}: {e}")
                    continue
            
            # Créer la réponse
            response = {
                'equipments': formatted_data,
                'pagination': {
                    'page': pagination_result.page,
                    'page_size': pagination_result.page_size,
                    'total_count': pagination_result.total_count,
                    'total_pages': pagination_result.total_pages,
                    'has_next': pagination_result.has_next,
                    'has_prev': pagination_result.has_prev
                }
            }
            
            # Mettre en cache avec TTL plus court car données paginées
            cache.set(cache_key, response, CACHE_TTL_MEDIUM // 2)
            
            logger.info(f"✅ Page {page}/{pagination_result.total_pages} récupérée: {len(formatted_data)} équipements")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur get_equipments_paginated: {e}")
        raise


def get_equipments_filtered(
    page: int = 1,
    page_size: int = DEFAULT_PAGE_SIZE,
    zone: Optional[str] = None,
    famille: Optional[str] = None,
    entity: Optional[str] = None,
    search_term: Optional[str] = None
) -> Dict[str, Any]:
    """
    Récupère les équipements avec filtres et pagination.
    
    Args:
        page: Numéro de page
        page_size: Taille de page
        zone: Filtre par zone
        famille: Filtre par famille
        entity: Filtre par entité
        search_term: Terme de recherche textuelle
        
    Returns:
        Dictionnaire avec équipements filtrés et pagination
    """
    # Validation
    if page_size < 1 or page_size > MAX_PAGE_SIZE:
        raise ValueError(f"Le paramètre 'page_size' doit être compris entre 1 et {MAX_PAGE_SIZE}.")
    
    # Créer le modèle de filtre
    filter_model = EquipmentFilterModel(
        page=page,
        page_size=page_size,
        zone=zone,
        famille=famille,
        entity=entity,
        search_term=search_term
    )
    
    # Vérifier le cache
    filters_dict = filter_model.to_dict()
    cached_result = get_cached_equipment_list(filters_dict)
    if cached_result:
        logger.info(f"📋 Cache hit pour filtres: {filters_dict}")
        return cached_result
    
    # Construire la requête de base
    query = """
    SELECT 
        pk_equipment, -- id
        ereq_parent_equipment, -- codeParent
        ereq_code, -- code
        ereq_category, -- famille
        ereq_zone, -- zone
        ereq_entity, -- entité
        ereq_function, -- unité
        ereq_costcentre, -- centre de charge
        ereq_description, -- description
        ereq_longitude, -- longitude
        ereq_latitude, -- latitude
        (SELECT pk_equipment FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
    FROM coswin.t_equipment
    WHERE 1=1
    """
    
    # Ajouter les conditions de filtre
    params = {}
    
    if zone:
        query += " AND ereq_zone = :zone"
        params['zone'] = zone
    
    if famille:
        query += " AND ereq_category = :famille"
        params['famille'] = famille
        
    if entity:
        query += " AND ereq_entity = :entity"
        params['entity'] = entity
    
    if search_term:
        query += """ AND (
            LOWER(ereq_code) LIKE LOWER(:search_term) OR 
            LOWER(ereq_description) LIKE LOWER(:search_term)
        )"""
        params['search_term'] = f"%{search_term}%"
    
    query += " ORDER BY pk_equipment"
    
    try:
        with OracleDatabase() as db:
            # Exécuter avec pagination
            pagination_result = db.execute_query_with_pagination(
                query, 
                params=params,
                page=page, 
                page_size=page_size
            )
            
            # Mapper les données
            formatted_data = []
            for row in pagination_result.data:
                try:
                    equipment = EquipmentModel.from_db_row(row)
                    formatted_data.append(equipment.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping équipement {row}: {e}")
                    continue
            
            # Créer la réponse
            response = {
                'equipments': formatted_data,
                'pagination': {
                    'page': pagination_result.page,
                    'page_size': pagination_result.page_size,
                    'total_count': pagination_result.total_count,
                    'total_pages': pagination_result.total_pages,
                    'has_next': pagination_result.has_next,
                    'has_prev': pagination_result.has_prev
                },
                'filters': {
                    'zone': zone,
                    'famille': famille,
                    'entity': entity,
                    'search_term': search_term,
                    'has_filters': filter_model.has_filters()
                }
            }
            
            # Mettre en cache
            cache_equipment_list(response, filters_dict, CACHE_TTL_MEDIUM)
            
            logger.info(f"✅ Filtres appliqués: {len(formatted_data)} équipements trouvés")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur get_equipments_filtered: {e}")
        raise


def get_zones() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les zones distinctes avec cache.
    
    Returns:
        Dictionnaire avec la liste des zones et métadonnées
    """
    # Vérifier le cache
    cached_zones = get_cached_zones_list()
    if cached_zones:
        logger.info("📋 Cache hit pour zones")
        return cached_zones
    
    # Requête pour récupérer les zones avec comptage
    query = """
    SELECT ereq_zone, COUNT(*) as count
    FROM coswin.t_equipment 
    WHERE ereq_zone IS NOT NULL 
    GROUP BY ereq_zone 
    ORDER BY ereq_zone
    """
    
    try:
        with OracleDatabase() as db:
            results = db.execute_query(query)
            
            zones = []
            for row in results:
                try:
                    zone = ZoneModel.from_db_row(row)
                    zones.append(zone.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping zone {row}: {e}")
                    continue
            
            response = {
                'zones': zones,
                'count': len(zones)
            }
            
            # Mettre en cache avec TTL long
            cache_zones_list(response, CACHE_TTL_LONG)
            
            logger.info(f"✅ {len(zones)} zones récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur get_zones: {e}")
        raise


def get_familles() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les familles distinctes avec cache.
    
    Returns:
        Dictionnaire avec la liste des familles et métadonnées
    """
    # Vérifier le cache
    cached_familles = get_cached_familles_list()
    if cached_familles:
        logger.info("📋 Cache hit pour familles")
        return cached_familles
    
    # Requête pour récupérer les familles avec comptage
    query = """
    SELECT ereq_category, COUNT(*) as count
    FROM coswin.t_equipment 
    WHERE ereq_category IS NOT NULL 
    GROUP BY ereq_category 
    ORDER BY ereq_category
    """
    
    try:
        with OracleDatabase() as db:
            results = db.execute_query(query)
            
            familles = []
            for row in results:
                try:
                    famille = FamilleModel.from_db_row(row)
                    familles.append(famille.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping famille {row}: {e}")
                    continue
            
            response = {
                'familles': familles,
                'count': len(familles)
            }
            
            # Mettre en cache avec TTL long
            cache_familles_list(response, CACHE_TTL_LONG)
            
            logger.info(f"✅ {len(familles)} familles récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur get_familles: {e}")
        raise


def get_entities() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les entités distinctes avec cache.
    
    Returns:
        Dictionnaire avec la liste des entités et métadonnées
    """
    # Vérifier le cache
    cached_entities = get_cached_entities_list()
    if cached_entities:
        logger.info("📋 Cache hit pour entités")
        return cached_entities
    
    # Requête pour récupérer les entités avec comptage
    query = """
    SELECT ereq_entity, COUNT(*) as count
    FROM coswin.t_equipment 
    WHERE ereq_entity IS NOT NULL 
    GROUP BY ereq_entity 
    ORDER BY ereq_entity
    """
    
    try:
        with OracleDatabase() as db:
            results = db.execute_query(query)
            
            entities = []
            for row in results:
                try:
                    entity = EntityModel.from_db_row(row)
                    entities.append(entity.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité {row}: {e}")
                    continue
            
            response = {
                'entities': entities,
                'count': len(entities)
            }
            
            # Mettre en cache avec TTL long
            cache_entities_list(response, CACHE_TTL_LONG)
            
            logger.info(f"✅ {len(entities)} entités récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur get_entities: {e}")
        raise


def get_equipment_by_id(equipment_id: str) -> Optional[Dict[str, Any]]:
    """
    Récupère un équipement spécifique par son ID.
    
    Args:
        equipment_id: ID de l'équipement à récupérer
        
    Returns:
        Dictionnaire de l'équipement ou None si non trouvé
    """
    # Vérifier le cache
    cache_key = f"equipment_detail_{equipment_id}"
    cached_equipment = cache.get_data_only(cache_key)
    if cached_equipment:
        logger.info(f"📋 Cache hit pour équipement {equipment_id}")
        return cached_equipment
    
    query = """
    SELECT 
        pk_equipment, ereq_parent_equipment, ereq_code, ereq_category, 
        ereq_zone, ereq_entity, ereq_function, ereq_costcentre, 
        ereq_description, ereq_longitude, ereq_latitude,
        (SELECT pk_equipment FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder,
        (SELECT ereq_description FROM coswin.t_equipment t2 
         WHERE coswin.t_equipment.ereq_string2 = t2.ereq_code) as feeder_description
    FROM coswin.t_equipment
    WHERE pk_equipment = :equipment_id
    """
    
    try:
        with OracleDatabase() as db:
            results = db.execute_query(query, params={'equipment_id': equipment_id})
            
            if not results:
                logger.info(f"❓ Équipement {equipment_id} non trouvé")
                return None
            
            equipment = EquipmentModel.from_db_row(results[0])
            equipment_dict = equipment.to_api_response()
            
            # Mettre en cache
            cache.set(cache_key, equipment_dict, CACHE_TTL_LONG)
            
            logger.info(f"✅ Équipement {equipment_id} récupéré")
            return equipment_dict
            
    except Exception as e:
        logger.error(f"❌ Erreur get_equipment_by_id {equipment_id}: {e}")
        raise


def get_equipment_stats() -> Dict[str, Any]:
    """
    Récupère les statistiques générales des équipements.
    
    Returns:
        Dictionnaire avec les statistiques
    """
    cache_key = "equipment_stats"
    cached_stats = cache.get_data_only(cache_key)
    if cached_stats:
        logger.info("📋 Cache hit pour statistiques")
        return cached_stats
    
    queries = {
        'total_count': "SELECT COUNT(*) FROM coswin.t_equipment",
        'zones_count': "SELECT COUNT(DISTINCT ereq_zone) FROM coswin.t_equipment WHERE ereq_zone IS NOT NULL",
        'familles_count': "SELECT COUNT(DISTINCT ereq_category) FROM coswin.t_equipment WHERE ereq_category IS NOT NULL",
        'entities_count': "SELECT COUNT(DISTINCT ereq_entity) FROM coswin.t_equipment WHERE ereq_entity IS NOT NULL",
        'with_coordinates': "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_longitude IS NOT NULL AND ereq_latitude IS NOT NULL",
        'with_feeder': "SELECT COUNT(*) FROM coswin.t_equipment WHERE ereq_string2 IS NOT NULL"
    }
    
    try:
        with OracleDatabase() as db:
            stats = {}
            for key, query in queries.items():
                result = db.execute_query(query)
                stats[key] = result[0][0] if result else 0
            
            stats['last_updated'] = db.execute_query("SELECT SYSDATE FROM DUAL")[0][0]
            
            # Mettre en cache avec TTL long
            cache.set(cache_key, stats, CACHE_TTL_LONG)
            
            logger.info("✅ Statistiques générales récupérées")
            return stats
            
    except Exception as e:
        logger.error(f"❌ Erreur get_equipment_stats: {e}")
        raise


def invalidate_all_cache():
    """
    Invalide tout le cache des équipements.
    
    Returns:
        Nombre de clés supprimées
    """
    patterns = [
        "equipment*", 
        "zones_list", 
        "familles_list", 
        "entities_list",
        "equipment_stats"
    ]
    
    total_deleted = 0
    for pattern in patterns:
        deleted = cache.clear_pattern(pattern)
        total_deleted += deleted
    
    logger.info(f"🧹 Cache invalidé: {total_deleted} clés supprimées")
    return total_deleted


def refresh_reference_data():
    """
    Force le rafraîchissement des données de référence (zones, familles, entités).
    
    Returns:
        Dictionnaire avec le statut du rafraîchissement
    """
    try:
        # Invalider les caches existants
        cache.delete("zones_list")
        cache.delete("familles_list") 
        cache.delete("entities_list")
        cache.delete("equipment_stats")
        
        # Recharger les données
        zones = get_zones()
        familles = get_familles()
        entities = get_entities()
        stats = get_equipment_stats()
        
        return {
            'status': 'success',
            'zones_count': zones['count'],
            'familles_count': familles['count'],
            'entities_count': entities['count'],
            'total_equipments': stats['total_count'],
            'refreshed_at': stats['last_updated']
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur refresh_reference_data: {e}")
        return {
            'status': 'error',
            'error': str(e)
        }


if __name__ == "__main__":
    # Tests de base
    print("🧪 Test des services d'équipements...")
    
    try:
        # Test récupération simple
        equipments = get_equipments(limit=5)
        print(f"✅ {len(equipments)} équipements récupérés")
        
        # Test statistiques
        stats = get_equipment_stats()
        print(f"✅ Stats: {stats['total_count']} équipements total")
        
        # Test zones
        zones = get_zones()
        print(f"✅ {zones['count']} zones récupérées")
        
        print("✅ Tous les tests passés")
        
    except Exception as e:
        print(f"❌ Erreur lors des tests: {e}")