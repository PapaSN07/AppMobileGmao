from app.db.database import get_database_connection
from app.models.models import EntityModel
from app.core.config import CACHE_TTL_LONG
from app.db.requests import ENTITY_QUERY
from app.core.cache import cache
from typing import Any, Dict, List
import logging

logger = logging.getLogger(__name__)

def get_entities(limit: int = 20) -> Dict[str, Any]:
    """Récupère les entités depuis la base de données."""
    # Inclure la limite dans la clé de cache
    cache_key = f"mobile_entities_{limit}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query = ENTITY_QUERY
    
    try:
        with get_database_connection() as db:
            # Appliquer la limite dans la requête SQL
            limited_query = f"""
            SELECT * FROM (
                {query}
            ) WHERE ROWNUM <= {limit}
            """
            
            results = db.execute_query(limited_query)
            entities = []
            
            for row in results:
                try:
                    entity = EntityModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    entities.append(entity.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité: {e}")
                    continue

            response = {
                "entities": entities, 
                "count": len(entities),
                "total_available": _get_total_count()  # Nombre total en DB
            }
            
            cache.set(cache_key, response, CACHE_TTL_LONG)
            logger.info(f"✅ {len(entities)} entités récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
        raise

def get_entities_by_type(entity_type: str, limit: int = 20) -> Dict[str, Any]:
    """Récupère les entités par type depuis la base de données."""
    cache_key = f"mobile_entities_type_{entity_type}_{limit}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    try:
        with get_database_connection() as db:
            query = """
            SELECT * FROM (
                SELECT
                    pk_entity,
                    chen_code,
                    chen_description,
                    chen_entity_type,
                    chen_level,
                    chen_parent_entity,
                    chen_system_entity
                FROM coswin.entity
                WHERE chen_entity_type = :entity_type
                ORDER BY chen_level, chen_code
            ) WHERE ROWNUM <= :limit
            """
            
            results = db.execute_query(query, {
                'entity_type': entity_type,
                'limit': limit
            })
            entities = []
            
            for row in results:
                try:
                    entity = EntityModel.from_db_row(row)
                    entities.append(entity.to_api_response())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité par type: {e}")
                    continue

            response = {
                "entities": entities,
                "count": len(entities),
                "entity_type": entity_type,
                "total_available": _get_total_count_by_type(entity_type)
            }
            
            cache.set(cache_key, response, CACHE_TTL_LONG)
            logger.info(f"✅ {len(entities)} entités de type {entity_type} récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur entités par type: {e}")
        raise

def get_entities_hierarchy_by_type(entity_type: str) -> Dict[str, Any]:
    """Récupère une entité et sa hiérarchie complète basée sur le type d'entité."""
    cache_key = f"entities_hierarchy_type_{entity_type}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    try:
        with get_database_connection() as db:
            # Récupérer l'entité principale du type demandé
            main_entity_query = """
            SELECT 
                pk_entity,
                chen_code,
                chen_description,
                chen_entity_type,
                chen_level,
                chen_parent_entity,
                chen_system_entity
            FROM coswin.entity 
            WHERE chen_entity_type = :entity_type
            AND ROWNUM = 1
            ORDER BY chen_level
            """
            
            main_results = db.execute_query(main_entity_query, {'entity_type': entity_type})
            
            if not main_results:
                return {
                    "main_entity": None,
                    "hierarchy": [],
                    "count": 0,
                    "entity_type": entity_type,
                    "message": f"Aucune entité trouvée pour le type {entity_type}"
                }
            
            # Créer l'entité principale
            main_entity = EntityModel.from_db_row(main_results[0])
            
            # CORRECTION: Requête CTE récursive avec alias de colonnes
            hierarchy_query = """
            WITH hierarchy_tree (
                pk_entity,
                chen_code, 
                chen_description,
                chen_entity_type,
                chen_level,
                chen_parent_entity,
                chen_system_entity,
                hierarchy_level,
                root_entity
            ) AS (
                -- Entité racine du type demandé
                SELECT 
                    pk_entity,
                    chen_code,
                    chen_description,
                    chen_entity_type,
                    chen_level,
                    chen_parent_entity,
                    chen_system_entity,
                    0 as hierarchy_level,
                    chen_code as root_entity
                FROM coswin.entity 
                WHERE chen_entity_type = :entity_type
                
                UNION ALL
                
                -- Entités enfants (récursif)
                SELECT 
                    e.pk_entity,
                    e.chen_code,
                    e.chen_description,
                    e.chen_entity_type,
                    e.chen_level,
                    e.chen_parent_entity,
                    e.chen_system_entity,
                    h.hierarchy_level + 1,
                    h.root_entity
                FROM coswin.entity e
                INNER JOIN hierarchy_tree h ON e.chen_parent_entity = h.chen_code
                WHERE h.hierarchy_level < 5  -- Limite pour éviter les boucles infinies
            )
            SELECT 
                h.chen_code,
                h.chen_description,
                h.chen_level,
                h.chen_entity_type,
                h.chen_parent_entity,
                h.hierarchy_level,
                (SELECT p.chen_description 
                 FROM coswin.entity p 
                 WHERE p.chen_code = h.chen_parent_entity
                ) AS parent_description
            FROM hierarchy_tree h
            ORDER BY h.hierarchy_level, h.chen_level, h.chen_code
            """
            
            hierarchy_results = db.execute_query(hierarchy_query, {'entity_type': entity_type})
            hierarchy = []
            
            for row in hierarchy_results:
                hierarchy.append({
                    'code': row[0],
                    'description': row[1],
                    'entity_level': row[2],  # Niveau dans l'organisation SENELEC
                    'entity_type': row[3],
                    'parent_code': row[4],
                    'hierarchy_level': row[5],  # Niveau dans la hiérarchie de l'arbre
                    'parent_description': row[6]
                })

            response = {
                "main_entity": main_entity.to_api_response(),
                "hierarchy": hierarchy,
                "count": len(hierarchy),
                "entity_type": entity_type,
                "total_levels": max([h['hierarchy_level'] for h in hierarchy]) + 1 if hierarchy else 1
            }
            
            cache.set(cache_key, response, CACHE_TTL_LONG)
            logger.info(f"✅ Hiérarchie de {len(hierarchy)} entités récupérée pour le type {entity_type}")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur hiérarchie entités par type: {e}")
        raise

def get_entities_hierarchy() -> Dict[str, Any]:
    """Récupère la hiérarchie complète de toutes les entités."""
    cache_key = "entities_hierarchy_all"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    try:
        with get_database_connection() as db:
            query = """
            SELECT 
                e.chen_code,
                e.chen_description,
                e.chen_level,
                e.chen_entity_type,
                e.chen_parent_entity,
                (SELECT p.chen_description 
                 FROM coswin.entity p 
                 WHERE p.chen_code = e.chen_parent_entity
                ) AS parent_description
            FROM coswin.entity e
            ORDER BY e.chen_level, e.chen_entity_type, e.chen_code
            """
            
            results = db.execute_query(query)
            hierarchy = []
            
            for row in results:
                hierarchy.append({
                    'code': row[0],
                    'description': row[1],
                    'level': row[2],
                    'type': row[3],
                    'parent_code': row[4],
                    'parent_description': row[5]
                })

            # Organiser par type d'entité
            hierarchy_by_type = {}
            for entity in hierarchy:
                entity_type = entity['type']
                if entity_type not in hierarchy_by_type:
                    hierarchy_by_type[entity_type] = []
                hierarchy_by_type[entity_type].append(entity)

            response = {
                "hierarchy": hierarchy,
                "hierarchy_by_type": hierarchy_by_type,
                "count": len(hierarchy),
                "types_count": len(hierarchy_by_type)
            }
            
            cache.set(cache_key, response, CACHE_TTL_LONG)
            logger.info(f"✅ Hiérarchie complète de {len(hierarchy)} entités récupérée")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur hiérarchie entités: {e}")
        raise

def _get_total_count() -> int:
    """Récupère le nombre total d'entités"""
    try:
        with get_database_connection() as db:
            result = db.execute_query("SELECT COUNT(*) FROM coswin.entity")
            return result[0][0] if result else 0
    except Exception:
        return 0

def _get_total_count_by_type(entity_type: str) -> int:
    """Récupère le nombre total d'entités par type"""
    try:
        with get_database_connection() as db:
            result = db.execute_query(
                "SELECT COUNT(*) FROM coswin.entity WHERE chen_entity_type = :entity_type",
                {'entity_type': entity_type}
            )
            return result[0][0] if result else 0
    except Exception:
        return 0