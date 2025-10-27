from pydantic import BaseModel, Field
from typing import Optional, Dict, List

class EquipmentStats(BaseModel):
    """Statistiques des équipements"""
    total_gmao: int = Field(..., description="Nombre total d'équipements dans GMAO (DB Main)")
    total_temp: int = Field(..., description="Nombre total d'équipements en attente (DB Temp)")
    new_equipments: int = Field(..., description="Nombre d'équipements ajoutés (is_new=True)")
    updated_equipments: int = Field(..., description="Nombre d'équipements modifiés (is_update=True)")
    approved_equipments: int = Field(..., description="Nombre d'équipements approuvés")
    rejected_equipments: int = Field(..., description="Nombre d'équipements rejetés")
    pending_validation: int = Field(..., description="Équipements en attente de validation")
    archived_equipments: int = Field(..., description="Nombre d'équipements archivés (Historique)")

class EntityStats(BaseModel):
    """Statistiques par entité"""
    entity: str
    count: int

class FamilyStats(BaseModel):
    """Statistiques par famille"""
    family: str
    count: int

class UserStats(BaseModel):
    """Statistiques par utilisateur"""
    username: str
    new_count: int = Field(default=0, description="Nombre d'équipements créés")
    update_count: int = Field(default=0, description="Nombre d'équipements modifiés")

class DashboardStatisticsResponse(BaseModel):
    """Réponse complète des statistiques du dashboard"""
    success: bool
    message: str
    equipment_stats: EquipmentStats
    stats_by_entity: Optional[List[EntityStats]] = None
    stats_by_family: Optional[List[FamilyStats]] = None
    stats_by_user: Optional[List[UserStats]] = None
    last_updated: str = Field(..., description="Date/heure de dernière mise à jour (ISO 8601)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "Statistiques récupérées avec succès",
                "equipment_stats": {
                    "total_gmao": 15000,
                    "total_temp": 250,
                    "new_equipments": 120,
                    "updated_equipments": 130,
                    "approved_equipments": 200,
                    "rejected_equipments": 15,
                    "pending_validation": 35,
                    "archived_equipments": 5000
                },
                "stats_by_entity": [
                    {"entity": "HCAU", "count": 150},
                    {"entity": "HCAS", "count": 100}
                ],
                "stats_by_family": [
                    {"family": "TRANSFORMATEURS", "count": 50},
                    {"family": "DISJONCTEURS", "count": 30}
                ],
                "stats_by_user": [
                    {"username": "nafissatou.diack", "new_count": 45, "update_count": 20}
                ],
                "last_updated": "2025-10-24T11:30:00Z"
            }
        }