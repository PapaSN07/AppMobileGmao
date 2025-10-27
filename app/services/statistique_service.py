import logging
from datetime import datetime
from sqlalchemy import func, and_, case
from typing import Dict

from app.db.sqlalchemy.session import get_main_session, get_temp_session
from app.models.equipment_model import EquipmentModel as EquipmentGMAO
from app.models.equipment_model import EquipmentClicClac, HistoryEquipmentClicClac
from app.core.cache import cache

logger = logging.getLogger(__name__)

def get_statistics_cockpit_web(include_details: bool = False) -> Dict:
    """
    Récupère les statistiques complètes pour le dashboard web
    
    Args:
        include_details: Si True, inclut les statistiques détaillées par entité/famille/utilisateur
    
    Returns:
        Dict contenant toutes les statistiques
    """
    logger.info("📊 Récupération des statistiques du dashboard")
    
    # Vérifier le cache (TTL: 5 minutes)
    cache_key = f"dashboard_stats:detailed_{include_details}"
    cached_stats = cache.get(cache_key)
    
    if cached_stats:
        logger.info("✅ Statistiques récupérées depuis le cache")
        return cached_stats
    
    try:
        # ============ Statistiques principales ============
        
        # 1. Nombre d'équipements dans GMAO (DB Main)
        with get_main_session() as main_session:
            total_gmao = main_session.query(func.count(EquipmentGMAO.id)).scalar() or 0
            logger.info(f"📦 Équipements GMAO: {total_gmao}")
        
        # 2. Statistiques de la DB temporaire (MSSQL)
        with get_temp_session() as temp_session:
            # Total des équipements en attente
            total_temp = temp_session.query(func.count(EquipmentClicClac.id)).scalar() or 0
            
            # Nouveaux équipements (is_new=True)
            new_equipments = temp_session.query(func.count(EquipmentClicClac.id)).filter(
                EquipmentClicClac.is_new == True
            ).scalar() or 0
            
            # Équipements modifiés (is_update=True)
            updated_equipments = temp_session.query(func.count(EquipmentClicClac.id)).filter(
                EquipmentClicClac.is_update == True
            ).scalar() or 0
            
            # Équipements approuvés
            approved_equipments = temp_session.query(func.count(EquipmentClicClac.id)).filter(
                EquipmentClicClac.is_approved == True
            ).scalar() or 0
            
            # Équipements rejetés
            rejected_equipments = temp_session.query(func.count(EquipmentClicClac.id)).filter(
                EquipmentClicClac.is_rejected == True
            ).scalar() or 0
            
            # Équipements en attente de validation
            pending_validation = temp_session.query(func.count(EquipmentClicClac.id)).filter(
                and_(
                    EquipmentClicClac.is_approved == False,
                    EquipmentClicClac.is_rejected == False
                )
            ).scalar() or 0
            
            # Équipements archivés (historique)
            archived_equipments = temp_session.query(func.count(HistoryEquipmentClicClac.id)).scalar() or 0
            
            logger.info(f"📊 Stats DB Temp - Total: {total_temp}, Nouveaux: {new_equipments}, Modifiés: {updated_equipments}")
            logger.info(f"📊 Stats DB Temp - Approuvés: {approved_equipments}, Rejetés: {rejected_equipments}, En attente: {pending_validation}")
            logger.info(f"📦 Équipements archivés: {archived_equipments}")
            
            # ============ Statistiques détaillées (optionnel) ============
            stats_by_entity = None
            stats_by_family = None
            stats_by_user = None
            
            if include_details:
                # Statistiques par entité
                stats_by_entity = temp_session.query(
                    EquipmentClicClac.entity,
                    func.count(EquipmentClicClac.id).label('count')
                ).group_by(EquipmentClicClac.entity).all()
                
                stats_by_entity = [
                    {"entity": entity or "N/A", "count": count}
                    for entity, count in stats_by_entity
                ]
                
                # Statistiques par famille
                stats_by_family = temp_session.query(
                    EquipmentClicClac.famille,
                    func.count(EquipmentClicClac.id).label('count')
                ).group_by(EquipmentClicClac.famille).order_by(func.count(EquipmentClicClac.id).desc()).limit(10).all()
                
                stats_by_family = [
                    {"family": family or "N/A", "count": count}
                    for family, count in stats_by_family
                ]
                
                # Statistiques par utilisateur
                stats_by_user = temp_session.query(
                    EquipmentClicClac.created_by,
                    func.sum(case((EquipmentClicClac.is_new == True, 1), else_=0)).label('new_count'),
                    func.sum(case((EquipmentClicClac.is_update == True, 1), else_=0)).label('update_count')
                ).group_by(EquipmentClicClac.created_by).all()
                
                stats_by_user = [
                    {
                        "username": username or "unknown",
                        "new_count": int(new_count) if new_count else 0,
                        "update_count": int(update_count) if update_count else 0
                    }
                    for username, new_count, update_count in stats_by_user
                    if username
                ]
                
                logger.info(f"📊 Stats détaillées - Entités: {len(stats_by_entity)}, Familles: {len(stats_by_family)}, Utilisateurs: {len(stats_by_user)}")
        
        # ============ Construire la réponse ============
        result = {
            "success": True,
            "message": "Statistiques récupérées avec succès",
            "equipment_stats": {
                "total_gmao": total_gmao,
                "total_temp": total_temp,
                "new_equipments": new_equipments,
                "updated_equipments": updated_equipments,
                "approved_equipments": approved_equipments,
                "rejected_equipments": rejected_equipments,
                "pending_validation": pending_validation,
                "archived_equipments": archived_equipments
            },
            "stats_by_entity": stats_by_entity,
            "stats_by_family": stats_by_family,
            "stats_by_user": stats_by_user,
            "last_updated": datetime.now().isoformat() + "Z"
        }
        
        # Mettre en cache (5 minutes)
        cache.set(cache_key, result, ttl=300)
        
        logger.info("✅ Statistiques récupérées et mises en cache")
        return result
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des statistiques: {e}", exc_info=True)
        return {
            "success": False,
            "message": f"Erreur: {str(e)}",
            "equipment_stats": {
                "total_gmao": 0,
                "total_temp": 0,
                "new_equipments": 0,
                "updated_equipments": 0,
                "approved_equipments": 0,
                "rejected_equipments": 0,
                "pending_validation": 0,
                "archived_equipments": 0
            },
            "stats_by_entity": None,
            "stats_by_family": None,
            "stats_by_user": None,
            "last_updated": datetime.utcnow().isoformat() + "Z"
        }

def get_statistics_summary() -> Dict:
    """
    Récupère uniquement les statistiques principales (version légère)
    Utile pour les appels fréquents ou les dashboards mobiles
    """
    return get_statistics_cockpit_web(include_details=False)

def invalidate_statistics_cache():
    """Invalide le cache des statistiques (à appeler après création/modification d'équipements)"""
    try:
        cache.delete("dashboard_stats:detailed_True")
        cache.delete("dashboard_stats:detailed_False")
        logger.info("✅ Cache des statistiques invalidé")
    except Exception as e:
        logger.error(f"❌ Erreur invalidation cache stats: {e}")