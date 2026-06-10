# Fonction utilitaire pour la pagination
from typing import Any, Dict, List, Optional, Generic, TypeVar
from pydantic import BaseModel

T = TypeVar('T')


class RestResponse(BaseModel, Generic[T]):
    """Réponse REST standardisée"""
    success: bool = True
    data: Optional[T] = None
    message: Optional[str] = None
    error: Optional[str] = None


def create_pagination_response(pagination_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Créer une réponse paginée standardisée à partir d'un PaginationResult
    
    Args:
        pagination_result: Résultat de pagination de la base de données
        
    Returns:
        Réponse formatée pour l'API
    """
    return {
        "data": pagination_result["data"],
        "pagination": {
            "current_page": pagination_result["page"],
            "per_page": pagination_result["page_size"],
            "total_items": pagination_result["total_count"],
            "total_pages": pagination_result["total_pages"],
            "has_next": pagination_result["has_next"],
            "has_prev": pagination_result["has_prev"]
        }
    }


def create_simple_response(data: List[Any], message: str = "Success", success: bool = True) -> Dict[str, Any]:
    """
    Créer une réponse simple pour les données non paginées
    
    Args:
        data: Données à retourner
        message: Message de statut
        
    Returns:
        Réponse formatée
    """
    return {
        "success": success,
        "data": data,
        "count": len(data),
        "message": message
    }