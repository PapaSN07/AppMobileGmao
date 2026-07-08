"""
Service pour l'intégration avec l'API OT (Ordre de Travail) Coswin
API Base URL: http://10.101.1.102:8083/ws/rest
"""


import asyncio
import json
import logging
import time
from datetime import datetime, timedelta, timezone


import requests
from requests.auth import HTTPDigestAuth
from requests.exceptions import RequestException, Timeout

from typing import List, Optional, Dict, Any
from fastapi import HTTPException
from urllib.parse import urlencode
from pathlib import Path
from app.core.config import (
    OT_API_BASE_URL,
    OT_API_USERNAME,
    OT_API_PASSWORD,
    OT_DATASOURCE,
    OT_CWUSER,
    OT_USE_LOCAL_MOCK,
    OT_LOCAL_JSON_PATH,
)


logger = logging.getLogger(__name__)


class OTService:
    """Service pour gérer les appels à l'API OT Coswin"""
    
    def __init__(self):
        self.base_url = OT_API_BASE_URL
        self.username = OT_API_USERNAME
        self.password = OT_API_PASSWORD
        self.datasource = OT_DATASOURCE
        self.cwuser = OT_CWUSER
        self.use_local_mock = OT_USE_LOCAL_MOCK
        self.local_workorders: List[Dict[str, Any]] = []
        
        # Coswin indique Digest auth via WWW-Authenticate: Digest ...
        self._digest_auth = None
        if self.username and self.password:
            self._digest_auth = HTTPDigestAuth(self.username, self.password)
        
        self.headers = {
            "Accept": "application/json"
        }
        
        self._cached_max_code = None
        self._cached_max_code_time = 0.0

        if self.use_local_mock:
            self._load_local_workorders()

    def _resolve_local_json_path(self) -> Path:
        """Résout le chemin du fichier JSON OT local."""
        if OT_LOCAL_JSON_PATH:
            path = Path(OT_LOCAL_JSON_PATH)
            return path if path.is_absolute() else (Path(__file__).resolve().parents[3] / path)

        # Valeur par défaut: fichier déjà présent à la racine du workspace.
        return Path(__file__).resolve().parents[3] / "API_OT_SUCCESS_EXAMPLE.json"

    def _load_local_workorders(self) -> None:
        """Charge les OT depuis un fichier JSON local pour les tests hors ligne."""
        json_path = self._resolve_local_json_path()
        if not json_path.exists():
            raise HTTPException(
                status_code=500,
                detail=f"OT local activé mais fichier introuvable: {json_path}",
            )

        with json_path.open("r", encoding="utf-8") as f:
            payload = json.load(f)

        # Supporte soit un objet direct, soit la clé workOrderExample du fichier de référence.
        if isinstance(payload, list):
            self.local_workorders = [item for item in payload if isinstance(item, dict)]
        elif isinstance(payload, dict) and isinstance(payload.get("workOrderExample"), dict):
            self.local_workorders = [payload["workOrderExample"]]
        elif isinstance(payload, dict):
            self.local_workorders = [payload]
        else:
            self.local_workorders = []

    def _get_local_workorder_by_code(self, code: str) -> Optional[Dict[str, Any]]:
        """Retourne un OT local par son wowoCode."""
        for workorder in self.local_workorders:
            if str(workorder.get("wowoCode")) == str(code):
                return workorder
        return None
    
    def _build_url(self, endpoint: str, **params) -> str:
        """
        Construit l'URL complète avec les paramètres requis
        
        Args:
            endpoint: Le endpoint de l'API (ex: /workorders)
            **params: Paramètres additionnels
            
        Returns:
            URL complète avec tous les paramètres
        """
        # Ajouter les paramètres obligatoires
        all_params = {
            "dataSource": self.datasource,
            "cwUser": self.cwuser,
            # "cwPassword": self.password,
            **params
        }
        
        # Construire la query string
        #query_string = "&".join([f"{k}={v}" for k, v in all_params.items()])
        #return f"{self.base_url}{endpoint}?{query_string}"
        query_string = urlencode(all_params, doseq=True, safe=':/')

        return f"{self.base_url}{endpoint}?{query_string}"
    
    async def _make_request(
        self,
        method: str,
        endpoint: str,
        params: Optional[Dict] = None,
        json_data: Optional[Dict] = None
    ) -> Any:
        """
        Effectue une requête HTTP vers l'API OT
        
        Args:
            method: Méthode HTTP (GET, POST, PUT, DELETE)
            endpoint: Endpoint de l'API
            params: Paramètres de requête additionnels
            json_data: Corps de la requête (pour POST/PUT)
            
        Returns:
            Réponse JSON de l'API
            
        Raises:
            HTTPException: En cas d'erreur de requête
        """
        url = self._build_url(endpoint, **(params or {}))
        logger.info(f"➡️ Appel API OT Coswin: {method} {url}")
        
        def sync_call():
            request_kwargs = {
                "headers": self.headers,
                "json": json_data,
                "timeout": 30,
                "proxies": {
                    "http": None,
                    "https": None,
                }
            }
            if self._digest_auth:
                request_kwargs["auth"] = self._digest_auth
            return requests.request(method, url, **request_kwargs)

        try:
            response = await asyncio.to_thread(sync_call)
            logger.info(
                f"⬅️ Réponse API OT Coswin: {response.status_code} "
                f"({len(response.content)} octets) pour {url}"
            )

            if response.status_code == 401:
                raise HTTPException(
                    status_code=401,
                    detail="Authentification échouée avec l'API OT"
                )
            if response.status_code == 404:
                logger.warning(f"404 Coswin sur {url} — corps: {response.text[:500]}")
                raise HTTPException(
                    status_code=404,
                    detail=f"Ressource non trouvée dans l'API OT (url={url}, body={response.text[:300]})"
                )
            if response.status_code >= 400:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Erreur API OT: {response.text}"
                )

            try:
                return response.json()
            except Exception:
                return response.text

        except Timeout:
            raise HTTPException(
                status_code=504,
                detail="Timeout lors de l'appel à l'API OT"
            )
        except RequestException as e:
            raise HTTPException(
                status_code=503,
                detail=f"Erreur de connexion à l'API OT: {str(e)}"
            )
    
    # ========== WORKORDERS ==========

    # Statut système Coswin correspondant à "Clôturé" (wowoUserStatus).
    CLOSED_STATUS_CODE = "CL"

    # Sécurité anti-boucle infinie : nombre maximum de pages Coswin à parcourir
    # avant d'abandonner, même en demandant "toutes les pages".
    MAX_PAGES_HARD_LIMIT = 10

    def _passes_filters(
        self,
        row: Dict[str, Any],
        supervisor_code: Optional[str],
        request_entity: Optional[str],
        exclude_closed: bool,
    ) -> bool:
        """Applique les filtres métier (technicien / service / statut) à un OT."""
        if supervisor_code and str(row.get("wowoSupervisor", "")) != str(supervisor_code):
            return False
        if request_entity and str(row.get("wowoRequestEntity", "")).upper() != str(request_entity).upper():
            return False
        if exclude_closed and str(row.get("wowoUserStatus", "")).upper() == self.CLOSED_STATUS_CODE:
            return False
        return True

    def _estimate_starting_wowo_code(self) -> int:
        """
        Calcule de manière mathématique le code de départ estimé pour récupérer 
        les OT récents (des ~4 derniers jours), évitant les requêtes lentes
        ou la recherche dichotomique sur le réseau intranet de la Senelec.
        """
        # Base de référence au 1er Janvier 2026 (code 2026253021)
        base_date = datetime(2026, 1, 1).date()
        base_seq = 253020
        daily_rate = 165  # Moyenne d'OT créés par jour constatée à la Senelec

        now_dt = datetime.now()
        current_year = now_dt.year
        current_date = now_dt.date()

        days_diff = (current_date - base_date).days
        # Si on est avant 2026 (cas de test ou horloge déréglée), on protège
        if days_diff < 0:
            days_diff = 0

        estimated_seq = base_seq + int(days_diff * daily_rate)
        estimated_max_code = (current_year * 1000000) + (estimated_seq % 1000000)

        # On recule de 150 OT (~1 jour de création d'OT) pour avoir les OT très récents
        # et éviter les temps de chargement trop longs sur le réseau.
        starting_code = estimated_max_code - 150
        
        logger.info(f"📊 Estimation code de départ OT (jours écoulés={days_diff}) : {starting_code}")
        return starting_code

    async def get_all_workorders(
        self,
        scope: str = "mine",
        supervisor_code: Optional[str] = None,
        request_entity: Optional[str] = None,
        exclude_closed: bool = True,
        pagination_context: Optional[str] = None,
        max_pages: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Récupère la liste des ordres de travail, filtrée par technicien et/ou
        service, en excluant (par défaut) les OT déjà clôturés.

        STRATÉGIE RETENUE :
        - Pour scope='mine' (technicien) : Le filtrage est fait directement par Coswin
          sur le serveur via filterColumn=wowoSupervisor, ce qui est instantané.
        - Pour scope='service' ou 'all_open' : Le filtrage est fait en Python à partir
          des OT récents. Les OT récents sont récupérés en identifiant d'abord le code
          d'OT estimé (par calcul mathématique très rapide) puis en demandant uniquement
          les OT ayant un code supérieur. Cela limite le nombre de pages à charger et
          évite les scans complets de date ou les recherches dichotomiques lourdes sur le réseau.
        """
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

        if self.use_local_mock:
            rows = list(self.local_workorders)
            matched = [
                row for row in rows
                if self._passes_filters(row, supervisor_code, request_entity, exclude_closed)
            ]
            return {
                "workorders": matched,
                "paginationContext": None,
                "hasMore": False,
            }

        # Détermination des paramètres d'appel de base
        params = {"usePagination": "true"}
        
        if scope == "mine":
            # Filtrage 100% côté serveur par superviseur (très rapide)
            params["filterColumn"] = "wowoSupervisor"
            params["filterOperator"] = "equals"
            params["filterOperand1"] = str(supervisor_code)
            page_limit = 2  # Un agent a rarement plus de 100 OT ouverts
        else:
            # Pour les recherches larges (service, etc.), on utilise notre estimation
            # mathématique linéaire très rapide pour cibler uniquement les OT récents.
            starting_code = self._estimate_starting_wowo_code()
                
            params["filterOperator"] = "greater"
            params["filterOperand1"] = str(starting_code)
            page_limit = max_pages if max_pages is not None else 3 # Max 3 pages (150 OT) pour rapidité
            page_limit = min(page_limit, 5)

        if pagination_context:
            params["paginationContext"] = pagination_context

        matched: List[Dict[str, Any]] = []
        more_data = False
        pages_fetched = 0

        while True:
            page_response = await self._make_request("GET", "/workorders", params=params)
            pages_fetched += 1

            page_list = (page_response or {}).get("list", {}).get("workorderfind", [])
            for row in page_list:
                if self._passes_filters(row, supervisor_code, request_entity, exclude_closed):
                    matched.append(row)

            more_data = bool((page_response or {}).get("moreDataAvailable"))
            pagination_context = (page_response or {}).get("paginationContext")

            if not more_data or not pagination_context:
                break
            if pages_fetched >= page_limit:
                break
            # Transmettre le context pour la page suivante
            params["paginationContext"] = pagination_context

        logger.info(
            f"get_all_workorders: {len(matched)} OT retenus après {pages_fetched} page(s) "
            f"Coswin (scope={scope}, supervisor={supervisor_code}, request_entity={request_entity}, "
            f"exclude_closed={exclude_closed})"
        )
        return {
            "workorders": matched,
            "paginationContext": pagination_context if more_data else None,
            "hasMore": more_data,
        }
    
    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """
        Récupère un ordre de travail par son code
        
        Args:
            code: Code de l'ordre de travail (ex: '2025248525')
            
        Returns:
            Détails de l'ordre de travail
        """
        if self.use_local_mock:
            local_workorder = self._get_local_workorder_by_code(code)
            if local_workorder is None:
                raise HTTPException(
                    status_code=404,
                    detail=f"Ordre de travail {code} non trouvé dans le mock local",
                )
            return local_workorder

        return await self._make_request("GET", f"/workorders/{code}")
    
    async def create_workorder(self, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Crée un nouvel ordre de travail
        
        Args:
            workorder_data: Données de l'ordre de travail
            
        Returns:
            Ordre de travail créé
        """
        return await self._make_request("POST", "/workorders", json_data=workorder_data)
    
    async def update_workorder(self, code: str, workorder_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Met à jour un ordre de travail existant
        
        Args:
            code: Code de l'ordre de travail
            workorder_data: Nouvelles données
            
        Returns:
            Ordre de travail mis à jour
        """
        return await self._make_request("PUT", f"/workorders/{code}", json_data=workorder_data)
    
    async def delete_workorder(self, code: str) -> Dict[str, Any]:
        """
        Supprime un ordre de travail
        
        Args:
            code: Code de l'ordre de travail
            
        Returns:
            Confirmation de suppression
        """
        return await self._make_request("DELETE", f"/workorders/{code}")
    
    # ========== EQUIPMENT ==========
    
    async def get_all_equipment(self) -> List[Dict[str, Any]]:
        """Récupère tous les équipements"""
        return await self._make_request("GET", "/equipment")
    
    async def get_equipment_by_code(self, code: str) -> Dict[str, Any]:
        """Récupère un équipement par son code"""
        return await self._make_request("GET", f"/equipment/{code}")
    
    # ========== LOCATIONS ==========
    
    async def get_all_locations(self) -> List[Dict[str, Any]]:
        """Récupère tous les emplacements"""
        return await self._make_request("GET", "/locations")
    
    async def get_location_by_code(self, code: str) -> Dict[str, Any]:
        """Récupère un emplacement par son code"""
        return await self._make_request("GET", f"/locations/{code}")
    
    # ========== OPERATIONS (Mode opératoire) ==========
    
    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les opérations d'un ordre de travail depuis Coswin.
        Endpoint Coswin: /workorders/{code}/actions
        Tableau: workActionViewwoActionsView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/actions")
        if isinstance(resp, dict):
            return resp.get("workActionViewwoActionsView", [])
        return []
    
    # ========== WORKFORCE (Mains d'œuvre allouées) ==========
    
    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les employés alloués à un ordre de travail.
        Onglet: Mains d'œuvre
        Endpoint Coswin: GET /workorders/{code}/allocatedemployees
        Tableau: employeeAllocatedViewwoEmpAllocView
        Champs utiles: woeaEmployee, reemDescription, woeaResource, woeaPlannedHours, woeaAllocationDate
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/allocatedemployees")
        if isinstance(resp, dict):
            return resp.get("employeeAllocatedViewwoEmpAllocView", [])
        return []

    # ========== COMMENTAIRES (Feedbacks employés) ==========

    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les feedbacks/commentaires saisis par les employés sur un OT.
        Onglet: Commentaires
        Endpoint Coswin: GET /workorders/{code}/employeefeedbacks
        Tableau: employeeFeedbackViewwoFeedbackView
        Champs utiles: reemDescription, woefStartDate, woefEndDate, woefActualHours, woefEmployeeUserStatus
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/employeefeedbacks")
        if isinstance(resp, dict):
            return resp.get("employeeFeedbackViewwoFeedbackView", [])
        return []


    # ========== ACTIONS ==========

    async def get_actions_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les actions d'un ordre de travail.
        Endpoint Coswin: /workorders/{code}/actions
        Tableau: workActionViewwoActionsView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/actions")
        if isinstance(resp, dict):
            return resp.get("workActionViewwoActionsView", [])
        return []

    # ========== ALLOCATED EMPLOYEES ==========

    async def get_allocated_employees_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les employés alloués à un ordre de travail.
        Endpoint Coswin: /workorders/{code}/allocatedemployees
        Tableau: employeeAllocatedViewwoEmpAllocView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/allocatedemployees")
        if isinstance(resp, dict):
            return resp.get("employeeAllocatedViewwoEmpAllocView", [])
        return []

    # ========== EMPLOYEE FEEDBACKS ==========

    async def get_employee_feedbacks_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les feedbacks (heures saisies) sur un ordre de travail.
        Endpoint Coswin: /workorders/{code}/employeefeedbacks
        Tableau: employeeFeedbackViewwoFeedbackView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/employeefeedbacks")
        if isinstance(resp, dict):
            return resp.get("employeeFeedbackViewwoFeedbackView", [])
        return []

    # ========== STOCK USED ==========

    async def get_stock_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère le stock utilisé sur un ordre de travail.
        Endpoint Coswin: /workorders/{code}/stockused
        Tableau: stockUsedViewwoStockView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/stockused")
        if isinstance(resp, dict):
            return resp.get("stockUsedViewwoStockView", [])
        return []

    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """Alias pour get_stock_used_by_workorder utilisé par le routeur /parts."""
        return await self.get_stock_used_by_workorder(workorder_code)


    # ========== ATTRIBUTES ==========

    async def get_attributes_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les attributs d'un ordre de travail.
        Endpoint Coswin: /workorders/{code}/attributes
        Tableau: workOrderCurrentSetAttributeViewwoAttributeView
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/attributes")
        if isinstance(resp, dict):
            return resp.get("workOrderCurrentSetAttributeViewwoAttributeView", [])
        return []

    # ========== FACILITIES USED (Moyens) ==========

    async def get_facilities_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les moyens (véhicules, outillages) utilisés pour un OT.
        Endpoint Coswin: GET /workorders/{code}/facilitiesused
        """
        resp = await self._make_request("GET", f"/workorders/{workorder_code}/facilitiesused")
        if isinstance(resp, dict):
            # Trouver dynamiquement la clé de liste (ex: facilityUsedViewwoFacilityView)
            keys = [k for k in resp.keys() if k != "wowoCode"]
            if keys:
                return resp.get(keys[0], [])
        return []

    # ========== SERVICES USED (Prestations / Services) ==========

    async def get_services_used_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les services (sous-traitance, prestations) utilisés pour un OT.
        Endpoint Coswin: GET /workorders/{code}/servicesused ou /workorders/{code}/services
        """
        try:
            resp = await self._make_request("GET", f"/workorders/{workorder_code}/servicesused")
            if isinstance(resp, dict):
                keys = [k for k in resp.keys() if k != "wowoCode"]
                if keys:
                    return resp.get(keys[0], [])
        except Exception as e:
            logger.warning(f"Echec de récupération de /servicesused, tentative avec /services: {e}")
            try:
                resp = await self._make_request("GET", f"/workorders/{workorder_code}/services")
                if isinstance(resp, dict):
                    keys = [k for k in resp.keys() if k != "wowoCode"]
                    if keys:
                        return resp.get(keys[0], [])
            except Exception as e2:
                logger.error(f"Echec également avec le fallback /services: {e2}")
        return []


# Instance globale du service
ot_service = OTService()