from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.entity_model import EntityModel
from app.core.config import CACHE_TTL_SHORT
from app.db.requests import ENTITY_QUERY  # HIERARCHIC supprimé : remplacé par CTE descendante
from app.core.cache import cache
from typing import Any, Dict
import logging

logger = logging.getLogger(__name__)

def extract_hierarchy(entity: str, hierarchy_result: Dict[str, Any] = None) -> list[str]:
    """Extrait la liste des entités autorisées à partir de la hiérarchie ou utilise entity en fallback."""
    if hierarchy_result and isinstance(hierarchy_result, dict):
        hierarchy_entities = hierarchy_result.get('hierarchy', [])
        if hierarchy_entities:
            return list(hierarchy_entities)
    try:
        res = get_hierarchy(entity)
        return res.get('hierarchy', [entity])
    except Exception as e:
        logger.warning(f"Erreur extraction hiérarchie pour {entity}: {e}, fallback sur [entity]")
        return [entity]

def get_entities(entity: str, hierarchy_result: Dict[str, Any]) -> Dict[str, Any]:
    """Récupère les entités depuis la base de données."""
    
    # Inclure la limite dans la clé de cache
    cache_key = f"mobile_entities_{entity}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # ✅ DRY : Utilisation de la fonction utilitaire extract_hierarchy
    hierarchy_entities = extract_hierarchy(entity, hierarchy_result)
    logger.info(f"Hiérarchie pour {entity}: {hierarchy_entities}")
    
    query = ENTITY_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE chen_code IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code
            
            query += f" ORDER BY chen_level, chen_code"

            results = db.execute_query(query, params=params)
            entities = []
            
            for row in results:
                try:
                    entity_model = EntityModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    entities.append(entity_model.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping entité: {e}")
                    continue

            if not entities:
                from sqlalchemy import text
                eq_rows = []
                try:
                    eq_rows = session.execute(text("SELECT DISTINCT ereq_entity FROM dbo.equipment WHERE ereq_entity IS NOT NULL AND ereq_entity != ''")).fetchall()
                except Exception:
                    pass
                if not eq_rows:
                    try:
                        eq_rows = session.execute(text("SELECT DISTINCT entity FROM gmao_mobile.dbo.equipment WHERE entity IS NOT NULL AND entity != ''")).fetchall()
                    except Exception:
                        pass
                for r in eq_rows:
                    val = str(r[0])
                    entities.append({
                        "code": val,
                        "description": val,
                        "level": "1"
                    })

            response = {
                "entities": entities, 
                "count": len(entities)
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(entities)} entités récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
        raise

def get_hierarchy(entity_code: str) -> Dict[str, Any]:
    """Récupère la hiérarchie descendante stricte (soi-même + tous les enfants/descendants uniquement)."""
    cache_key = f"entity_hierarchy_descendants_{entity_code}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    query_descendants = """
        WITH EntityHierarchy AS (
            SELECT chen_code, chen_parent_entity
            FROM entity
            WHERE UPPER(chen_code) = UPPER(:entity)
            
            UNION ALL
            
            SELECT e.chen_code, e.chen_parent_entity
            FROM entity e
            INNER JOIN EntityHierarchy h ON UPPER(e.chen_parent_entity) = UPPER(h.chen_code)
        )
        SELECT DISTINCT chen_code FROM EntityHierarchy
    """
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            results = db.execute_query(query_descendants, {'entity': entity_code})
            
            if not results:
                hierarchy = [entity_code]
            else:
                hierarchy = [row[0] if isinstance(row, tuple) else row.get('chen_code') for row in results]

            response = {
                "entity_code": entity_code,
                "hierarchy": hierarchy,
                "count": len(hierarchy),
                "generated_by": "recursive_descendants_cte"
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ Hiérarchie descendante de {entity_code}: {len(hierarchy)} niveaux ({hierarchy})")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur hiérarchie descendante SQL: {e}")
        return {
            "entity_code": entity_code,
            "hierarchy": [entity_code],
            "count": 1,
            "message": f"Fallback: Hiérarchie seule pour {entity_code}"
        }

def get_all_entities() -> Dict[str, Any]:
    """Récupère les entités depuis la base de données."""
    
    # Inclure la limite dans la clé de cache
    cache_key = f"mobile_entities"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    try:
        with get_main_session() as session:
            entities = session.query(EntityModel).all()

            response = {
                "entities": [entity.to_dict() for entity in entities], 
                "count": len(entities)
            }
            
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            logger.info(f"✅ {len(entities)} entités récupérées")
            return response
            
    except Exception as e:
        logger.error(f"❌ Erreur entités: {e}")
        raise