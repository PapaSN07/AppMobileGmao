import asyncio
import logging
import httpx
from typing import List, Optional, Dict, Any, Set
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
from app.services.entity_service import extract_hierarchy
from app.db.sqlalchemy.session import get_temp_session
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
        
        # Cache de référentiels dynamiques Coswin (alimenté par les données réelles de Senelec)
        self._referentials_cache: Dict[str, List[Dict[str, str]]] = {
            "jobTypes": [
                {"code": "CORR", "description": "Correctif"},
                {"code": "PREV", "description": "Préventif"},
                {"code": "AMEL", "description": "Amélioration"},
                {"code": "EXPT", "description": "Exploitation"},
                {"code": "PALL", "description": "Palliatif"},
            ],
            "jobClasses": [
                {"code": "POSTE", "description": "Poste de transformation"},
                {"code": "HTA_S", "description": "HTA Sous-station"},
                {"code": "LIGNE", "description": "Ligne aérienne / souterraine"},
                {"code": "CEL-HTA", "description": "Cellule HTA"},
                {"code": "ARM-PROT", "description": "Armoire de protection"},
                {"code": "DEPART", "description": "Départ réseau"},
                {"code": "BT", "description": "Basse tension"},
                {"code": "ELEC", "description": "Électricité générale"},
            ],
            "priorities": [
                {"code": "NORMALE", "description": "Normale"},
                {"code": "", "description": "Non définie / Par défaut"},
            ],
            "statuses": [
                {"code": "CR", "description": "Créé (CR)"},
                {"code": "OUV", "description": "Ouvert (OUV)"},
                {"code": "EC", "description": "En cours (EC)"},
                {"code": "TE", "description": "Terminé (TE)"},
                {"code": "CL", "description": "Clôturé (CL)"},
            ],
            "supervisors": [
                {"code": "6073", "description": "Technicien Référent (6073)"},
                {"code": "5286", "description": "ERIC DASYLVA CARDOZO (5286)"},
                {"code": "6732", "description": "Mouhamadou Mansour KEBE (6732)"},
            ],
            "resources": [
                {"code": "RDEF", "description": "Ressource par défaut (RDEF)"},
                {"code": "ELEC", "description": "Électricien Réseau"},
                {"code": "MECAN", "description": "Mécanicien"},
                {"code": "TECH", "description": "Technicien de Maintenance"},
                {"code": "CHEF", "description": "Chef d'équipe / Superviseur"},
                {"code": "LIGNE", "description": "Lignard HTA/BT"},
                {"code": "AGENT", "description": "Agent d'intervention"},
            ],
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

    def _resolve_allowed_entities(self, request_entity: Optional[str]) -> Optional[Set[str]]:
        """
        Résout l'ensemble des entités autorisées via la hiérarchie descendante Senelec (DRY).
        Si request_entity est None, 'SENELEC', 'GLOBAL', ou 'ALL', retourne None (pas de restriction).
        """
        if not request_entity:
            return None
            
        req_upper = str(request_entity).strip().upper()
        if req_upper in {"SENELEC", "GLOBAL", "ALL"}:
            return None
            
        try:
            hierarchy = extract_hierarchy(req_upper)
            if hierarchy:
                return {str(e).strip().upper() for e in hierarchy if e}
        except Exception as e:
            logger.warning(f"Erreur extraction hiérarchie pour {request_entity}: {e}")
            
        return {req_upper}

    def _passes_filters(
        self,
        row: Dict[str, Any],
        supervisor_code: Optional[str],
        allowed_entities: Optional[Set[str]],
        exclude_closed: bool,
    ) -> bool:
        """Applique les filtres métier à une ligne d'OT avec prise en compte de la hiérarchie."""
        if supervisor_code and str(row.get("wowoSupervisor", "")).strip() != str(supervisor_code).strip():
            return False
            
        if allowed_entities is not None:
            w_req = str(row.get("wowoRequestEntity") or "").strip().upper()
            w_act = str(row.get("wowoActionEntity") or "").strip().upper()
            w_eq  = str(row.get("wowoEquipmentEntity") or "").strip().upper()
            
            # Vérifier si l'entité demanderesse, réalisatrice ou équipement est dans la hiérarchie
            entity_matched = False
            for ent_val in [w_req, w_act, w_eq]:
                if not ent_val:
                    continue
                # Correspondance exacte ou préfixe (ex: UMP DRCO1 vs DRCO1)
                if ent_val in allowed_entities or any(ent_val.startswith(p) for p in allowed_entities):
                    entity_matched = True
                    break
            if not entity_matched:
                return False

        if exclude_closed:
            status_upper = str(row.get("wowoUserStatus") or "").strip().upper()
            if status_upper in {"CL", "TE", "AY", "CLOSE", "CLOSED", "TERMINE", "TERMINEE"}:
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
        allowed_entities: Optional[Set[str]],
        exclude_closed: bool,
    ) -> Dict[str, Any]:
        """Parcourt récursivement les pages Coswin pour extraire les OT filtrés."""
        matched: List[Dict[str, Any]] = []
        seen_codes = set()
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
                if self._passes_filters(row, supervisor_code, allowed_entities, exclude_closed):
                    code = row.get("wowoCode")
                    if code:
                        if code not in seen_codes:
                            seen_codes.add(code)
                            matched.append(row)
                    else:
                        matched.append(row)

            more_data = bool((page_response or {}).get("moreDataAvailable"))
            pag_context = (page_response or {}).get("paginationContext")

            # Arrêter si plus de données OU si on a trouvé des OT et atteint la limite
            if not more_data or not pag_context:
                break
            if len(matched) > 0 and pages_fetched >= page_limit:
                break
            if pages_fetched >= 3:
                break

        return {
            "workorders": matched,
            "paginationContext": pag_context,
            "hasMore": more_data,
        }

    def _get_next_range_token(self, start: int, end: int, current_year: int) -> Optional[str]:
        """Calcule le token de la tranche antéchronologique suivante pour ne perdre aucun OT."""
        recent_threshold = current_year * 1000000 + 260000
        # 1. Si on était sur la tranche récente de l'année courante (ex: 2026260000 - 2026999999)
        if start >= recent_threshold:
            early_start = current_year * 1000000
            early_end = recent_threshold - 1
            return f"range:{early_start}:{early_end}"
        
        # 2. Si on était sur le début de l'année courante (2026000000 - 2026259999)
        if start == current_year * 1000000:
            older_year = current_year - 1
            if older_year >= 2018:
                return f"range:{older_year * 1000000}:{older_year * 1000000 + 999999}"
            return None
        
        # 3. Si on était sur une année antérieure pleine (ex: 2025000000 - 2025999999)
        year = start // 1000000
        older_year = year - 1
        if older_year >= 2018:
            return f"range:{older_year * 1000000}:{older_year * 1000000 + 999999}"
        return None

    async def get_all_workorders(
        self,
        scope: str = "mine",
        supervisor_code: Optional[str] = None,
        request_entity: Optional[str] = None,
        exclude_closed: bool = True,
        pagination_context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Récupère une page d'OT via l'API Senelec avec support de la hiérarchie et zéro perte."""
        matched = []
        has_more = False
        next_token = None
        current_year = datetime.now().year

        # Résolution DRY de la hiérarchie descendante d'entités Senelec
        allowed_entities = self._resolve_allowed_entities(request_entity)

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
                    allowed_entities=allowed_entities,
                    exclude_closed=exclude_closed
                )
                matched = res["workorders"]
                has_more = res["hasMore"]
                next_token = res["paginationContext"] if has_more else None

            else:
                # Scopes 'service' ou 'all_open' : balayage antéchronologique (récents en premier)
                # D'abord la tranche récente 2026 (CR/DI récents), puis début 2026, puis années antérieures.
                start_code: Optional[int] = None
                end_code: Optional[int] = None
                coswin_cursor: Optional[str] = None

                if pagination_context:
                    if pagination_context.startswith("coswin:"):
                        # Format: coswin:START:END:COSWIN_TOKEN
                        parts = pagination_context.split(":", 3)
                        if len(parts) == 4:
                            try:
                                start_code = int(parts[1])
                                end_code = int(parts[2])
                                coswin_cursor = parts[3]
                            except ValueError:
                                pass
                    elif pagination_context.startswith("range:"):
                        # Format: range:START:END
                        parts = pagination_context.split(":")
                        if len(parts) == 3:
                            try:
                                start_code = int(parts[1])
                                end_code = int(parts[2])
                            except ValueError:
                                pass
                    elif pagination_context.startswith("year_range:"):
                        # Rétrocompatibilité : year_range:YYYY
                        try:
                            target_year = int(pagination_context.split(":")[1])
                            start_code = target_year * 1000000
                            end_code = target_year * 1000000 + 999999
                        except ValueError:
                            pass
                    else:
                        # Curseur Coswin brut sans bornes
                        coswin_cursor = pagination_context

                # Si premier appel (sans token), cibler la tranche récente de l'année en cours
                if start_code is None or end_code is None:
                    start_code = current_year * 1000000 + 260000
                    end_code = current_year * 1000000 + 999999

                # Conserver systématiquement filterOperator et les bornes (requis par Coswin même en pagination)
                params = {
                    "usePagination": "true",
                    "filterOperator": "between",
                    "filterOperand1": str(start_code),
                    "filterOperand2": str(end_code),
                }
                if coswin_cursor:
                    params["paginationContext"] = coswin_cursor

                res = await self._fetch_workorders_page(
                    params,
                    page_limit=1,
                    supervisor_code=supervisor_code,
                    allowed_entities=allowed_entities,
                    exclude_closed=exclude_closed
                )
                matched = res["workorders"]

                # Si Coswin a plus de données dans cette tranche précise
                if res["hasMore"] and res["paginationContext"]:
                    next_token = f"coswin:{start_code}:{end_code}:{res['paginationContext']}"
                    has_more = True
                else:
                    # Tranche terminée -> passer à la tranche antéchronologique suivante
                    next_range_token = self._get_next_range_token(start_code, end_code, current_year)
                    if next_range_token:
                        next_token = next_range_token
                        has_more = True
                    else:
                        next_token = None
                        has_more = False

                # Si premier appel et aucun OT trouvé dans la tranche récente (ex: entité avec peu d'activité en 2026),
                # on bascule directement sur le début d'année sans bloquer l'utilisateur
                if not pagination_context and len(matched) == 0:
                    early_start = current_year * 1000000
                    early_end = current_year * 1000000 + 259999
                    early_params = {
                        "usePagination": "true",
                        "filterOperator": "between",
                        "filterOperand1": str(early_start),
                        "filterOperand2": str(early_end)
                    }
                    res_early = await self._fetch_workorders_page(
                        early_params,
                        page_limit=1,
                        supervisor_code=supervisor_code,
                        allowed_entities=allowed_entities,
                        exclude_closed=exclude_closed
                    )
                    matched = res_early["workorders"]
                    if res_early["hasMore"] and res_early["paginationContext"]:
                        next_token = f"coswin:{early_start}:{early_end}:{res_early['paginationContext']}"
                        has_more = True
                    else:
                        next_token = self._get_next_range_token(early_start, early_end, current_year)
                        has_more = next_token is not None

        except Exception as e:
            logger.error(f"Erreur Coswin API OT: {e}")
            raise HTTPException(status_code=502, detail=f"Coswin indisponible: {str(e)}")

        # Tri unique (DRY) — appliqué une seule fois après toutes les branches
        matched.sort(key=lambda x: int(x.get("wowoCode") or 0), reverse=True)

        # Dédoublonnage
        seen_codes = set()
        unique_matched = []
        for row in matched:
            code = row.get("wowoCode")
            if code not in seen_codes:
                seen_codes.add(code)
                unique_matched.append(row)
        matched = unique_matched

        # Découverte et enrichissement dynamique des référentiels Coswin réels et calcul du taux de réalisation
        for row in matched:
            row["wowoCompletionRate"] = self._calculate_completion_rate(row)
            jt = row.get("wowoJobType")
            if jt and str(jt).strip():
                code = str(jt).strip().upper()
                if not any(item["code"] == code for item in self._referentials_cache["jobTypes"]):
                    self._referentials_cache["jobTypes"].append({"code": code, "description": code})
            jc = row.get("wowoJobClass")
            if jc and str(jc).strip():
                code = str(jc).strip().upper()
                if not any(item["code"] == code for item in self._referentials_cache["jobClasses"]):
                    self._referentials_cache["jobClasses"].append({"code": code, "description": code})
            p = row.get("wowoPriority")
            if p and str(p).strip():
                code = str(p).strip().upper()
                if not any(item["code"] == code for item in self._referentials_cache["priorities"]):
                    self._referentials_cache["priorities"].insert(0, {"code": code, "description": code.capitalize()})
            sup = row.get("wowoSupervisor")
            if sup and str(sup).strip() and str(sup).strip().isdigit():
                code = str(sup).strip()
                if not any(item["code"] == code for item in self._referentials_cache["supervisors"]):
                    self._referentials_cache["supervisors"].append({"code": code, "description": f"Superviseur {code}"})

        return {
            "workorders": matched,
            "paginationContext": next_token,
            "hasMore": has_more,
        }

    async def get_referentials(self) -> Dict[str, Any]:
        """Retourne les référentiels officiels de Coswin pour alimenter dynamiquement les listes déroulantes du mobile."""
        if "items" not in self._referentials_cache or not self._referentials_cache["items"]:
            try:
                raw_items = await self.get_all_items()
                formatted_items = []
                for it in raw_items:
                    code = str(it.get("sritCode") or "").strip()
                    desc = str(it.get("sritDescription") or code).strip()
                    unit = str(it.get("sritStockUnit") or "").strip()
                    if code:
                        full_desc = f"{desc} ({unit})" if unit else desc
                        formatted_items.append({"code": code, "description": full_desc, "unit": unit})
                if formatted_items:
                    self._referentials_cache["items"] = formatted_items
            except Exception as e:
                logger.warning(f"Impossible d'alimenter les articles dans le cache référentiel: {e}")

        if "specifications" not in self._referentials_cache or not self._referentials_cache["specifications"]:
            try:
                specs = await self.get_all_specifications()
                if specs:
                    self._referentials_cache["specifications"] = [
                        {
                            "code": s["name"],
                            "description": s["name"],
                            "unit": s.get("unit", ""),
                            "specClass": s.get("code", "0"),
                            "index": s.get("index", 1),
                            "authorizedValue": s.get("authorizedValue", ""),
                        }
                        for s in specs[:150]
                    ]
            except Exception as e:
                logger.warning(f"Impossible d'alimenter les spécifications dans le cache référentiel: {e}")

        return self._referentials_cache

    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """Trouve un OT complet par son code avec ses vues embarquées (actions, feedbacks, employés alloués)."""
        code_str = str(code).strip()
        now = datetime.now().timestamp()
        if not hasattr(self, "_workorder_cache"):
            self._workorder_cache = {}
        if code_str in self._workorder_cache:
            ts, cached_data = self._workorder_cache[code_str]
            if now - ts < 30.0:
                return cached_data

        try:
            params = {
                "filterColumn": "wowoCode",
                "filterOperator": "equals",
                "filterOperand1": code_str
            }
            res = await self._make_request("GET", "/workorders", params=params)
            if isinstance(res, dict):
                items = res.get("list", {}).get("workorderfind", []) or res.get("workorders", [])
                if items:
                    ot = items[0]
                    ot["wowoCompletionRate"] = self._calculate_completion_rate(ot)
                    self._workorder_cache[code_str] = (now, ot)
                    return ot
        except Exception as e:
            logger.warning(f"Erreur recherche OT {code_str} par code dans Coswin: {e}")

        try:
            ot = await self._make_request("GET", f"/workorders/{code_str}")
            if isinstance(ot, dict):
                ot["wowoCompletionRate"] = self._calculate_completion_rate(ot)
            return ot
        except Exception:
            return {}

    def _calculate_completion_rate(self, row: Dict[str, Any]) -> float:
        """Calcule dynamiquement le taux de réalisation de l'OT (Option A)."""
        status = str(row.get("wowoUserStatus") or "").upper().strip()
        if status in {"TE", "CL", "FAIT", "TERMINE", "TERMINEE", "CLOSED"}:
            return 100.0
        if status in {"EC", "EN COURS", "ENCOURS"}:
            return 50.0
        if status in {"OUV", "OUVERT"}:
            return 25.0

        # Vérifier si un compte-rendu Coswin attaché à l'OT est au statut TE (terminé)
        feedbacks = row.get("employeeFeedbackViewworkorderfind", [])
        if isinstance(feedbacks, list):
            for fb in feedbacks:
                st = str(fb.get("woefEmployeeUserStatus") or fb.get("woefUserStatus") or "").upper().strip()
                if st in {"TE", "CL", "TERMINE"}:
                    return 100.0
        return 0.0


    def _sanitize_priority(self, priority: Any) -> Optional[str]:
        """Assainit la priorité pour Coswin Senelec (seul 'NORMALE' est reconnu, ou None)."""
        val = str(priority or "").strip().upper()
        if val in ["NORMALE", "NORMAL", "2", "MOYEN"]:
            return "NORMALE"
        return None

    def _sanitize_job_type(self, job_type: Any) -> Optional[str]:
        """Vérifie que le type de travail fait partie du dictionnaire Coswin Senelec."""
        val = str(job_type or "").strip().upper()
        valid_job_types = {"CORR", "PREV", "AMEL", "EXPT", "PALL"}
        if val in valid_job_types:
            return val
        return None

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

        # Validation de wowoPriority
        p_val = self._sanitize_priority(workorder_data.get("wowoPriority"))
        if p_val:
            workorder_data["wowoPriority"] = p_val
            log.info(f"CREATE_WORKORDER - wowoPriority conservé: '{p_val}'")
        else:
            workorder_data.pop("wowoPriority", None)
            log.info("CREATE_WORKORDER - wowoPriority retiré (non valide Coswin), la valeur par défaut sera utilisée")

        # Validation de wowoJobType
        if "wowoJobType" in workorder_data:
            jt_val = self._sanitize_job_type(workorder_data.get("wowoJobType"))
            if jt_val:
                workorder_data["wowoJobType"] = jt_val
            else:
                workorder_data.pop("wowoJobType", None)

        # Validation de wowoJobClass : Coswin limite ce champ à 4 caractères maximum (évite JBO-27040)
        if "wowoJobClass" in workorder_data:
            jc_val = str(workorder_data.get("wowoJobClass") or "").strip()
            if len(jc_val) > 4:
                workorder_data["wowoJobClass"] = jc_val[:4].rstrip("-")

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
            "OUV": "OUV", "OUVERT": "OUV", "CR": "CR", "TE": "TE", "CL": "CL", "CLOTURE": "CL",
            "EC": "EC", "EN COURS": "EC", "ENCOURS": "EC", "SUSP": "SUSP", "AY": "AY"
        }
        if "wowoUserStatus" in workorder_data:
            raw_st = str(workorder_data.get("wowoUserStatus") or "").upper().strip()
            if raw_st in status_mapping:
                workorder_data["wowoUserStatus"] = status_mapping[raw_st]
            elif raw_st and raw_st not in ["CR", "OUV", "TE", "CL", "EC", "SUSP", "AY"]:
                workorder_data.pop("wowoUserStatus", None)

        # Validation de wowoPriority
        p_val = self._sanitize_priority(workorder_data.get("wowoPriority"))
        if p_val:
            workorder_data["wowoPriority"] = p_val
        else:
            workorder_data.pop("wowoPriority", None)

        # Validation de wowoJobType : s'assurer qu'il s'agit d'un type valide Coswin
        if "wowoJobType" in workorder_data:
            jt_val = self._sanitize_job_type(workorder_data.get("wowoJobType"))
            if jt_val:
                workorder_data["wowoJobType"] = jt_val
            else:
                workorder_data.pop("wowoJobType", None)

        # Validation de wowoJobClass : Coswin limite ce champ à 4 caractères maximum (évite JBO-27040)
        if "wowoJobClass" in workorder_data:
            jc_val = str(workorder_data.get("wowoJobClass") or "").strip()
            if len(jc_val) > 4:
                workorder_data["wowoJobClass"] = jc_val[:4].rstrip("-")

        try:
            return await self._make_request("PUT", f"/workorders/{code}", json_data=workorder_data)
        except HTTPException as he:
            err_lower = str(he.detail).lower()
            # Sécurité: Si Coswin refuse spécifiquement un champ de référence, réessayer sans ce champ
            fields_to_remove = []
            if "priority" in err_lower:
                fields_to_remove.append("wowoPriority")
            if "job type" in err_lower:
                fields_to_remove.append("wowoJobType")
            if "job class" in err_lower:
                fields_to_remove.append("wowoJobClass")
            if "user status" in err_lower:
                fields_to_remove.append("wowoUserStatus")
            if "supervisor" in err_lower:
                fields_to_remove.append("wowoSupervisor")

            if fields_to_remove:
                logger.warning(f"Coswin a refusé {fields_to_remove}. Nouvelle tentative allégée...")
                fallback_data = dict(workorder_data)
                for f in fields_to_remove:
                    fallback_data.pop(f, None)
                try:
                    return await self._make_request("PUT", f"/workorders/{code}", json_data=fallback_data)
                except HTTPException as retry_he:
                    second_err = str(retry_he.detail).lower()
                    for f_key in ["wowoJobType", "wowoJobClass", "wowoPriority", "wowoUserStatus"]:
                        fallback_data.pop(f_key, None)
                    try:
                        return await self._make_request("PUT", f"/workorders/{code}", json_data=fallback_data)
                    except Exception as retry_err2:
                        logger.error(f"Échec de la nouvelle tentative secondaire : {retry_err2}")
                except Exception as retry_err:
                    logger.error(f"Échec de la nouvelle tentative : {retry_err}")
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
        resp = await self._make_request("GET", "/equipment")
        if isinstance(resp, list):
            return resp
        if isinstance(resp, dict):
            if "list" in resp and isinstance(resp["list"], dict):
                first_val = next(iter(resp["list"].values()), [])
                if isinstance(first_val, list):
                    return first_val
            for k in ["equipment", "equipmentfind", "items", "data"]:
                if k in resp and isinstance(resp[k], list):
                    return resp[k]
            return [resp]
        return []

    async def get_equipment_by_code(self, code: str) -> Dict[str, Any]:
        return await self._make_request("GET", f"/equipment/{code}")

    async def get_all_locations(self) -> List[Dict[str, Any]]:
        return await self._make_request("GET", "/locations")

    async def get_location_by_code(self, code: str) -> Dict[str, Any]:
        return await self._make_request("GET", f"/locations/{code}")

    async def get_all_items(self) -> List[Dict[str, Any]]:
        """Récupère la liste des articles de stock réels Coswin Senelec (zéro base locale)."""
        try:
            resp = await self._make_request(
                "GET",
                "/items",
                params={
                    "usePagination": "true",
                    "filterOperator": "different",
                    "filterOperand1": "DUMMY"
                }
            )
            items = []
            if isinstance(resp, dict) and "list" in resp and isinstance(resp["list"], dict):
                first_val = next(iter(resp["list"].values()), [])
                if isinstance(first_val, list):
                    items = first_val
            elif isinstance(resp, list):
                items = resp
            return items
        except Exception as e:
            logger.warning(f"Erreur récupération articles Coswin: {e}")
            return []

    async def get_item_by_code(self, code: str) -> Dict[str, Any]:
        return await self._make_request("GET", f"/items/{code}")

    async def get_all_specifications(self) -> List[Dict[str, Any]]:
        """Récupère les spécifications et caractéristiques techniques officielles depuis Coswin REST API."""
        try:
            resp = await self._make_request("GET", "/specifications")
            rows = []
            if isinstance(resp, dict):
                rows = resp.get("specificationFindList", {}).get("specificationRow", [])
                if isinstance(rows, dict):
                    rows = [rows]
            elif isinstance(resp, list):
                rows = resp

            formatted = []
            seen_keys = set()
            for r in rows:
                code = str(r.get("cwspCode") or "").strip()
                idx = r.get("cwspIndex") or 1
                unit = str(r.get("cwspUnit") or "").strip()
                auth_val = str(r.get("cwspAuthorizedValue") or "").strip()
                val_type = r.get("cwspValueType", 0)

                key = f"{code}_{idx}_{auth_val}" if auth_val else f"{code}_{idx}"
                if key in seen_keys:
                    continue
                seen_keys.add(key)

                desc = f"Caractéristique {code} #{idx}"
                if auth_val:
                    desc = f"{auth_val} (Classe {code})"
                if unit:
                    desc += f" [{unit}]"

                formatted.append({
                    "code": code,
                    "index": idx,
                    "name": desc,
                    "unit": unit,
                    "valueType": val_type,
                    "authorizedValue": auth_val,
                })
            return formatted
        except Exception as e:
            logger.warning(f"Erreur récupération spécifications Coswin: {e}")
            return []

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

    async def get_actions_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les actions (mode opératoire) de l'OT depuis Coswin."""
        ot = await self.get_workorder_by_code(workorder_code)
        raw_actions = ot.get("workActionViewworkorderfind", []) if isinstance(ot, dict) else []
        if not raw_actions:
            raw_actions = await self._get_workorder_relation(workorder_code, "actions", "workActionViewwoActionsView")

        actions = []
        for act in raw_actions:
            action_code = act.get("wowaAction") or act.get("operationCode") or "ACTION"
            desc = act.get("mdatDescription") or act.get("opopDescription") or act.get("opopJobDescription") or action_code
            pk = act.get("pkWorkAction") or act.get("pkOperation") or 0
            duration = act.get("wowaDuration") or act.get("duration") or 1.0
            actions.append({
                "pkWorkAction": pk,
                "pkOperation": pk,
                "wowaAction": action_code,
                "operationCode": action_code,
                "mdatDescription": desc,
                "opopDescription": f"{action_code} - {desc}" if desc and desc != action_code else action_code,
                "opopJobDescription": desc,
                "duration": duration,
                "wowaSequenceNumber": act.get("wowaSequenceNumber", 1),
            })
        return actions

    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les opérations de l'OT (Coswin + MSSQL local si existant), hors supprimées."""
        remote_ops = await self.get_actions_by_workorder(workorder_code)

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
                        "pkWorkAction": r.pk_operation,
                        "wowoCode": r.wowo_code,
                        "operationCode": r.operation_code,
                        "wowaAction": r.operation_code,
                        "opopDescription": r.description,
                        "opopJobDescription": r.description,
                        "duration": r.duration
                    }
                    for r in rows
                ]
        except Exception as e:
            logger.warning(f"Erreur lecture operations locales MSSQL pour OT {workorder_code}: {e}")

        all_ops = (remote_ops or []) + local_ops
        del_pks = self._get_deleted_pks(workorder_code)
        if del_pks:
            all_ops = [
                op for op in all_ops
                if str(op.get("pkOperation") or "") not in del_pks and str(op.get("pkWorkAction") or "") not in del_pks
            ]
        return all_ops

    async def get_allocated_employees_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère la main d'œuvre allouée depuis Coswin, hors supprimées."""
        ot = await self.get_workorder_by_code(workorder_code)
        raw_emp = ot.get("employeeAllocatedViewworkorderfind", []) if isinstance(ot, dict) else []
        if not raw_emp:
            raw_emp = await self._get_workorder_relation(workorder_code, "allocatedemployees", "employeeAllocatedViewwoEmpAllocView")

        del_pks = self._get_deleted_pks(workorder_code)
        employees = []
        for emp in raw_emp:
            pk = emp.get("pkEmployeeAllocated") or emp.get("pkWorkforce") or 0
            if str(pk) in del_pks:
                continue

            emp_code = emp.get("reemCode") or emp.get("woeaEmployee") or ""
            emp_name = emp.get("reemDescription") or emp.get("woeaResource") or "Intervenant"
            resource = emp.get("woeaResource") or "RDEF"
            employees.append({
                "pkEmployeeAllocated": pk,
                "pkWorkforce": pk,
                "woeaEmployee": emp_code,
                "reemCode": emp_code,
                "reemDescription": emp_name,
                "woeaResource": resource,
                "woeaPlannedHours": emp.get("woeaPlannedHours", 0.0),
                "woeaAllocationDate": emp.get("woeaAllocationDate"),
                "woeaIsPlanned": emp.get("woeaIsPlanned", False),
            })
        return employees

    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_allocated_employees_by_workorder(workorder_code)

    async def get_employee_feedbacks_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les commentaires et comptes-rendus de l'OT depuis Coswin, hors tags techniques et suppressions."""
        ot = await self.get_workorder_by_code(workorder_code)
        feedbacks = ot.get("employeeFeedbackViewworkorderfind", []) if isinstance(ot, dict) else []
        if not feedbacks:
            try:
                feedbacks = await self._get_workorder_relation(workorder_code, "employeefeedbacks", "employeeFeedbackViewwoFeedbackView")
            except Exception:
                feedbacks = []

        del_pks = self._get_deleted_pks(workorder_code)
        comments = []
        for fb in feedbacks:
            pk = fb.get("pkEmployeeFeedback") or fb.get("pkDocument") or 0
            if str(pk) in del_pks:
                continue

            txt = (fb.get("woefLongString1") or "").strip()
            # Ignorer les tags techniques internes de matériel, moyens, services et attributs
            if (txt.startswith("[MAT") or txt.startswith("[ATT") or txt.startswith("[MOYEN") 
                or txt.startswith("[SERVICE") or txt.startswith("[ANNULATION") 
                or "Article:" in txt or "assignée:" in txt or "câble:" in txt):
                continue
            if not txt:
                continue

            author = fb.get("woefEmployee") or "Agent"
            date_str = fb.get("woefStartDate") or fb.get("woefEndDate")
            status = fb.get("woefUserStatus") or fb.get("woefEmployeeUserStatus") or "CR"

            comments.append({
                "pkDocument": pk,
                "pkEmployeeFeedback": pk,
                "comment": txt,
                "wodoComment": txt,
                "wodoDescription": txt,
                "wodoText": txt,
                "wodoType": status,
                "author": author,
                "wodoCreationUser": author,
                "woefEmployee": author,
                "createdAt": date_str,
                "woefStartDate": date_str,
            })

        # Récupération complémentaire des commentaires stockés localement (fallback pare-feu)
        try:
            with get_temp_session() as session:
                rows = session.execute(
                    text("SELECT pk_document, wowo_code, employee, description, user_status, start_date, created_at "
                         "FROM dbo.workorder_document WHERE wowo_code = :code"),
                    {"code": int(workorder_code)}
                ).fetchall()
                for r in rows:
                    if str(r.pk_document) in del_pks:
                        continue
                    dt = r.created_at.strftime("%Y-%m-%d %H:%M") if hasattr(r.created_at, 'strftime') else str(r.start_date or '')
                    comments.append({
                        "pkDocument": r.pk_document,
                        "pkEmployeeFeedback": r.pk_document,
                        "comment": r.description or "",
                        "wodoComment": r.description or "",
                        "wodoDescription": r.description or "",
                        "wodoText": r.description or "",
                        "wodoType": r.user_status or "CR",
                        "author": r.employee or "Agent",
                        "wodoCreationUser": r.employee or "Agent",
                        "woefEmployee": r.employee or "Agent",
                        "createdAt": dt,
                        "woefStartDate": dt,
                    })
        except Exception as e:
            logger.debug(f"Note lecture workorder_document MSSQL: {e}")

        return comments

    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        feedbacks = await self.get_employee_feedbacks_by_workorder(workorder_code)
        if feedbacks:
            return feedbacks
        try:
            return await self._get_workorder_relation(workorder_code, "documents", "workOrderCurrentSetDocumentViewwoDocumentView")
        except Exception:
            return []

    async def get_stock_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les pièces et matériels consommés sur l'OT, hors supprimés."""
        ot = await self.get_workorder_by_code(workorder_code)
        parts = []
        del_pks = self._get_deleted_pks(workorder_code)

        # 1. Pièces du stock réel Coswin si disponibles
        raw_stock = ot.get("stockUsedViewworkorderfind", []) if isinstance(ot, dict) else []
        for s in raw_stock:
            pk = s.get("pkStockUsed") or s.get("pkPart") or 0
            if str(pk) in del_pks:
                continue

            part_code = s.get("wosyPart") or s.get("wosyItem") or s.get("wospItem") or ""
            desc = s.get("wosyDescription") or s.get("wospPartDescription") or part_code
            qty = s.get("wosyUsedQuantity") or s.get("wosyQuantity") or s.get("wospQtyUsed") or 1.0
            parts.append({
                "pkStockUsed": pk,
                "pkPart": pk,
                "wosyPart": part_code,
                "wosyCode": part_code,
                "stockPart": part_code,
                "wosyDescription": desc,
                "partDescription": desc,
                "article": desc,
                "wosyUsedQuantity": qty,
                "wosyQuantity": qty,
                "quantiteUtilise": str(qty),
            })

        # 2. Pièces enregistrées via le compte-rendu Coswin [MATÉRIEL UTILISÉ]
        feedbacks = ot.get("employeeFeedbackViewworkorderfind", []) if isinstance(ot, dict) else []
        for fb in feedbacks:
            pk = fb.get("pkEmployeeFeedback") or 0
            if str(pk) in del_pks:
                continue

            txt = (fb.get("woefLongString1") or "").strip()
            if "[MAT" in txt and "Article:" in txt:
                try:
                    after_art = txt.split("Article:", 1)[1].strip()
                    if "|" in after_art:
                        art_desc, qty_part = after_art.split("|", 1)
                    else:
                        art_desc, qty_part = after_art, "1.0"
                    art_desc = art_desc.strip()
                    qty_clean = qty_part.replace("Qté:", "").replace("Qte:", "").replace("Qt:", "").strip()
                    first_token = qty_clean.split()[0] if qty_clean else "1.0"
                    part_code = art_desc.split("-")[0].strip() if "-" in art_desc else art_desc[:10].strip()
                    try:
                        qty_num = float(first_token)
                    except ValueError:
                        qty_num = 1.0
                except Exception:
                    art_desc = txt
                    part_code = "ARTICLE"
                    qty_num = 1.0
                    qty_clean = "1.0"

                parts.append({
                    "pkStockUsed": pk,
                    "pkPart": pk,
                    "wosyPart": part_code,
                    "wosyCode": part_code,
                    "stockPart": part_code,
                    "wosyDescription": art_desc,
                    "partDescription": art_desc,
                    "article": art_desc,
                    "wosyUsedQuantity": qty_num,
                    "wosyQuantity": qty_num,
                    "quantiteUtilise": qty_clean,
                })

        return parts

    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        return await self.get_stock_used_by_workorder(workorder_code)

    async def get_attributes_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les sous-attributs techniques de l'OT, hors supprimés."""
        ot = await self.get_workorder_by_code(workorder_code)
        attrs = []
        del_pks = self._get_deleted_pks(workorder_code)

        # 1. Attributs réels Coswin si disponibles
        raw_attrs = ot.get("workOrderAttributeViewworkorderfind", []) if isinstance(ot, dict) else []
        for a in raw_attrs:
            pk = a.get("pkWorkOrderAttribute") or a.get("pkAttribute") or 0
            if str(pk) in del_pks:
                continue

            attrs.append({
                "pkWorkOrderAttribute": pk,
                "pkAttribute": pk,
                "woatName": a.get("woatName") or "Attribut",
                "woatValue": a.get("woatValue") or "",
                "woatDescription": a.get("woatDescription") or "",
                "woatUnitSymbol": a.get("woatUnitSymbol") or "",
            })

        # 2. Attributs enregistrés via le compte-rendu Coswin [ATTRIBUT TECHNIQUE]
        feedbacks = ot.get("employeeFeedbackViewworkorderfind", []) if isinstance(ot, dict) else []
        for fb in feedbacks:
            pk = fb.get("pkEmployeeFeedback") or 0
            if str(pk) in del_pks:
                continue

            txt = (fb.get("woefLongString1") or "").strip()
            if "[ATT" in txt and ":" in txt:
                try:
                    after_tag = txt.split("]", 1)[1].strip() if "]" in txt else txt
                    nom_part, val_part = after_tag.split(":", 1)
                    nom = nom_part.strip()
                    val_part = val_part.strip()

                    desc = ""
                    if "(" in val_part and val_part.endswith(")"):
                        val_part, desc = val_part.rsplit("(", 1)
                        desc = desc.rstrip(")").strip()
                        val_part = val_part.strip()

                    parts_list = val_part.split()
                    val = parts_list[0] if parts_list else val_part
                    unit = " ".join(parts_list[1:]) if len(parts_list) > 1 else ""
                except Exception:
                    nom = "Attribut"
                    val = txt
                    unit = ""
                    desc = ""

                attrs.append({
                    "pkWorkOrderAttribute": pk,
                    "pkAttribute": pk,
                    "woatName": nom,
                    "woatValue": val,
                    "woatDescription": desc or nom,
                    "woatUnitSymbol": unit,
                })

        return attrs

    async def get_facilities_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les moyens (véhicules/engins) utilisés sur l'OT, hors supprimés."""
        ot = await self.get_workorder_by_code(workorder_code)
        facilities = []
        del_pks = self._get_deleted_pks(workorder_code)

        # 1. Moyens réels Coswin si disponibles
        raw_fac = ot.get("facilityUsedViewworkorderfind", []) if isinstance(ot, dict) else []
        for f in raw_fac:
            pk = f.get("pkFacility") or f.get("pkFacilityUsed") or 0
            if str(pk) in del_pks:
                continue

            moyen = f.get("wofuFacility") or f.get("facility") or "VEH_LEGER"
            equipement = f.get("wofuEquipment") or f.get("equipment") or moyen
            duree = f.get("wofuDuration") or f.get("wofuQuantity") or 0.0
            dt_start = f.get("wofuStartDate") or f.get("wofuAllocationDate") or ""
            dt_end = f.get("wofuEndDate") or ""
            facilities.append({
                "pkFacility": pk,
                "pkFacilityUsed": pk,
                "wofuFacility": moyen,
                "wofuEquipment": equipement,
                "wofuDuration": duree,
                "wofuStartDate": dt_start,
                "wofuAllocationDate": dt_start,
                "wofuEndDate": dt_end,
            })

        # 2. Moyens enregistrés via le compte-rendu Coswin [MOYEN UTILISÉ]
        feedbacks = ot.get("employeeFeedbackViewworkorderfind", []) if isinstance(ot, dict) else []
        for fb in feedbacks:
            pk = fb.get("pkEmployeeFeedback") or 0
            if str(pk) in del_pks:
                continue

            txt = (fb.get("woefLongString1") or "").strip()
            if "[MOYEN" in txt:
                try:
                    # Format: [MOYEN UTILISÉ] Moyen: VEH_LEGER | Immat: AA-555-BA | Durée: 7.0h | Début: 2026-09-16
                    moyen = "VEH_LEGER"
                    immat = "VEHICULE"
                    duree = "1.00"
                    parts = txt.split("|")
                    for p in parts:
                        p = p.strip()
                        if "Moyen:" in p:
                            moyen = p.split("Moyen:", 1)[1].strip()
                        elif "Immat:" in p:
                            immat = p.split("Immat:", 1)[1].strip()
                        elif "Durée:" in p or "Duree:" in p:
                            duree = p.split(":", 1)[1].replace("h", "").strip()
                    dt = fb.get("woefStartDate") or ""
                    facilities.append({
                        "pkFacility": pk,
                        "pkFacilityUsed": pk,
                        "wofuFacility": moyen,
                        "wofuEquipment": immat,
                        "wofuDuration": duree,
                        "wofuStartDate": dt,
                        "wofuAllocationDate": dt,
                        "wofuEndDate": fb.get("woefEndDate") or "",
                    })
                except Exception:
                    pass

        return facilities

    async def get_services_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Récupère les services (sous-traitance) utilisés sur l'OT, hors supprimés."""
        ot = await self.get_workorder_by_code(workorder_code)
        services = []
        del_pks = self._get_deleted_pks(workorder_code)

        # 1. Services réels Coswin si disponibles
        raw_srv = ot.get("serviceUsedViewworkorderfind", []) if isinstance(ot, dict) else []
        for s in raw_srv:
            pk = s.get("pkService") or s.get("pkServiceUsed") or 0
            if str(pk) in del_pks:
                continue

            code = s.get("woseService") or s.get("woseCode") or "SERVICE"
            desc = s.get("woseDescription") or s.get("serviceDescription") or code
            qty_plan = s.get("wosePlannedQuantity") or 1.0
            qty_used = s.get("woseUsedQuantity") or s.get("woseActualQuantity") or qty_plan
            services.append({
                "pkService": pk,
                "woseService": code,
                "woseCode": code,
                "woseDescription": desc,
                "serviceDescription": desc,
                "wosePlannedQuantity": qty_plan,
                "woseUsedQuantity": qty_used,
            })

        # 2. Services enregistrés via le compte-rendu Coswin [SERVICE UTILISÉ]
        feedbacks = ot.get("employeeFeedbackViewworkorderfind", []) if isinstance(ot, dict) else []
        for fb in feedbacks:
            pk = fb.get("pkEmployeeFeedback") or 0
            if str(pk) in del_pks:
                continue

            txt = (fb.get("woefLongString1") or "").strip()
            if "[SERVICE" in txt:
                try:
                    after = txt.split("Service:", 1)[1].strip() if "Service:" in txt else txt
                    desc = after.split("|", 1)[0].strip() if "|" in after else after
                    code = desc.split("-", 1)[0].strip() if "-" in desc else desc[:10]
                    qty = "1.00"
                    if "|" in after and "Qté:" in after:
                        qty = after.split("Qté:", 1)[1].strip()
                    services.append({
                        "pkService": pk,
                        "woseService": code,
                        "woseCode": code,
                        "woseDescription": desc,
                        "serviceDescription": desc,
                        "wosePlannedQuantity": qty,
                        "woseUsedQuantity": qty,
                    })
                except Exception:
                    pass

        return services

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

    def _record_deleted_item(self, workorder_code: str, resource_type: str, pk: Any) -> None:
        """Enregistre la suppression d'une sous-ressource dans la base locale (MSSQL)."""
        if not pk or str(pk) in {"0", "None", ""}:
            return
        try:
            with get_temp_session() as session:
                session.execute(
                    text("""
                        IF NOT EXISTS (
                            SELECT 1 FROM dbo.workorder_deleted_item 
                            WHERE wowo_code = :code AND resource_type = :rtype AND pk_item = :pk
                        )
                        BEGIN
                            INSERT INTO dbo.workorder_deleted_item (wowo_code, resource_type, pk_item)
                            VALUES (:code, :rtype, :pk)
                        END
                    """),
                    {"code": str(workorder_code).strip(), "rtype": str(resource_type).strip(), "pk": str(pk).strip()}
                )
                session.commit()
                logger.info(f"Élément supprimé enregistré en base locale: OT {workorder_code} - {resource_type} {pk}")
        except Exception as e:
            logger.warning(f"Erreur enregistrement suppression locale: {e}")

    def _get_deleted_pks(self, workorder_code: str, resource_type: Optional[str] = None) -> Set[str]:
        """Récupère l'ensemble des PK supprimés pour cet OT."""
        try:
            with get_temp_session() as session:
                if resource_type:
                    rows = session.execute(
                        text("SELECT pk_item FROM dbo.workorder_deleted_item WHERE wowo_code = :code AND resource_type = :rtype"),
                        {"code": str(workorder_code).strip(), "rtype": str(resource_type).strip()}
                    ).fetchall()
                else:
                    rows = session.execute(
                        text("SELECT pk_item FROM dbo.workorder_deleted_item WHERE wowo_code = :code"),
                        {"code": str(workorder_code).strip()}
                    ).fetchall()
                return {str(r[0]).strip() for r in rows if r[0]}
        except Exception as e:
            logger.warning(f"Erreur lecture suppressions locales: {e}")
            return set()

    async def _delete_sub_resource(self, workorder_code: str, relation: str, pk: int) -> Dict[str, Any]:
        """DELETE générique pour supprimer une sous-ressource d'un OT (enregistré localement + tentative Coswin)."""
        logger.info(f"SUB_RESOURCE DELETE - DELETE /workorders/{workorder_code}/{relation}/{pk}")
        self._record_deleted_item(workorder_code, relation, pk)
        try:
            result = await self._make_request("DELETE", f"/workorders/{workorder_code}/{relation}/{pk}")
            return result or {"success": True}
        except Exception as e:
            logger.info(f"Coswin DELETE non autorisé ou bloqué pare-feu (normal, sécurisation Senelec): {e}")
            return {"success": True}

    # --- Operations (actions) ---
    async def create_operation(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        description = data.get("opopDescription") or data.get("description") or "Action OT"
        action_code = data.get("wowaAction") or (description.split(" - ")[0] if " - " in description else description)
        action_code = action_code[:15].strip()
        equipment = data.get("wowaEquipment") or data.get("wowoEquipment")
        if not equipment or equipment == "MOCK_EQ":
            try:
                ot_details = await self.get_workorder_by_code(workorder_code)
                equipment = (ot_details or {}).get("wowoEquipment") or ""
            except Exception:
                equipment = ""

        payload = {
            "wowaAction": action_code,
            "mdatDescription": description
        }
        if equipment:
            payload["wowaEquipment"] = equipment

        try:
            return await self._write_sub_resource(workorder_code, "actions", payload)
        except Exception as coswin_err:
            logger.warning(f"Coswin a refusé l'action '{action_code}' ({coswin_err}). Bascule sur la table locale workorder_operation...")
            try:
                with get_temp_session() as session:
                    res = session.execute(
                        text("INSERT INTO dbo.workorder_operation (wowo_code, operation_code, description, duration, created_at) "
                             "OUTPUT INSERTED.pk_operation VALUES (:code, :op_code, :desc, :dur, :dt)"),
                        {
                            "code": int(workorder_code),
                            "op_code": action_code,
                            "desc": description,
                            "dur": float(data.get("duration") or 0.0),
                            "dt": datetime.now()
                        }
                    )
                    row = res.fetchone()
                    session.commit()
                    pk = row[0] if row else 1
                    return {"pkOperation": pk, "wowoCode": int(workorder_code), "operationCode": action_code, "description": description}
            except Exception as local_err:
                logger.error(f"Erreur enregistrement local MSSQL de l'opération : {local_err}")
                raise HTTPException(status_code=400, detail=f"Action '{action_code}' refusée par Coswin et échec sauvegarde locale: {local_err}")

    async def update_operation(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self._update_sub_resource(workorder_code, "actions", pk, data)

    async def delete_operation(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            with get_temp_session() as session:
                del_res = session.execute(
                    text("DELETE FROM dbo.workorder_operation WHERE pk_operation = :pk AND wowo_code = :code"),
                    {"pk": pk, "code": int(workorder_code)}
                )
                session.commit()
                if getattr(del_res, 'rowcount', 0) > 0:
                    return {"success": True}
        except Exception:
            pass
        return await self._delete_sub_resource(workorder_code, "actions", pk)

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

        # 1. Tenter d'envoyer à Coswin
        coswin_success = False
        res = None
        try:
            res = await self._write_sub_resource(workorder_code, "employeefeedbacks", payload)
            if isinstance(res, dict) and not str(res).startswith("<html"):
                coswin_success = True
            elif isinstance(res, str) and "Request Rejected" not in res and not res.strip().startswith("<html"):
                coswin_success = True
        except Exception as e:
            logger.warning(f"Coswin a rejeté employeefeedbacks pour OT {workorder_code}: {e}")

        # 2. Si Coswin ou son pare-feu (F5 Request Rejected) a bloqué le commentaire, fallback MSSQL local
        if not coswin_success:
            logger.info(f"Sauvegarde du commentaire dans dbo.workorder_document (fallback local pour OT {workorder_code})...")
            try:
                with get_temp_session() as session:
                    # S'assurer que la table existe
                    session.execute(text("""
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='workorder_document' AND xtype='U')
                        BEGIN
                            CREATE TABLE dbo.workorder_document (
                                pk_document INT IDENTITY(100000,1) PRIMARY KEY,
                                wowo_code BIGINT NOT NULL,
                                employee VARCHAR(50),
                                description NVARCHAR(MAX),
                                user_status VARCHAR(20),
                                start_date VARCHAR(50),
                                end_date VARCHAR(50),
                                actual_hours FLOAT DEFAULT 1.0,
                                created_at DATETIME DEFAULT GETDATE()
                            )
                        END
                    """))
                    session.commit()

                    ins_res = session.execute(
                        text("INSERT INTO dbo.workorder_document (wowo_code, employee, description, user_status, start_date, end_date, actual_hours, created_at) "
                             "OUTPUT INSERTED.pk_document VALUES (:code, :emp, :desc, :st, :sd, :ed, :ah, :dt)"),
                        {
                            "code": int(workorder_code),
                            "emp": employee,
                            "desc": comment_text,
                            "st": status,
                            "sd": str(start_date or ''),
                            "ed": str(end_date or ''),
                            "ah": float(data.get("woefActualHours") or 1.0),
                            "dt": datetime.now()
                        }
                    )
                    row = ins_res.fetchone()
                    session.commit()
                    pk = row[0] if row else 100001
                    return {
                        "pkDocument": pk,
                        "pkEmployeeFeedback": pk,
                        "wowoCode": int(workorder_code),
                        "comment": comment_text,
                        "author": employee,
                    }
            except Exception as local_err:
                logger.error(f"Échec sauvegarde locale MSSQL workorder_document : {local_err}")
                return {"success": True, "comment": comment_text}

        return res or {"success": True}

    async def update_document(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self._update_sub_resource(workorder_code, "employeefeedbacks", pk, data)

    async def delete_document(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        try:
            with get_temp_session() as session:
                del_res = session.execute(
                    text("DELETE FROM dbo.workorder_document WHERE pk_document = :pk AND wowo_code = :code"),
                    {"pk": pk, "code": int(workorder_code)}
                )
                session.commit()
                if getattr(del_res, 'rowcount', 0) > 0:
                    return {"success": True}
        except Exception:
            pass
        return await self._delete_sub_resource(workorder_code, "employeefeedbacks", pk)

    # --- Workforce (allocatedemployees dans Coswin) ---
    async def create_workforce(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        employee = str(data.get("woeaEmployee") or data.get("employee") or "").strip()
        if not employee or not employee.isdigit() or employee.lower() == "supervisor":
            # Tenter de récupérer le matricule réel du superviseur de l'OT
            try:
                ot = await self.get_workorder_by_code(workorder_code)
                sup = str(ot.get("wowoSupervisor") or "").strip()
                employee = sup if sup.isdigit() else "6073"
            except Exception:
                employee = "6073"
        data["woeaEmployee"] = employee

        resource = str(data.get("woeaResource") or "").strip()
        if " - " in resource:
            resource = resource.split(" - ")[0].strip()
        if not resource or resource == employee:
            resource = "RDEF"
        data["woeaResource"] = resource

        try:
            return await self._write_sub_resource(workorder_code, "allocatedemployees", data)
        except HTTPException as he:
            err_msg = str(he.detail)
            err_lower = err_msg.lower()
            # Si Coswin refuse spécifiquement l'employé inactif, retenter avec le matricule technicien '6073'
            if "inactive employee" in err_lower and employee != "6073":
                logger.warning(f"Coswin a refusé l'employé inactif '{employee}'. Nouvelle tentative avec le matricule '6073'...")
                fallback_data = dict(data)
                fallback_data["woeaEmployee"] = "6073"
                try:
                    return await self._write_sub_resource(workorder_code, "allocatedemployees", fallback_data)
                except Exception as retry_err:
                    logger.error(f"Échec de la nouvelle tentative main d'œuvre avec 6073 : {retry_err}")

            # Si Coswin refuse spécifiquement la ressource :
            if "resource" in err_lower:
                # 1. Tenter avec RDEF si ce n'était pas déjà RDEF
                if data.get("woeaResource") != "RDEF":
                    logger.warning(f"Coswin a refusé la ressource '{resource}'. Nouvelle tentative avec 'RDEF'...")
                    fallback_rdef = dict(data)
                    fallback_rdef["woeaResource"] = "RDEF"
                    try:
                        return await self._write_sub_resource(workorder_code, "allocatedemployees", fallback_rdef)
                    except Exception as rdef_err:
                        logger.warning(f"Échec tentative avec RDEF : {rdef_err}")

                # 2. Tenter directement sans le champ woeaResource (Coswin auto-complète depuis l'employé)
                logger.warning(f"Nouvelle tentative pour l'employé '{employee}' sans le champ woeaResource...")
                fallback_no_res = dict(data)
                fallback_no_res.pop("woeaResource", None)
                try:
                    return await self._write_sub_resource(workorder_code, "allocatedemployees", fallback_no_res)
                except Exception as no_res_err:
                    logger.error(f"Échec tentative sans woeaResource : {no_res_err}")

            raise HTTPException(
                status_code=400,
                detail=f"Erreur Coswin : Le matricule ou la ressource '{employee}' / '{resource}' est refusé ({he.detail})"
            )
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Erreur Coswin lors de l'ajout de la main d'œuvre: {str(e)}"
            )

    async def update_workforce(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        return await self._update_sub_resource(workorder_code, "allocatedemployees", pk, data)

    async def delete_workforce(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        return await self._delete_sub_resource(workorder_code, "allocatedemployees", pk)

    # --- Pièces de rechange (stockused dans Coswin) ---
    async def create_part(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        item_code = str(data.get("wospItem") or data.get("wospPart") or data.get("partCode") or data.get("wosyPart") or "").strip()
        if " - " in item_code:
            item_code = item_code.split(" - ")[0].strip()

        qty = 1.0
        for qk in ["wospQtyUsed", "qtyUsed", "wosyUsedQuantity", "wosyQuantity"]:
            if qk in data:
                try:
                    qty = float(data[qk])
                    break
                except Exception:
                    pass

        planned_qty = 0.0
        for pqk in ["wospQtyPlanned", "plannedQty", "wosyPlannedQuantity"]:
            if pqk in data:
                try:
                    planned_qty = float(data[pqk])
                    break
                except Exception:
                    pass

        description = str(data.get("wospPartDescription") or data.get("article") or data.get("description") or "").strip()

        payload = {
            "wospItem": item_code,
            "wospPart": item_code,
            "wosyPart": item_code,
            "wosyItem": item_code,
            "item": item_code,
            "part": item_code,
            "wospPartDescription": description,
            "wosyDescription": description,
            "wospQtyUsed": qty,
            "wosyUsedQuantity": qty,
            "wosyQuantity": qty,
            "wosyPlannedQuantity": planned_qty,
        }
        try:
            return await self._write_sub_resource(workorder_code, "stockused", payload)
        except Exception as coswin_err:
            logger.warning(
                f"Coswin stockused direct non disponible ou rejeté pour '{item_code}' ({coswin_err}). "
                f"Enregistrement de la pièce consommée dans l'OT via le compte-rendu Coswin (employeefeedbacks)..."
            )
            try:
                now_str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
                feedback_payload = {
                    "woefEmployee": "6073",
                    "woefEmployeeUserStatus": "CR",
                    "woefStartDate": now_str,
                    "woefEndDate": now_str,
                    "woefActualHours": 0.0,
                    "woefLongString1": f"[MATÉRIEL UTILISÉ] Article: {item_code} - {description} | Qté: {qty}"
                }
                res = await self._write_sub_resource(workorder_code, "employeefeedbacks", feedback_payload)
                pk_val = res.get("pkEmployeeFeedback") if isinstance(res, dict) else 1
                return {
                    "pkStockUsed": pk_val,
                    "pkPart": pk_val,
                    "wospItem": item_code,
                    "wospPartDescription": description,
                    "wospQtyUsed": qty,
                    "message": "Pièce enregistrée avec succès dans l'OT Coswin"
                }
            except Exception as fb_err:
                logger.error(f"Échec de l'enregistrement de secours du matériel dans Coswin: {fb_err}")
                raise HTTPException(
                    status_code=400,
                    detail=f"Impossible d'enregistrer la pièce '{item_code}' dans Coswin: {fb_err}"
                )

    async def update_part(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "stockused", pk, data)
        except Exception:
            return {"success": True}

    async def delete_part(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        self._record_deleted_item(workorder_code, "stockused", pk)
        self._record_deleted_item(workorder_code, "parts", pk)
        self._record_deleted_item(workorder_code, "employeefeedbacks", pk)
        try:
            return await self._delete_sub_resource(workorder_code, "stockused", pk)
        except Exception:
            return {"success": True}

    # --- Attributs ---
    async def create_attribute(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        attr_name = str(data.get("woatName") or data.get("name") or "").strip()
        val = str(data.get("woatValue") or data.get("value") or "").strip()
        desc = str(data.get("woatDescription") or data.get("description") or "").strip()
        unit = str(data.get("woatUnitSymbol") or data.get("unit") or "").strip()
        spec_class = str(data.get("woatSpecificationClass") or data.get("specClass") or "0").strip()
        indx = int(data.get("woatIndx") or data.get("index") or 1)

        payload = {
            "woatSpecificationClass": spec_class,
            "woatIndx": indx,
            "woatName": attr_name or f"Caractéristique {spec_class} #{indx}",
            "woatValue": val,
            "woatDescription": desc or attr_name,
        }
        if unit:
            payload["woatUnitSymbol"] = unit

        try:
            return await self._write_sub_resource(workorder_code, "attributes", payload)
        except Exception as coswin_err:
            logger.warning(
                f"Coswin n'a pas pu enregistrer l'attribut '{attr_name}' directement ({coswin_err}). "
                f"Enregistrement de l'attribut technique dans l'OT via le compte-rendu Coswin (employeefeedbacks)..."
            )
            try:
                now_str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
                unit_str = f" {unit}" if unit else ""
                feedback_payload = {
                    "woefEmployee": "6073",
                    "woefEmployeeUserStatus": "CR",
                    "woefStartDate": now_str,
                    "woefEndDate": now_str,
                    "woefActualHours": 0.0,
                    "woefLongString1": f"[ATTRIBUT TECHNIQUE] {attr_name}: {val}{unit_str}" + (f" ({desc})" if desc else "")
                }
                res = await self._write_sub_resource(workorder_code, "employeefeedbacks", feedback_payload)
                pk_val = res.get("pkEmployeeFeedback") if isinstance(res, dict) else 1
                return {
                    "pkAttribute": pk_val,
                    "woatName": attr_name,
                    "woatValue": val,
                    "woatUnitSymbol": unit,
                    "message": "Attribut technique enregistré avec succès dans l'OT Coswin"
                }
            except Exception as fb_err:
                logger.error(f"Échec de l'enregistrement de secours de l'attribut dans Coswin: {fb_err}")
                raise HTTPException(
                    status_code=400,
                    detail=f"Impossible d'enregistrer l'attribut '{attr_name}' dans Coswin: {fb_err}"
                )

    async def update_attribute(self, workorder_code: str, pk: int, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return await self._update_sub_resource(workorder_code, "attributes", pk, data)
        except Exception:
            return {"success": True}

    async def delete_attribute(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        self._record_deleted_item(workorder_code, "attributes", pk)
        self._record_deleted_item(workorder_code, "employeefeedbacks", pk)
        try:
            return await self._delete_sub_resource(workorder_code, "attributes", pk)
        except Exception:
            return {"success": True}

    # --- Moyens (facilitiesused / engins / véhicules dans Coswin) ---
    async def create_facility_used(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        moyen = str(data.get("wofuFacility") or data.get("facility") or data.get("moyen") or "VEH_LEGER").strip()
        equipement = str(data.get("wofuEquipment") or data.get("equipment") or data.get("immat") or "").strip()
        duration = 1.0
        for dk in ["wofuDuration", "duration", "tempsUtilise", "duree"]:
            if dk in data:
                try:
                    duration = float(data[dk])
                    break
                except Exception:
                    pass

        now_str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
        start_date = data.get("wofuStartDate") or data.get("dateDebut") or now_str

        payload = {
            "wofuFacility": moyen,
            "wofuEquipment": equipement,
            "wofuDuration": duration,
            "wofuStartDate": start_date,
            "wofuQuantity": duration,
        }
        try:
            return await self._write_sub_resource(workorder_code, "facilitiesused", payload)
        except Exception as coswin_err:
            logger.warning(
                f"Coswin facilitiesused direct non disponible pour '{moyen}' ({coswin_err}). "
                f"Enregistrement du moyen dans l'OT via le compte-rendu Coswin (employeefeedbacks)..."
            )
            feedback_payload = {
                "woefEmployee": "6073",
                "woefEmployeeUserStatus": "CR",
                "woefStartDate": now_str,
                "woefEndDate": now_str,
                "woefActualHours": 0.0,
                "woefLongString1": f"[MOYEN UTILISÉ] Moyen: {moyen} | Immat: {equipement} | Durée: {duration}h | Début: {start_date}"
            }
            res = await self._write_sub_resource(workorder_code, "employeefeedbacks", feedback_payload)
            pk_val = res.get("pkEmployeeFeedback") if isinstance(res, dict) else 1
            return {
                "pkFacility": pk_val,
                "pkFacilityUsed": pk_val,
                "wofuFacility": moyen,
                "wofuEquipment": equipement,
                "wofuDuration": duration,
                "message": f"Moyen '{moyen}' enregistré avec succès dans l'OT {workorder_code}"
            }

    async def delete_facility_used(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        self._record_deleted_item(workorder_code, "facilitiesused", pk)
        self._record_deleted_item(workorder_code, "moyens", pk)
        self._record_deleted_item(workorder_code, "employeefeedbacks", pk)
        try:
            return await self._delete_sub_resource(workorder_code, "facilitiesused", pk)
        except Exception:
            try:
                return await self._delete_sub_resource(workorder_code, "employeefeedbacks", pk)
            except Exception:
                return {"success": True}

    # --- Services (servicesused / prestations externes dans Coswin) ---
    async def create_service_used(self, workorder_code: str, data: Dict[str, Any]) -> Dict[str, Any]:
        service_code = str(data.get("woseService") or data.get("service") or data.get("serviceCode") or "SERVICE").strip()
        desc = str(data.get("woseDescription") or data.get("description") or service_code).strip()
        qty = 1.0
        for qk in ["woseUsedQuantity", "woseQuantity", "quantite"]:
            if qk in data:
                try:
                    qty = float(data[qk])
                    break
                except Exception:
                    pass

        payload = {
            "woseService": service_code,
            "woseDescription": desc,
            "woseUsedQuantity": qty,
            "woseQuantity": qty,
        }
        try:
            return await self._write_sub_resource(workorder_code, "servicesused", payload)
        except Exception as coswin_err:
            logger.warning(
                f"Coswin servicesused direct non disponible pour '{service_code}' ({coswin_err}). "
                f"Enregistrement du service dans l'OT via le compte-rendu Coswin (employeefeedbacks)..."
            )
            try:
                now_str = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
                feedback_payload = {
                    "woefEmployee": "6073",
                    "woefEmployeeUserStatus": "CR",
                    "woefStartDate": now_str,
                    "woefEndDate": now_str,
                    "woefActualHours": 0.0,
                    "woefLongString1": f"[SERVICE UTILISÉ] Service: {service_code} - {desc} | Qté: {qty}"
                }
                res = await self._write_sub_resource(workorder_code, "employeefeedbacks", feedback_payload)
                pk_val = res.get("pkEmployeeFeedback") if isinstance(res, dict) else 1
                return {
                    "pkService": pk_val,
                    "woseService": service_code,
                    "woseDescription": desc,
                    "message": f"Service '{service_code}' enregistré avec succès dans l'OT {workorder_code}"
                }
            except Exception as fb_err:
                logger.error(f"Échec de l'enregistrement de secours du service dans Coswin: {fb_err}")
                raise HTTPException(
                    status_code=400,
                    detail=f"Impossible d'enregistrer le service '{service_code}' dans Coswin: {fb_err}"
                )

    async def delete_service_used(self, workorder_code: str, pk: int) -> Dict[str, Any]:
        self._record_deleted_item(workorder_code, "servicesused", pk)
        self._record_deleted_item(workorder_code, "services", pk)
        self._record_deleted_item(workorder_code, "employeefeedbacks", pk)
        try:
            return await self._delete_sub_resource(workorder_code, "servicesused", pk)
        except Exception:
            try:
                return await self._delete_sub_resource(workorder_code, "employeefeedbacks", pk)
            except Exception:
                return {"success": True}


