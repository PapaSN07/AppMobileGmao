from datetime import datetime
import logging
from fastapi import APIRouter, Depends, Query

from app.dependencies import get_current_user
from app.services.statistique_service import get_statistics_cockpit_web, get_statistics_summary
from app.schemas.responses.statistics_response import DashboardStatisticsResponse, EquipmentStats

logger = logging.getLogger(__name__)

statistique_router_web = APIRouter(
    prefix="/statistics",
    tags=["Statistiques - Dashboard Web"],
)

@statistique_router_web.get(
    "",
    response_model=DashboardStatisticsResponse,
    summary="Statistiques du dashboard",
    description="Récupère toutes les statistiques pour le dashboard web (avec cache de 5 minutes)"
)
async def get_dashboard_statistics(
    include_details: bool = Query(
        default=False,
        description="Si True, inclut les stats détaillées par entité/famille/utilisateur"
    ),
    current_user: dict = Depends(get_current_user)
):
    """
    Récupère les statistiques complètes du dashboard
    
    - **total_gmao**: Nombre d'équipements dans GMAO (DB Main)
    - **total_temp**: Nombre d'équipements en attente (DB Temp)
    - **new_equipments**: Équipements ajoutés (is_new=True)
    - **updated_equipments**: Équipements modifiés (is_update=True)
    - **approved_equipments**: Équipements approuvés
    - **rejected_equipments**: Équipements rejetés
    - **pending_validation**: Équipements en attente de validation
    - **archived_equipments**: Équipements archivés
    
    Si `include_details=True`, inclut également :
    - **stats_by_entity**: Statistiques par entité (HCAU, HCAS, etc.)
    - **stats_by_family**: Top 10 des familles d'équipements
    - **stats_by_user**: Statistiques par utilisateur (créations/modifications)
    """
    try:
        logger.info(f"📊 Requête de statistiques (details={include_details}) par user {current_user.get('username')}")
        
        stats = get_statistics_cockpit_web(include_details=include_details)
        
        return stats
        
    except Exception as e:
        logger.error(f"❌ Erreur endpoint statistiques: {e}")
        return DashboardStatisticsResponse(
            success=False,
            message=f"Erreur interne: {str(e)}",
            equipment_stats=EquipmentStats(
                total_gmao=0,
                total_temp=0,
                new_equipments=0,
                updated_equipments=0,
                approved_equipments=0,
                rejected_equipments=0,
                pending_validation=0,
                archived_equipments=0
            ),
            last_updated=datetime.now().isoformat() + "Z"
        )

@statistique_router_web.get(
    "/summary",
    summary="Résumé des statistiques (version légère)",
    description="Récupère uniquement les statistiques principales sans les détails"
)
async def get_statistics_summary_endpoint(
    current_user: dict = Depends(get_current_user)
):
    """Version allégée des statistiques (sans détails par entité/famille/utilisateur)"""
    try:
        logger.info(f"📊 Requête de résumé statistiques par user {current_user.get('username')}")
        
        stats = get_statistics_summary()
        
        return stats
        
    except Exception as e:
        logger.error(f"❌ Erreur endpoint résumé statistiques: {e}")
        return {
            "success": False,
            "message": f"Erreur interne: {str(e)}"
        }