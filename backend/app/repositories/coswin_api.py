import asyncio
import logging
import httpx
from typing import List, Optional, Dict, Any
from fastapi import HTTPException
from urllib.parse import urlencode
from datetime import datetime

from app.core.config import (
    OT_API_BASE_URL,
    OT_API_USERNAME,
    OT_API_PASSWORD,
    OT_DATASOURCE,
    OT_CWUSER,
)
from app.repositories.base import AbstractWorkOrderRepository

logger = logging.getLogger(__name__)

class CoswinAPIWorkOrderRepository(AbstractWorkOrderRepository):
    """Implémentation d'accès aux données via les Web Services REST de Coswin (Senelec)."""
    
    def __init__(self):
        self.base_url = OT_API_BASE_URL
        self.username = OT_API_USERNAME
        self.password = OT_API_PASSWORD
        self.datasource = OT_DATASOURCE
        self.cwuser = OT_CWUSER
        
        self._digest_auth = None
        if self.username and self.password:
            self._digest_auth = httpx.DigestAuth(self.username, self.password)
        
        self.headers = {
            "Accept": "application/json"
        }
        
    def _build_url(self, endpoint: str, **params) -> str:
        """Construit l'URL complète avec les paramètres requis."""
        all_params = {
            "dataSource": self.datasource,
            "cwUser": self.cwuser,
            **params
        }
        query_string = urlencode(all_params, doseq=True, safe=':/')
        return f"{self.base_url}{endpoint}?{query_string}"

    async def _make_request(
        self,
        method: str,
        endpoint: str,
        params: Optional[Dict] = None,
        json_data: Optional[Dict] = None
    ) -> Any:
        """Effectue une requête HTTP vers l'API Coswin."""
        url = self._build_url(endpoint, **(params or {}))
        logger.info(f"➡️ Repo API OT: {method} {url}")

        try:
            async with httpx.AsyncClient(timeout=30.0, trust_env=False) as client:
                request_kwargs = {
                    "headers": self.headers,
                    "json": json_data,
                }
                if self._digest_auth:
                    request_kwargs["auth"] = self._digest_auth
                
                response = await client.request(method, url, **request_kwargs)

            logger.info(
                f"⬅️ Repo API OT Réponse: {response.status_code} "
                f"({len(response.content)} octets) pour {url}"
            )

            if response.status_code == 401:
                raise HTTPException(
                    status_code=401,
                    detail="Authentification échouée avec l'API Coswin"
                )
            if response.status_code == 404:
                logger.warning(f"404 Coswin sur {url} — corps: {response.text[:500]}")
                raise HTTPException(
                    status_code=404,
                    detail=f"Ressource non trouvée dans l'API Coswin (url={url})"
                )
            if response.status_code >= 400:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Erreur API Coswin: {response.text}"
                )

            try:
                return response.json()
            except Exception:
                return response.text

        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="Timeout lors de l'appel à l'API Coswin"
            )
        except httpx.RequestError as e:
            raise HTTPException(
                status_code=503,
                detail=f"Erreur de connexion à l'API Coswin: {str(e)}"
            )

    def _passes_filters(
        self,
        row: Dict[str, Any],
        supervisor_code: Optional[str],
        request_entity: Optional[str],
        exclude_closed: bool,
    ) -> bool:
        """Applique les filtres métier à une ligne d'OT."""
        if supervisor_code and str(row.get("wowoSupervisor", "")) != str(supervisor_code):
            return False
        if request_entity and str(row.get("wowoRequestEntity", "")).upper() != str(request_entity).upper():
            return False
        if exclude_closed and str(row.get("wowoUserStatus", "")).upper() == "CL":
            return False
        return True

    def _estimate_starting_wowo_code(self) -> int:
        """Calcule le code de départ estimé pour récupérer les OT récents."""
        base_date = datetime(2026, 1, 1).date()
        base_seq = 253020
        daily_rate = 165
        now_dt = datetime.now()
        current_year = now_dt.year
        current_date = now_dt.date()
        days_diff = (current_date - base_date).days
        if days_diff < 0:
            days_diff = 0
        estimated_seq = base_seq + int(days_diff * daily_rate)
        estimated_max_code = (current_year * 1000000) + (estimated_seq % 1000000)
        return estimated_max_code - 150

    async def _fetch_workorders_page(
        self,
        params: Dict[str, Any],
        page_limit: int,
        supervisor_code: Optional[str],
        request_entity: Optional[str],
        exclude_closed: bool,
    ) -> Dict[str, Any]:
        """Parcourt récursivement les pages Coswin pour extraire les OT filtrés."""
        matched: List[Dict[str, Any]] = []
        pages_fetched = 0
        more_data = False
        pag_context = params.get("paginationContext")

        while True:
            temp_params = dict(params)
            if pag_context:
                temp_params["paginationContext"] = pag_context

            page_response = await self._make_request("GET", "/workorders", params=temp_params)
            pages_fetched += 1

            page_list = (page_response or {}).get("list", {}).get("workorderfind", [])
            for row in page_list:
                if self._passes_filters(row, supervisor_code, request_entity, exclude_closed):
                    matched.append(row)

            more_data = bool((page_response or {}).get("moreDataAvailable"))
            pag_context = (page_response or {}).get("paginationContext")

            if not more_data or not pag_context or pages_fetched >= page_limit:
                break

        return {
            "workorders": matched,
            "paginationContext": pag_context,
            "hasMore": more_data,
        }

    async def get_all_workorders(
        self,
        scope: str = "mine",
        supervisor_code: Optional[str] = None,
        request_entity: Optional[str] = None,
        exclude_closed: bool = True,
        pagination_context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Récupère une page d'OT via l'API Senelec."""
        if scope == "mine":
            params = {
                "usePagination": "true",
                "filterColumn": "wowoSupervisor",
                "filterOperator": "equals",
                "filterOperand1": str(supervisor_code)
            }
            if pagination_context:
                params["paginationContext"] = pagination_context
            
            res = await self._fetch_workorders_page(
                params,
                page_limit=2,
                supervisor_code=supervisor_code,
                request_entity=request_entity,
                exclude_closed=exclude_closed
            )
            matched = res["workorders"]
            matched.sort(key=lambda x: int(x.get("wowoCode") or 0), reverse=True)
            has_more = res["hasMore"]
            next_token = res["paginationContext"] if has_more else None
        else:
            BLOCK_SIZE = 2000
            if pagination_context and pagination_context.startswith("custom_prev_code:"):
                try:
                    current_upper = int(pagination_context.split(":")[1])
                except ValueError:
                    current_upper = self._estimate_starting_wowo_code() + 150
            else:
                current_upper = self._estimate_starting_wowo_code() + 150
                
            current_lower = current_upper - BLOCK_SIZE
            if current_lower < 2018000000:
                current_lower = 2018000000
                
            matched = []
            blocks_searched = 0
            
            while len(matched) < 15 and blocks_searched < 4 and current_upper > 2018000000:
                blocks_searched += 1
                upper_bound = 3000000000 if (blocks_searched == 1 and not pagination_context) else (current_upper - 1)
                
                params = {
                    "usePagination": "true",
                    "filterOperator": "between",
                    "filterOperand1": str(current_lower),
                    "filterOperand2": str(upper_bound)
                }
                
                page_response = await self._make_request("GET", "/workorders", params=params)
                page_list = (page_response or {}).get("list", {}).get("workorderfind", [])
                
                block_matched = []
                for row in page_list:
                    if self._passes_filters(row, supervisor_code, request_entity, exclude_closed):
                        block_matched.append(row)
                
                block_matched.sort(key=lambda x: int(x.get("wowoCode") or 0), reverse=True)
                matched.extend(block_matched)
                
                current_upper = current_lower
                current_lower = current_upper - BLOCK_SIZE
                if current_lower < 2018000000:
                    current_lower = 2018000000
            
            has_more = current_upper > 2018000000
            next_token = f"custom_prev_code:{current_upper}" if has_more else None

        # Dédoublonnage
        seen_codes = set()
        unique_matched = []
        for row in matched:
            code = row.get("wowoCode")
            if code not in seen_codes:
                seen_codes.add(code)
                unique_matched.append(row)
        matched = unique_matched

        return {
            "workorders": matched,
            "paginationContext": next_token,
            "hasMore": has_more,
        }

    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """Trouve un OT par son code."""
        return await self._make_request("GET", f"/workorders/{code}")

    async def create_workorder(self, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Crée un nouvel OT."""
        return await self._make_request("POST", "/workorders", json_data=workorder_data)

    async def update_workorder(self, code: str, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Met à jour un OT existant."""
        return await self._make_request("PUT", f"/workorders/{code}", json_data=workorder_data)

    async def delete_workorder(self, code: str) -> Dict[str, Any]:
        """Supprime un OT."""
        return await self._make_request("DELETE", f"/workorders/{code}")

    # ========== EQUIPMENT & LOCATIONS ==========
    async def get_all_equipment(self) -> List[Dict[str, Any]]:
        return await self._make_request("GET", "/equipment")

    async def get_equipment_by_code(self, code: str) -> Dict[str, Any]:
        return await self._make_request("GET", f"/equipment/{code}")

    async def get_all_locations(self) -> List[Dict[str, Any]]:
        return await self._make_request("GET", "/locations")

    async def get_location_by_code(self, code: str) -> Dict[str, Any]:
        return await self._make_request("GET", f"/locations/{code}")

    # ========== SUB-RESOURCES ==========
    async def _get_workorder_relation(self, workorder_code: str, relation_name: str, table_key: Optional[str] = None) -> List[Dict[str, Any]]:
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/{relation_name}")
        if not isinstance(resp, dict):
            return []
        if table_key:
            return resp.get(table_key, [])
        keys = [k for k in resp.keys() if k != "wowoCode"]
        if keys:
            return resp.get(keys[0], [])
        return []

    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_actions_by_workorder(workorder_code)

    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_allocated_employees_by_workorder(workorder_code)

    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_employee_feedbacks_by_workorder(workorder_code)

    async def get_actions_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "actions", "workActionViewwoActionsView")

    async def get_allocated_employees_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "allocatedemployees", "employeeAllocatedViewwoEmpAllocView")

    async def get_employee_feedbacks_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "employeefeedbacks", "employeeFeedbackViewwoFeedbackView")

    async def get_stock_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "stockused", "stockUsedViewwoStockView")

    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_stock_used_by_workorder(workorder_code)

    async def get_attributes_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "attributes", "workOrderCurrentSetAttributeViewwoAttributeView")

    async def get_facilities_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "facilitiesused")

    async def get_services_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        try:
            return await self._get_workorder_relation(workorder_code, "servicesused")
        except Exception:
            try:
                return await self._get_workorder_relation(workorder_code, "services")
            except Exception:
                pass
        return []

    # ========== SUB-RESOURCES CRUD (NOT SUPPORTED BY REAL COSWIN API) ==========
    async def create_operation(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Writing sub-resources is not supported on production API")

    async def update_operation(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Modifying sub-resources is not supported on production API")

    async def delete_operation(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Deleting sub-resources is not supported on production API")

    async def create_document(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Writing sub-resources is not supported on production API")

    async def update_document(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Modifying sub-resources is not supported on production API")

    async def delete_document(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Deleting sub-resources is not supported on production API")

    async def create_workforce(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Writing sub-resources is not supported on production API")

    async def update_workforce(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Modifying sub-resources is not supported on production API")

    async def delete_workforce(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Deleting sub-resources is not supported on production API")

    async def create_part(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Writing sub-resources is not supported on production API")

    async def update_part(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Modifying sub-resources is not supported on production API")

    async def delete_part(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Deleting sub-resources is not supported on production API")

    async def create_attribute(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Writing sub-resources is not supported on production API")

    async def update_attribute(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Modifying sub-resources is not supported on production API")

    async def delete_attribute(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        raise HTTPException(status_code=501, detail="Deleting sub-resources is not supported on production API")
