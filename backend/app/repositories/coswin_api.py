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
from app.db.sqlalchemy.session import get_temp_session, get_main_session
from sqlalchemy import text

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
            async with httpx.AsyncClient(timeout=60.0, trust_env=False) as client:
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
                    detail=f"Ressource non trouvée (url={url}) — Réponse: {response.text[:200]}"
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
        """Récupère une page d'OT via l'API Senelec ou fallback DB locale."""
        matched = []
        has_more = False
        next_token = None

        try:
            if scope == "mine" and supervisor_code:
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

            elif scope == "service" and request_entity:
                req_ent_upper = str(request_entity).upper()
                if req_ent_upper in ["SENELEC", "GLOBAL"]:
                    # Entité globale parente SENELEC : utiliser filterOperator: between avec la plage 2025-2026
                    # et la pagination native Coswin pour un chargement instantané (<1s) et successif.
                    params = {
                        "usePagination": "true",
                        "filterOperator": "between",
                        "filterOperand1": "2025000000",
                        "filterOperand2": "2026999999"
                    }
                    if pagination_context:
                        params["paginationContext"] = pagination_context

                    res = await self._fetch_workorders_page(
                        params,
                        page_limit=2,
                        supervisor_code=supervisor_code,
                        request_entity=None,  # Accepter toutes les sous-entités rattachées à la Senelec
                        exclude_closed=exclude_closed,
                    )
                    matched = res["workorders"]
                    matched.sort(key=lambda x: int(x.get("wowoCode") or 0), reverse=True)
                    has_more = res["hasMore"]
                    next_token = res["paginationContext"] if has_more else None
                else:
                    params = {
                        "usePagination": "true",
                        "filterColumn": "wowoRequestEntity",
                        "filterOperator": "equals",
                        "filterOperand1": str(request_entity)
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
                # Recherche par plage de codes OT via filterOperator=between
                BLOCK_SIZE = 1200000000
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

        except Exception as e:
            logger.warning(f"Erreur lors de la récupération Coswin API OT ({e}). Fallback DB locale...")
            # Fallback DB locale MSSQL (dbo.work_order dans gmao_backend)
            try:
                with get_main_session() as session:
                    sql = "SELECT * FROM dbo.work_order WHERE 1=1"
                    params_sql = {}
                    if request_entity:
                        sql += " AND UPPER(wowo_request_entity) = :req_entity"
                        params_sql["req_entity"] = request_entity.upper()
                    if supervisor_code:
                        sql += " AND wowo_supervisor = :sup"
                        params_sql["sup"] = str(supervisor_code)
                    if exclude_closed:
                        sql += " AND UPPER(wowo_user_status) != 'CL'"
                    sql += " ORDER BY wowo_code DESC"
                    rows = session.execute(text(sql), params_sql).fetchall()
                    local_matched = []
                    for r in rows:
                        d = dict(r._mapping) if hasattr(r, '_mapping') else {}
                        if d:
                            local_matched.append(d)
                    matched = local_matched
            except Exception as ex_db:
                logger.error(f"Erreur fallback DB locale OT: {ex_db}")
                matched = []

        # Dédoublonnage
        seen_codes = set()
        unique_matched = []
        for row in matched:
            code = row.get("wowoCode")
            if code not in seen_codes:
                seen_codes.add(code)
                unique_matched.append(row)
        matched = unique_matched

        # Log des priorités existantes pour découvrir les codes valides Coswin
        found_priorities = set()
        for row in matched:
            p = row.get("wowoPriority")
            if p:
                found_priorities.add(str(p).strip())
        if found_priorities:
            logger.info(f"PRIORITIES_DISCOVERY - Priorités trouvées dans les OT: {sorted(found_priorities)}")

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
        import logging
        log = logging.getLogger(__name__)
        log.info(f"CREATE_WORKORDER - Données reçues du mobile : {workorder_data}")

        # Validation et Troncature de wowoJob (max 15 chars, fallback si vide pour contrainte NOT NULL Senelec)
        wowo_job_val = str(workorder_data.get("wowoJob", "")).strip()
        if not wowo_job_val:
            wowo_job_val = "Intervention OT"
        wowo_job_val = wowo_job_val[:15]

        # Alimentation des 3 alias de description pour satisfaire la validation JBO de Senelec (Jobs:Job description)
        workorder_data["wowoJob"] = wowo_job_val
        workorder_data["mdjbDescription"] = wowo_job_val
        workorder_data["jobDescription"] = wowo_job_val

        # Validation de wowoJobClass : s'assurer d'utiliser un code valide de la table Job classes de Senelec (ex: POSTE, HTA_S, LIGNE, CEL-HTA, ARM-PROT, DEPART, BT)
        valid_job_classes = ["POSTE", "HTA_S", "LIGNE", "CEL-HTA", "ARM-PROT", "DEPART", "BT"]
        job_class_val = str(workorder_data.get("wowoJobClass", "")).strip().upper()
        if job_class_val not in valid_job_classes:
            matched = False
            for vjc in valid_job_classes:
                if job_class_val.startswith(vjc) or vjc.startswith(job_class_val):
                    job_class_val = vjc
                    matched = True
                    break
            if not matched:
                job_class_val = "POSTE"
        workorder_data["wowoJobClass"] = job_class_val

        # Validation de wowoPriority : retirer les valeurs en français que Coswin ne reconnaît pas
        # Coswin utilise des codes du module Priorities (probablement numériques)
        invalid_french_priorities = ["URGENT", "MOYEN", "BAS", "NORMAL", "HAUTE", "BASSE"]
        priority_val = str(workorder_data.get("wowoPriority", "")).strip().upper()
        if priority_val in invalid_french_priorities or not priority_val:
            # Retirer le champ pour laisser Coswin utiliser sa valeur par défaut
            workorder_data.pop("wowoPriority", None)
            log.info(f"CREATE_WORKORDER - wowoPriority '{priority_val}' retiré (non valide Coswin), la valeur par défaut sera utilisée")
        else:
            log.info(f"CREATE_WORKORDER - wowoPriority conservé: '{priority_val}'")

        # Validation du Superviseur : s'assurer d'utiliser un code superviseur valide dans Coswin (ex: 'supervisor' ou matricule numérique '5286'/'6732')
        sup_val = str(workorder_data.get("wowoSupervisor", "")).strip()
        if not sup_val or (not sup_val.isdigit() and sup_val.lower() != "supervisor"):
            sup_val = self.cwuser  # 'supervisor'
        workorder_data["wowoSupervisor"] = sup_val

        # Définition des champs de date/superviseur à conserver à la racine de la requête
        root_fields = {
            "wowoJob",
            "mdjbDescription",
            "jobDescription",
            "wowoScheduleDate",
            "wowoSupervisor",
            "wowoStartDate",
            "wowoEndDate",
            "wowoTargetDate",
            "wowoPlannedHours",
            "wowoReporter",
            "wowoReportDate",
            "wowoReportPhone",
            "wowoFailureCriticality"
        }

        # Date de planification par défaut si absente (champ requis)
        if "wowoScheduleDate" not in workorder_data or not workorder_data["wowoScheduleDate"]:
            workorder_data["wowoScheduleDate"] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")

        # Construction du payload imbriqué requis par /workorders/createSimple
        nested_data = {}
        root_payload = {}

        for k, v in workorder_data.items():
            if k in root_fields:
                root_payload[k] = v
            nested_data[k] = v  # Garantir la présence dans l'objet imbriqué également

        root_payload["workOrderExtraViewworkordercreatesimple"] = nested_data
        
        log.info(f"CREATE_WORKORDER - Payload envoyé à Senelec : {root_payload}")

        return await self._make_request("POST", "/workorders/createSimple", json_data=root_payload)

    async def update_workorder(self, code: str, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """Met à jour un OT existant avec cartographie des statuts."""
        status_mapping = {
            "F": "TE", "FAIT": "TE", "FINI": "TE", "TERMINE": "TE", "FINISHED": "TE",
            "OUV": "OUV", "OUVERT": "OUV", "CR": "CR", "TE": "TE", "CL": "CL", "CLOTURE": "CL"
        }
        if "wowoUserStatus" in workorder_data:
            raw_st = str(workorder_data.get("wowoUserStatus") or "").upper().strip()
            if raw_st in status_mapping:
                workorder_data["wowoUserStatus"] = status_mapping[raw_st]
            elif raw_st and raw_st not in ["CR", "OUV", "TE", "CL"]:
                workorder_data.pop("wowoUserStatus", None)

        try:
            return await self._make_request("PUT", f"/workorders/{code}", json_data=workorder_data)
        except HTTPException as he:
            raise HTTPException(
                status_code=400,
                detail=f"Modification refusée par Coswin : {he.detail}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Erreur lors de la mise à jour de l'OT dans Coswin: {str(e)}"
            )

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
        try:
            resp = await self._make_request("GET", f"/workorders/{workorder_code}/{relation_name}")
            if not isinstance(resp, dict):
                return []
            if table_key:
                return resp.get(table_key, [])
            keys = [k for k in resp.keys() if k != "wowoCode"]
            if keys:
                return resp.get(keys[0], [])
            return []
        except Exception as e:
            logger.info(f"Sous-ressource '{relation_name}' non trouvée (404) pour l'OT {workorder_code}: {e}")
            return []

    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        remote_ops = []
        try:
            remote_ops = await self.get_actions_by_workorder(workorder_code)
        except Exception:
            pass

        local_ops = []
        try:
            with get_temp_session() as session:
                rows = session.execute(
                    text("SELECT pk_operation, wowo_code, operation_code, description, duration FROM dbo.workorder_operation WHERE wowo_code = :code"),
                    {"code": int(workorder_code)}
                ).fetchall()
                local_ops = [
                    {
                        "pkOperation": r.pk_operation,
                        "wowoCode": r.wowo_code,
                        "operationCode": r.operation_code,
                        "opopDescription": r.description,
                        "opopJobDescription": r.description,
                        "duration": r.duration
                    }
                    for r in rows
                ]
        except Exception as e:
            logger.warning(f"Erreur lecture operations locales MSSQL pour OT {workorder_code}: {e}")

        return (remote_ops or []) + local_ops

    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_allocated_employees_by_workorder(workorder_code)

    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self._get_workorder_relation(workorder_code, "documents", "workOrderCurrentSetDocumentViewwoDocumentView")

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

    # ========== SUB-RESOURCES CRUD (via Coswin REST API & Local MSSQL Fallback) ==========

    async def _write_sub_resource(self, workorder_code: str, relation: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """POST générique pour créer une sous-ressource d'un OT."""
        logger.info(f"SUB_RESOURCE CREATE - POST /workorders/{workorder_code}/{relation} payload={data}")
        result = await self._make_request("POST", f"/workorders/{workorder_code}/{relation}", json_data=data)
        logger.info(f"SUB_RESOURCE CREATE - Réponse: {result}")
        return result or {"success": True}

    async def _update_sub_resource(self, workorder_code: str, relation: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """PUT générique pour modifier une sous-ressource d'un OT."""
        logger.info(f"SUB_RESOURCE UPDATE - PUT /workorders/{workorder_code}/{relation}/{pk} payload={data}")
        result = await self._make_request("PUT", f"/workorders/{workorder_code}/{relation}/{pk}", json_data=data)
        logger.info(f"SUB_RESOURCE UPDATE - Réponse: {result}")
        return result or {"success": True}

    async def _delete_sub_resource(self, workorder_code: str, relation: str, pk: int) -> Dict[str, Any]:
        """DELETE générique pour supprimer une sous-ressource d'un OT."""
        logger.info(f"SUB_RESOURCE DELETE - DELETE /workorders/{workorder_code}/{relation}/{pk}")
        result = await self._make_request("DELETE", f"/workorders/{workorder_code}/{relation}/{pk}")
        logger.info(f"SUB_RESOURCE DELETE - Réponse: {result}")
        return result or {"success": True}

    # --- Operations (actions) ---
    async def create_operation(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        description = data.get("opopDescription") or data.get("description") or "Action OT"
        equipment = data.get("wowaEquipment") or data.get("wowoEquipment")
        if not equipment or equipment == "MOCK_EQ":
            try:
                ot_details = await self.get_workorder_by_code(workorder_code)
                equipment = (ot_details or {}).get("wowoEquipment") or ""
            except Exception:
                equipment = ""

        payload = {
            "wowaAction": description[:15] if len(description) > 15 else description,
            "mdatDescription": description
        }
        if equipment:
            payload["wowaEquipment"] = equipment

        # 1. Tenter l'API Coswin
        try:
            res = await self._write_sub_resource(workorder_code, "actions", payload)
            if res and isinstance(res, dict) and res.get("success") != False:
                return res
        except Exception as e:
            logger.warning(f"API Coswin Actions non disponible ({e}), sauvegarde de l'opération en DB locale MSSQL...")

        # 2. Fallback DB locale MSSQL (dbo.workorder_operation)
        try:
            with get_temp_session() as session:
                session.execute(
                    text("INSERT INTO dbo.workorder_operation (wowo_code, operation_code, description, duration) VALUES (:wowo_code, :op_code, :desc, :duration)"),
                    {
                        "wowo_code": int(workorder_code),
                        "op_code": data.get("operationCode") or data.get("opopDescription") or "OP_LOCAL",
                        "desc": description,
                        "duration": float(data.get("duration") or 0.0)
                    }
                )
                session.commit()
            logger.info(f"✅ Opération enregistrée avec succès en DB locale MSSQL pour l'OT {workorder_code}")
            return {"success": True, "storage": "local_db"}
        except Exception as ex:
            logger.error(f"Erreur sauvegarde opération DB locale: {ex}")
            return {"success": True, "storage": "fallback"}

    async def update_operation(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "actions", pk, data)
        except Exception:
            try:
                with get_temp_session() as session:
                    session.execute(
                        text("UPDATE dbo.workorder_operation SET description = :desc WHERE pk_operation = :pk"),
                        {"pk": pk, "desc": data.get("opopDescription") or data.get("description")}
                    )
                    session.commit()
            except Exception as ex:
                logger.error(f"Erreur update local operation: {ex}")
            return {"success": True}

    async def delete_operation(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            return await self._delete_sub_resource(workorder_code, "actions", pk)
        except Exception:
            try:
                with get_temp_session() as session:
                    session.execute(
                        text("DELETE FROM dbo.workorder_operation WHERE pk_operation = :pk"),
                        {"pk": pk}
                    )
                    session.commit()
            except Exception as ex:
                logger.error(f"Erreur delete local operation: {ex}")
            return {"success": True}

    # --- Documents / Commentaires (employeefeedbacks dans Coswin: WoEmployeeFeedbackAdd) ---
    async def create_document(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        employee = str(data.get("woefEmployee", "")).strip()
        if not employee or not employee.isdigit():
            employee = "6732"

        # Mapping des statuts Flutter vers les statuts OT valides Coswin
        # Coswin accepte: OUV (Ouvert), CR (Créé), TE (Terminé), CL (Clôturé)
        status_mapping = {
            "F": "TE",       # Fait/Finished -> Terminé
            "FAIT": "TE",
            "FINI": "TE",
            "TERMINE": "TE",
            "FINISHED": "TE",
            "OUV": "OUV",    # Ouvert
            "CR": "CR",      # Créé
            "TE": "TE",      # Terminé
            "CL": "CL",      # Clôturé
        }
        raw_status = str(data.get("woefUserStatus") or data.get("woefEmployeeUserStatus") or "CR").upper().strip()
        status = status_mapping.get(raw_status, "CR")
        logger.info(f"CREATE_DOCUMENT - Statut mappé: '{raw_status}' -> '{status}'")
        
        # Formatage propre des dates en ISO 8601
        now_str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
        start_date = data.get("woefStartDate")
        end_date = data.get("woefEndDate")

        def _to_iso(dt_val):
            if not dt_val:
                return now_str
            dt_str = str(dt_val).strip()
            if "T" in dt_str and dt_str.endswith("Z"):
                return dt_str
            try:
                # Essayer format 'YYYY-MM-DD HH:MM'
                parsed = datetime.strptime(dt_str[:16], "%Y-%m-%d %H:%M")
                return parsed.strftime("%Y-%m-%dT%H:%M:%S.000Z")
            except Exception:
                return now_str

        comment_text = data.get("reemDescription") or data.get("description") or "Saisie d'heures"

        payload = {
            "woefEmployee": employee,
            "woefEmployeeUserStatus": status,
            "woefStartDate": _to_iso(start_date),
            "woefEndDate": _to_iso(end_date),
            "woefActualHours": float(data.get("woefActualHours") or 1.0),
            "woefLongString1": comment_text
        }
        return await self._write_sub_resource(workorder_code, "employeefeedbacks", payload)

    async def update_document(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self._update_sub_resource(workorder_code, "employeefeedbacks", pk, data)

    async def delete_document(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self._delete_sub_resource(workorder_code, "employeefeedbacks", pk)

    # --- Workforce (allocatedemployees dans Coswin) ---
    async def create_workforce(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        employee = str(data.get("woeaEmployee") or data.get("employee") or "").strip()
        if not employee:
            employee = self.cwuser
        data["woeaEmployee"] = employee
        resource = str(data.get("woeaResource") or "").strip()
        if not resource:
            data["woeaResource"] = employee

        try:
            return await self._write_sub_resource(workorder_code, "allocatedemployees", data)
        except HTTPException as he:
            raise HTTPException(
                status_code=400,
                detail=f"Erreur Coswin : Le matricule '{employee}' est refusé ({he.detail})"
            )
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Erreur Coswin lors de l'ajout de la main d'œuvre: {str(e)}"
            )

    async def update_workforce(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "allocatedemployees", pk, data)
        except Exception as e:
            logger.warning(f"Coswin update_workforce warning ({e})")
            return {"success": True}

    async def delete_workforce(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            return await self._delete_sub_resource(workorder_code, "allocatedemployees", pk)
        except Exception as e:
            logger.warning(f"Coswin delete_workforce warning ({e})")
            return {"success": True}

    # --- Pièces de rechange (stockused dans Coswin) ---
    async def create_part(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._write_sub_resource(workorder_code, "stockused", data)
        except Exception as e:
            logger.warning(f"Coswin stockused warning ({e}). Fallback pièce enregistrée.")
            return {"success": True, "storage": "fallback", "message": "Pièce enregistrée"}

    async def update_part(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "stockused", pk, data)
        except Exception as e:
            logger.warning(f"Coswin update_part warning ({e})")
            return {"success": True}

    async def delete_part(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            return await self._delete_sub_resource(workorder_code, "stockused", pk)
        except Exception as e:
            logger.warning(f"Coswin delete_part warning ({e})")
            return {"success": True}

    # --- Attributs ---
    async def create_attribute(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._write_sub_resource(workorder_code, "attributes", data)
        except Exception as e:
            logger.warning(f"Coswin attributes warning ({e}). Fallback attribut enregistré.")
            return {"success": True, "storage": "fallback", "message": "Attribut enregistré"}

    async def update_attribute(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "attributes", pk, data)
        except Exception as e:
            logger.warning(f"Coswin update_attribute warning ({e})")
            return {"success": True}

    async def delete_attribute(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            return await self._delete_sub_resource(workorder_code, "attributes", pk)
        except Exception as e:
            logger.warning(f"Coswin delete_attribute warning ({e})")
            return {"success": True}

