"""
Service pour l'intégration avec l'API OT (Ordre de Travail) Coswin
API Base URL: http://10.101.1.102:8083/ws/rest
"""
import httpx
import base64
from typing import List, Optional, Dict, Any
from fastapi import HTTPException
from app.core.config import (
    OT_API_BASE_URL,
    OT_API_USERNAME,
    OT_API_PASSWORD,
    OT_DATASOURCE,
    OT_CWUSER
)


class OTService:
    """Service pour gérer les appels à l'API OT Coswin"""
    
    def __init__(self):
        self.base_url = OT_API_BASE_URL
        self.username = OT_API_USERNAME
        self.password = OT_API_PASSWORD
        self.datasource = OT_DATASOURCE
        self.cwuser = OT_CWUSER
        
        # Utiliser httpx.BasicAuth pour l'authentification
        self.auth = httpx.BasicAuth(self.username, self.password)
        self.headers = {
            "Content-Type": "application/json"
        }
    
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
            **params
        }
        
        # Construire la query string
        query_string = "&".join([f"{k}={v}" for k, v in all_params.items()])
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
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.request(
                    method=method,
                    url=url,
                    headers=self.headers,
                    auth=self.auth,
                    json=json_data
                )
                
                # Vérifier le statut de la réponse
                if response.status_code == 401:
                    raise HTTPException(
                        status_code=401,
                        detail="Authentification échouée avec l'API OT"
                    )
                elif response.status_code == 404:
                    raise HTTPException(
                        status_code=404,
                        detail="Ressource non trouvée dans l'API OT"
                    )
                elif response.status_code >= 400:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Erreur API OT: {response.text}"
                    )
                
                # Retourner la réponse JSON
                return response.json()
                
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="Timeout lors de l'appel à l'API OT"
            )
        except httpx.RequestError as e:
            raise HTTPException(
                status_code=503,
                detail=f"Erreur de connexion à l'API OT: {str(e)}"
            )
    
    # ========== WORKORDERS ==========
    
    async def get_all_workorders(
        self,
        limit: Optional[int] = None,
        offset: Optional[int] = None,
        status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Récupère tous les ordres de travail
        
        Args:
            limit: Nombre maximum de résultats
            offset: Offset pour la pagination
            status: Filtrer par statut (ex: 'OPEN', 'CLOSED')
            
        Returns:
            Liste des ordres de travail
        """
        params = {}
        if limit is not None:
            params["limit"] = limit
        if offset is not None:
            params["offset"] = offset
        if status:
            params["status"] = status
            
        return await self._make_request("GET", "/workorders", params=params)
    
    async def get_workorder_by_code(self, code: str) -> Dict[str, Any]:
        """
        Récupère un ordre de travail par son code
        
        Args:
            code: Code de l'ordre de travail (ex: '2025248525')
            
        Returns:
            Détails de l'ordre de travail
        """
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
    
    # ========== OPERATIONS ==========
    
    async def get_operations_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les opérations d'un ordre de travail
        
        Args:
            workorder_code: Code de l'ordre de travail
            
        Returns:
            Liste des opérations
        """
        return await self._make_request("GET", f"/workorders/{workorder_code}/operations")
    
    # ========== PARTS (Pièces de rechange) ==========
    
    async def get_parts_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les pièces de rechange d'un ordre de travail
        
        Args:
            workorder_code: Code de l'ordre de travail
            
        Returns:
            Liste des pièces
        """
        return await self._make_request("GET", f"/workorders/{workorder_code}/parts")
    
    # ========== DOCUMENTS ==========
    
    async def get_documents_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère les documents d'un ordre de travail
        
        Args:
            workorder_code: Code de l'ordre de travail
            
        Returns:
            Liste des documents
        """
        return await self._make_request("GET", f"/workorders/{workorder_code}/documents")
    
    # ========== WORKFORCE ==========
    
    async def get_workforce_by_workorder(self, workorder_code: str) -> List[Dict[str, Any]]:
        """
        Récupère la main d'œuvre affectée à un ordre de travail
        
        Args:
            workorder_code: Code de l'ordre de travail
            
        Returns:
            Liste du personnel affecté
        """
        return await self._make_request("GET", f"/workorders/{workorder_code}/workforce")


# Instance globale du service
ot_service = OTService()
