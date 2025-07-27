from fastapi import APIRouter, Query, HTTPException, Path, status
from typing import Optional, Dict, Any
import logging

from app.services.equipment_service import (
    get_equipments,
    get_equipments_paginated,
    get_equipments_filtered,
    get_zones,
    get_familles,
    get_entities,
    get_equipment_by_id,
    get_equipment_stats,
    invalidate_all_cache,
    refresh_reference_data
)
from app.core.cache import get_cache_stats
from app.models.models import EquipmentFilterModel

# Configuration du logging
logger = logging.getLogger(__name__)

# Création du routeur
equipment_router = APIRouter(
    prefix="/equipments",
    tags=["Équipements"],
    responses={
        404: {"description": "Équipement non trouvé"},
        500: {"description": "Erreur interne du serveur"},
    },
)

@equipment_router.get("/", 
    summary="Récupérer les équipements avec filtres et pagination",
    description="Endpoint principal pour récupérer les équipements avec filtres avancés et pagination",
    response_description="Liste paginée des équipements avec métadonnées"
)
async def read_equipments_filtered(
    page: int = Query(1, ge=1, description="Numéro de la page (commence à 1)"),
    page_size: int = Query(20, ge=1, le=100, description="Nombre d'éléments par page (max 100)"),
    zone: Optional[str] = Query(None, description="Filtrer par zone géographique"),
    famille: Optional[str] = Query(None, description="Filtrer par famille d'équipement"),
    entity: Optional[str] = Query(None, description="Filtrer par entité responsable"),
    search: Optional[str] = Query(None, description="Recherche textuelle dans le code et la description")
) -> Dict[str, Any]:
    """
    Récupère les équipements avec filtres avancés et pagination.
    
    **Paramètres de filtrage disponibles :**
    - `zone` : Filtrer par zone géographique
    - `famille` : Filtrer par famille d'équipement 
    - `entity` : Filtrer par entité responsable
    - `search` : Recherche textuelle dans le code et la description
    
    **Pagination :**
    - `page` : Numéro de page (défaut: 1)
    - `page_size` : Taille de page (défaut: 20, max: 100)
    """
    try:
        logger.info(f"🔍 Recherche équipements - Page: {page}, Size: {page_size}, Filtres: zone={zone}, famille={famille}, entity={entity}, search={search}")
        
        result = get_equipments_filtered(
            page=page,
            page_size=page_size,
            zone=zone,
            famille=famille,
            entity=entity,
            search_term=search
        )
        
        logger.info(f"✅ {len(result['equipments'])} équipements retournés")
        return result
        
    except ValueError as e:
        logger.warning(f"⚠️ Paramètres invalides: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Paramètres de requête invalides: {str(e)}"
        )
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des équipements: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur interne lors de la récupération des équipements"
        )

@equipment_router.get("/all",
    summary="Récupérer tous les équipements avec limite",
    description="Récupère une liste simple d'équipements avec limitation optionnelle"
)
async def read_all_equipments(
    limit: int = Query(10, ge=1, le=1000, description="Nombre maximum d'équipements à retourner")
) -> Dict[str, Any]:
    """
    Récupère une liste simple d'équipements avec limitation.
    
    **Paramètres :**
    - `limit` : Nombre maximum d'équipements (défaut: 10, max: 1000)
    """
    try:
        logger.info(f"📋 Récupération simple avec limite: {limit}")
        
        equipments = get_equipments(limit=limit)
        
        return {
            "equipments": equipments,
            "count": len(equipments),
            "limit": limit,
            "message": "Équipements récupérés avec succès"
        }
        
    except ValueError as e:
        logger.warning(f"⚠️ Limite invalide: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"❌ Erreur get_equipments: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des équipements"
        )

@equipment_router.get("/paginated",
    summary="Récupérer les équipements avec pagination simple",
    description="Pagination basique sans filtres"
)
async def read_equipments_paginated(
    page: int = Query(1, ge=1, description="Numéro de la page"),
    page_size: int = Query(10, ge=1, le=100, description="Nombre d'éléments par page")
) -> Dict[str, Any]:
    """
    Récupère les équipements avec pagination simple (sans filtres).
    """
    try:
        logger.info(f"📄 Pagination simple - Page: {page}, Size: {page_size}")
        
        result = get_equipments_paginated(page=page, page_size=page_size)
        
        logger.info(f"✅ Page {result['pagination']['page']}/{result['pagination']['total_pages']} récupérée")
        return result
        
    except ValueError as e:
        logger.warning(f"⚠️ Paramètres pagination invalides: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"❌ Erreur pagination: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la pagination"
        )

