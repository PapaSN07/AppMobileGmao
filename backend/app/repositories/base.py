from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional

class AbstractWorkOrderRepository(ABC):
    @abstractmethod
    async def get_all_workorders(
        self,
        scope: str = "mine",
        supervisor_code: Optional[str] = None,
        request_entity: Optional[str] = None,
        exclude_closed: bool = True,
        pagination_context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Récupère la liste des ordres de travail (filtrée, paginée)."""
        pass

    @abstractmethod
    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """Récupère un ordre de travail par son code unique."""
        pass

    @abstractmethod
    async def create_workorder(self, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Crée un nouvel ordre de travail."""
        pass

    @abstractmethod
    async def update_workorder(self, code: str, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Met à jour un ordre de travail existant."""
        pass

    @abstractmethod
    async def delete_workorder(self, code: str) -> Dict[str, Any]:
        """Supprime un ordre de travail."""
        pass

    # ========== EQUIPMENT & LOCATIONS ==========
    @abstractmethod
    async def get_all_equipment(self) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_equipment_by_code(self, code: str) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def get_all_locations(self) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_location_by_code(self, code: str) -> Dict[str, Any]:
        pass

    # ========== SUB-RESOURCES ==========
    @abstractmethod
    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_actions_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_allocated_employees_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_employee_feedbacks_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_stock_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_attributes_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_facilities_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    @abstractmethod
    async def get_services_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        pass

    # ========== SUB-RESOURCES CRUD ==========
    @abstractmethod
    async def create_operation(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def update_operation(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def delete_operation(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def create_document(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def update_document(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def delete_document(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def create_workforce(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def update_workforce(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def delete_workforce(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def create_part(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def update_part(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def delete_part(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def create_attribute(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def update_attribute(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    async def delete_attribute(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        pass
