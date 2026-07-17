import logging
from typing import List, Optional, Dict, Any
from fastapi import HTTPException

from app.repositories.base import AbstractWorkOrderRepository

logger = logging.getLogger(__name__)

class OTService:
    """Service métier pour gérer les ordres de travail (OT)."""
    
    def __init__(self, repository: Optional[AbstractWorkOrderRepository] = None):
        if repository is None:
            # Fallback de compatibilité : instanciation dynamique selon la configuration
            from app.core import config
            from app.repositories.coswin_api import CoswinAPIWorkOrderRepository
            from app.repositories.local_sql import LocalSQLWorkOrderRepository
            from app.db.sqlalchemy.engine import SessionLocalMock
            
            logger.warning("Instanciation de OTService sans repository fourni. Utilisation de la configuration par defaut.")
            if config.DATA_SOURCE == "local":
                db = SessionLocalMock()
                self.repository = LocalSQLWorkOrderRepository(db)
            else:
                self.repository = CoswinAPIWorkOrderRepository()
        else:
            self.repository = repository
            
    # ========== WORKORDERS ==========
    async def get_all_workorders(
        self,
        scope: str = "mine",
        supervisor_code: Optional[str] = None,
        request_entity: Optional[str] = None,
        exclude_closed: bool = True,
        pagination_context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Récupère la liste des ordres de travail (filtrée, paginée)."""
        # Validation des entrées selon la portée (scope) demandée
        if scope == "mine" and not supervisor_code:
            raise HTTPException(
                status_code=400,
                detail="supervisor_code est requis pour scope='mine'.",
            )
        if scope == "service" and not request_entity:
            raise HTTPException(
                status_code=400,
                detail="request_entity est requis pour scope='service'.",
            )
            
        return await self.repository.get_all_workorders(
            scope=scope,
            supervisor_code=supervisor_code,
            request_entity=request_entity,
            exclude_closed=exclude_closed,
            pagination_context=pagination_context
        )

    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """Récupère un ordre de travail par son code unique."""
        return await self.repository.get_workorder_by_code(code)

    async def create_workorder(self, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Crée un nouvel ordre de travail."""
        return await self.repository.create_workorder(workorder_data)

    async def update_workorder(self, code: str, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Met à jour un ordre de travail existant."""
        return await self.repository.update_workorder(code, workorder_data)

    async def delete_workorder(self, code: str) -> Dict[str, Any]:
        """Supprime un ordre de travail."""
        return await self.repository.delete_workorder(code)

    # ========== EQUIPMENT & LOCATIONS ==========
    async def get_all_equipment(self) -> List[Dict[str, Any]]:
        return await self.repository.get_all_equipment()

    async def get_equipment_by_code(self, code: str) -> Dict[str, Any]:
        return await self.repository.get_equipment_by_code(code)

    async def get_all_locations(self) -> List[Dict[str, Any]]:
        return await self.repository.get_all_locations()

    async def get_location_by_code(self, code: str) -> Dict[str, Any]:
        return await self.repository.get_location_by_code(code)

    # ========== SUB-RESOURCES ==========
    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_operations_by_workorder(workorder_code)

    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_workforce_by_workorder(workorder_code)

    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_documents_by_workorder(workorder_code)

    async def get_actions_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_actions_by_workorder(workorder_code)

    async def get_allocated_employees_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_allocated_employees_by_workorder(workorder_code)

    async def get_employee_feedbacks_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_employee_feedbacks_by_workorder(workorder_code)

    async def get_stock_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_stock_used_by_workorder(workorder_code)

    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_parts_by_workorder(workorder_code)

    async def get_attributes_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_attributes_by_workorder(workorder_code)

    async def get_facilities_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_facilities_used_by_workorder(workorder_code)

    async def get_services_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.repository.get_services_used_by_workorder(workorder_code)

    # ========== SUB-RESOURCES CRUD ==========
    async def create_operation(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.create_operation(workorder_code, data)

    async def update_operation(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.update_operation(workorder_code, pk, data)

    async def delete_operation(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self.repository.delete_operation(workorder_code, pk)

    async def create_document(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.create_document(workorder_code, data)

    async def update_document(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.update_document(workorder_code, pk, data)

    async def delete_document(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self.repository.delete_document(workorder_code, pk)

    async def create_workforce(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.create_workforce(workorder_code, data)

    async def update_workforce(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.update_workforce(workorder_code, pk, data)

    async def delete_workforce(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self.repository.delete_workforce(workorder_code, pk)

    async def create_part(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.create_part(workorder_code, data)

    async def update_part(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.update_part(workorder_code, pk, data)

    async def delete_part(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self.repository.delete_part(workorder_code, pk)

    async def create_attribute(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.create_attribute(workorder_code, data)

    async def update_attribute(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.repository.update_attribute(workorder_code, pk, data)

    async def delete_attribute(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self.repository.delete_attribute(workorder_code, pk)


# Instance globale pour compatibilité ascendante (fallback)
ot_service = OTService()