@equipment_router.get("/{equipment_id}",
    summary="Récupérer un équipement par ID",
    description="Récupère les détails complets d'un équipement spécifique"
)
async def read_equipment_by_id(
    equipment_id: str = Path(..., description="ID unique de l'équipement")
) -> Dict[str, Any]:
    """
    Récupère un équipement spécifique par son ID.
    
    **Paramètres :**
    - `equipment_id` : Identifiant unique de l'équipement
    """
    try:
        logger.info(f"🔍 Recherche équipement ID: {equipment_id}")
        
        equipment = get_equipment_by_id(equipment_id)
        
        if equipment is None:
            logger.warning(f"❓ Équipement {equipment_id} non trouvé")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Équipement avec l'ID '{equipment_id}' non trouvé"
            )
        
        logger.info(f"✅ Équipement {equipment_id} trouvé")
        return {
            "equipment": equipment,
            "message": "Équipement récupéré avec succès"
        }
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération équipement {equipment_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération de l'équipement"
        )

# Endpoints pour les données de référence

@equipment_router.get("/reference/zones",
    summary="Récupérer toutes les zones",
    description="Récupère la liste complète des zones géographiques disponibles"
)
async def read_zones() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les zones géographiques disponibles.
    """
    try:
        logger.info("🌍 Récupération des zones")
        
        zones = get_zones()
        
        logger.info(f"✅ {zones['count']} zones récupérées")
        return zones
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération zones: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des zones"
        )

@equipment_router.get("/reference/familles",
    summary="Récupérer toutes les familles",
    description="Récupère la liste complète des familles d'équipements"
)
async def read_familles() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les familles d'équipements disponibles.
    """
    try:
        logger.info("👥 Récupération des familles")
        
        familles = get_familles()
        
        logger.info(f"✅ {familles['count']} familles récupérées")
        return familles
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération familles: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des familles"
        )

@equipment_router.get("/reference/entities",
    summary="Récupérer toutes les entités",
    description="Récupère la liste complète des entités responsables"
)
async def read_entities() -> Dict[str, Any]:
    """
    Récupère la liste de toutes les entités responsables disponibles.
    """
    try:
        logger.info("🏢 Récupération des entités")
        
        entities = get_entities()
        
        logger.info(f"✅ {entities['count']} entités récupérées")
        return entities
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération entités: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des entités"
        )

# Endpoints de statistiques et administration

@equipment_router.get("/stats/general",
    summary="Statistiques générales",
    description="Récupère les statistiques générales des équipements"
)
async def read_equipment_stats() -> Dict[str, Any]:
    """
    Récupère les statistiques générales des équipements.
    
    **Inclut :**
    - Nombre total d'équipements
    - Nombre de zones, familles, entités
    - Équipements avec coordonnées GPS
    - Équipements avec feeder
    - Date de dernière mise à jour
    """
    try:
        logger.info("📊 Récupération des statistiques")
        
        stats = get_equipment_stats()
        
        logger.info("✅ Statistiques récupérées")
        return {
            "statistics": stats,
            "message": "Statistiques récupérées avec succès"
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération statistiques: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des statistiques"
        )

@equipment_router.get("/admin/cache/info",
    summary="Informations du cache",
    description="Récupère les informations détaillées sur l'état du cache Redis"
)
async def read_cache_info() -> Dict[str, Any]:
    """
    Récupère les informations détaillées sur le cache Redis.
    
    **Informations incluses :**
    - Statut de disponibilité Redis
    - Nombre de clés en cache
    - Utilisation mémoire
    - Statistiques de connexion
    """
    try:
        logger.info("🗄️ Récupération infos cache")
        
        cache_info = get_cache_stats()
        
        return {
            "cache_info": cache_info,
            "message": "Informations de cache récupérées"
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur infos cache: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de la récupération des informations de cache"
        )

@equipment_router.post("/admin/cache/invalidate",
    summary="Invalider le cache",
    description="Invalide tout le cache des équipements (nécessite privilèges admin)"
)
async def invalidate_cache() -> Dict[str, Any]:
    """
    Invalide tout le cache des équipements.
    
    **⚠️ Attention :** Cette opération vide tout le cache et peut impacter les performances
    jusqu'à ce que le cache soit reconstruit.
    """
    try:
        logger.info("🧹 Invalidation du cache")
        
        deleted_keys = invalidate_all_cache()
        
        logger.info(f"✅ Cache invalidé: {deleted_keys} clés supprimées")
        return {
            "deleted_keys": deleted_keys,
            "message": f"Cache invalidé avec succès. {deleted_keys} clés supprimées."
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur invalidation cache: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'invalidation du cache"
        )

