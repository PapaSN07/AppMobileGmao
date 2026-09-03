from app.core.config import CACHE_TTL_SHORT
from app.core.cache import cache
from app.db.sqlalchemy.session import SQLAlchemyQueryExecutor, get_main_session
from app.models.famille_model import FamilleModel
from app.db.requests import CATEGORY_QUERY
from typing import Any, Dict
import logging

from app.services.entity_service import extract_hierarchy

logger = logging.getLogger(__name__)

def get_familles(entity: str, hierarchy_result: Dict[str, Any]) -> Dict[str, Any]:
    """Récupère toutes les familles depuis la base de données."""
    
    # ✅ FIX #1 : Clé de cache inclut l'entité pour éviter la fuite inter-utilisateurs
    cache_key = f"mobile_familles_{entity.upper()}"
    cached = cache.get_data_only(cache_key)
    if cached:
        return cached
    
    # ✅ DRY : Utilisation de extract_hierarchy
    hierarchy_entities = extract_hierarchy(entity, hierarchy_result)
    logger.info(f"Hiérarchie pour {entity}: {hierarchy_entities}")
    
    query = CATEGORY_QUERY
    params = {}
    
    try:
        with get_main_session() as session:
            db = SQLAlchemyQueryExecutor(session)
            
            hierarchy_entities.append('INFO_PARTAGEE') # Ajout de l'entité partagée
            
            # Filtre par hiérarchie d'entités (OBLIGATOIRE)
            placeholders = ','.join([f':entity_{i}' for i in range(len(hierarchy_entities))])
            query += f" WHERE mdct_entity IN ({placeholders})"
            
            for i, entity_code in enumerate(hierarchy_entities):
                params[f'entity_{i}'] = entity_code

            query += f" ORDER BY mdct_level, mdct_code"

            results = db.execute_query(query, params=params)
            familles = []
            for row in results:
                try:
                    famille = FamilleModel.from_db_row(row)
                    # Convertir en dictionnaire pour la sérialisation
                    familles.append(famille.to_dict())
                except Exception as e:
                    logger.error(f"❌ Erreur mapping famille: {e}")
                    continue

            if not familles:
                from sqlalchemy import text
                eq_rows = []
                try:
                    eq_rows = session.execute(text("SELECT DISTINCT ereq_category FROM dbo.equipment WHERE ereq_category IS NOT NULL AND ereq_category != ''")).fetchall()
                except Exception:
                    pass
                if not eq_rows:
                    try:
                        eq_rows = session.execute(text("SELECT DISTINCT famille FROM gmao_mobile.dbo.equipment WHERE famille IS NOT NULL AND famille != ''")).fetchall()
                    except Exception:
                        pass
                for r in eq_rows:
                    cat_val = str(r[0])
                    familles.append({
                        "code": cat_val,
                        "description": cat_val,
                        "level": "1"
                    })

            response = {"familles": familles, "count": len(familles)}
            cache.set(cache_key, response, CACHE_TTL_SHORT)
            return response
    except Exception as e:
        logger.error(f"❌ Erreur familles: {e}")
        raise