@equipment_router.post("/admin/data/refresh",
    summary="Rafraîchir les données de référence",
    description="Force le rafraîchissement des données de référence (zones, familles, entités)"
)
async def refresh_reference_data_endpoint() -> Dict[str, Any]:
    """
    Force le rafraîchissement des données de référence.
    
    **Données rafraîchies :**
    - Liste des zones
    - Liste des familles
    - Liste des entités  
    - Statistiques générales
    """
    try:
        logger.info("🔄 Rafraîchissement des données de référence")
        
        result = refresh_reference_data()
        
        if result['status'] == 'success':
            logger.info("✅ Données de référence rafraîchies")
            return {
                "refresh_result": result,
                "message": "Données de référence rafraîchies avec succès"
            }
        else:
            logger.error(f"❌ Erreur rafraîchissement: {result.get('error', 'Erreur inconnue')}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erreur lors du rafraîchissement: {result.get('error', 'Erreur inconnue')}"
            )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"❌ Erreur rafraîchissement données: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors du rafraîchissement des données"
        )

@equipment_router.get("/health",
    summary="Vérification de santé",
    description="Endpoint de vérification de l'état de santé du service d'équipements"
)
async def health_check() -> Dict[str, Any]:
    """
    Endpoint de vérification de l'état de santé du service d'équipements.
    
    **Vérifications incluses :**
    - Statut du service
    - Disponibilité du cache Redis
    - Connectivité base de données
    """
    try:
        from app.core.cache import cache
        from app.db.database import test_connection
        
        # Test de connectivité DB
        db_status = test_connection()
        
        health_info = {
            "status": "healthy" if db_status else "degraded",
            "service": "equipment_service",
            "database_connected": db_status,
            "cache_available": cache.is_available,
            "timestamp": logger.handlers[0].formatter.formatTime(logger.makeRecord(
                logger.name, logger.level, "", 0, "", (), None
            )) if logger.handlers else "unknown"
        }
        
        status_code = status.HTTP_200_OK if db_status else status.HTTP_503_SERVICE_UNAVAILABLE
        
        return health_info
        
    except Exception as e:
        logger.error(f"❌ Erreur health check: {e}")
        return {
            "status": "unhealthy",
            "service": "equipment_service",
            "error": str(e),
            "database_connected": False,
            "cache_available": False
        }

# Endpoint de documentation personnalisée
@equipment_router.get("/docs/filters",
    summary="Documentation des filtres",
    description="Documentation détaillée des filtres disponibles pour la recherche d'équipements"
)
async def filters_documentation() -> Dict[str, Any]:
    """
    Documentation détaillée des filtres disponibles.
    """
    return {
        "available_filters": {
            "zone": {
                "description": "Filtre par zone géographique",
                "type": "string",
                "example": "DAKAR",
                "endpoint_to_get_values": "/equipments/reference/zones"
            },
            "famille": {
                "description": "Filtre par famille d'équipement", 
                "type": "string",
                "example": "LOCALITE",
                "endpoint_to_get_values": "/equipments/reference/familles"
            },
            "entity": {
                "description": "Filtre par entité responsable",
                "type": "string", 
                "example": "SDPG",
                "endpoint_to_get_values": "/equipments/reference/entities"
            },
            "search": {
                "description": "Recherche textuelle dans le code et la description",
                "type": "string",
                "example": "PIKINE",
                "note": "Recherche insensible à la casse avec correspondance partielle"
            }
        },
        "pagination": {
            "page": {
                "description": "Numéro de page (commence à 1)",
                "type": "integer",
                "default": 1,
                "minimum": 1
            },
            "page_size": {
                "description": "Nombre d'éléments par page",
                "type": "integer", 
                "default": 20,
                "minimum": 1,
                "maximum": 100
            }
        },
        "usage_examples": [
            {
                "description": "Rechercher tous les équipements de la zone DAKAR",
                "url": "/equipments/?zone=DAKAR&page=1&page_size=20"
            },
            {
                "description": "Rechercher les équipements de famille LOCALITE avec pagination",
                "url": "/equipments/?famille=LOCALITE&page=2&page_size=50"
            },
            {
                "description": "Recherche textuelle dans les descriptions",
                "url": "/equipments/?search=PIKINE&page=1&page_size=10"
            },
            {
                "description": "Combinaison de filtres",
                "url": "/equipments/?zone=DAKAR&famille=LOCALITE&search=KEUR&page=1&page_size=25"
            }
        ]
    }