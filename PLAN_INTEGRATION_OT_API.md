# 🚀 PLAN D'ACTION : INTÉGRATION API OT

**API OT**: `http://10.101.1.102:8083/`  
**Date**: 28 Novembre 2025  
**Branche**: OT_Alima

---

## 📋 CHECKLIST D'INTÉGRATION

### ☐ Phase 1: Investigation API (1-2h)
- [ ] Tester connectivité API `http://10.101.1.102:8083/`
- [ ] Documenter structure JSON réponses
- [ ] Vérifier authentification requise
- [ ] Identifier paramètres WHERE clause
- [ ] Tester pagination

### ☐ Phase 2: Backend FastAPI (2-3h)
- [ ] Créer proxy OT dans backend (recommandé)
- [ ] Ajouter variable environnement `OT_API_BASE_URL`
- [ ] Créer `ot_service.py`
- [ ] Créer `ot_router.py` (mobile + web)
- [ ] Ajouter modèles Pydantic
- [ ] Tests endpoints

### ☐ Phase 3: Frontend Mobile (3-4h)
- [ ] Adapter `WorkOrder` model selon JSON API
- [ ] Modifier `OTService` (désactiver mock)
- [ ] Configurer URL API OT
- [ ] Implémenter méthodes CRUD
- [ ] Gestion cache/offline
- [ ] Tests UI

### ☐ Phase 4: Tests & Validation (1-2h)
- [ ] Tests unitaires services
- [ ] Tests navigation complète
- [ ] Tests offline/online
- [ ] Tests CRUD complet
- [ ] Validation UX

---

## 📝 COMMANDES DE TEST RAPIDE

### 1. Tester API OT

```powershell
# Test connectivité
curl http://10.101.1.102:8083/

# Test liste workorders
curl http://10.101.1.102:8083/workorders

# Test pagination
curl http://10.101.1.102:8083/workorders/nextPage

# Test statuts validation
curl http://10.101.1.102:8083/workorders/validationstatuses

# Test détail (remplacer CODE_TEST)
curl http://10.101.1.102:8083/workorders/CODE_TEST

# Test actions
curl http://10.101.1.102:8083/workorders/CODE_TEST/actions

# Test diagnostics
curl http://10.101.1.102:8083/workorders/CODE_TEST/diagnostics
```

### 2. Analyser JSON

Sauvegarder réponse pour analyse:
```powershell
curl http://10.101.1.102:8083/workorders | Out-File -FilePath workorders_response.json
```

---

## 🔧 MODIFICATIONS REQUISES

### Backend (Option Recommandée)

#### 1. **Configuration** (`backend/app/core/config.py`)

```python
# Ajouter
OT_API_BASE_URL = os.getenv("OT_API_BASE_URL", "http://10.101.1.102:8083")
OT_API_TIMEOUT = int(os.getenv("OT_API_TIMEOUT", "30"))
```

#### 2. **Service OT** (`backend/app/services/ot_service.py`)

```python
import httpx
from typing import List, Optional, Dict, Any
from app.core.config import OT_API_BASE_URL, OT_API_TIMEOUT

class OTService:
    def __init__(self):
        self.base_url = OT_API_BASE_URL
        self.timeout = OT_API_TIMEOUT
    
    async def get_workorders(
        self, 
        where_clause: Optional[str] = None,
        page: Optional[int] = None
    ) -> Dict[str, Any]:
        """GET /workorders ou /workorders/nextPage"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            endpoint = "/workorders/nextPage" if page else "/workorders"
            params = {}
            if where_clause:
                params["where"] = where_clause
            if page:
                params["page"] = page
            
            response = await client.get(
                f"{self.base_url}{endpoint}",
                params=params
            )
            response.raise_for_status()
            return response.json()
    
    async def get_workorder_detail(self, code: str) -> Dict[str, Any]:
        """GET /workorders/{code}"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(f"{self.base_url}/workorders/{code}")
            response.raise_for_status()
            return response.json()
    
    async def create_simple_workorder(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """POST /workorders/createSimple"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/workorders/createSimple",
                json=data
            )
            response.raise_for_status()
            return response.json()
    
    async def change_status(
        self, 
        code: str, 
        status_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """PUT /workorders/{code}/changeStatus"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.put(
                f"{self.base_url}/workorders/{code}/changeStatus",
                json=status_data
            )
            response.raise_for_status()
            return response.json()
    
    async def get_actions(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/actions"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/actions"
            )
            response.raise_for_status()
            return response.json()
    
    async def get_diagnostics(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/diagnostics"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/diagnostics"
            )
            response.raise_for_status()
            return response.json()
    
    async def get_allocated_employees(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/allocatedemployees"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/allocatedemployees"
            )
            response.raise_for_status()
            return response.json()
    
    async def get_status_history(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/statushistory"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/statushistory"
            )
            response.raise_for_status()
            return response.json()
    
    async def get_stock_used(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/stockused"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/stockused"
            )
            response.raise_for_status()
            return response.json()
```

#### 3. **Router OT** (`backend/app/routers/mobile/ot_router.py`)

```python
from fastapi import APIRouter, HTTPException, Depends
from typing import Optional, Dict, Any
from app.services.ot_service import OTService

router = APIRouter(prefix="/ot", tags=["OT Mobile"])

@router.get("/workorders")
async def get_workorders(
    where: Optional[str] = None,
    page: Optional[int] = None
):
    """Liste des ordres de travail"""
    try:
        ot_service = OTService()
        result = await ot_service.get_workorders(where, page)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/workorders/{code}")
async def get_workorder_detail(code: str):
    """Détail d'un ordre de travail"""
    try:
        ot_service = OTService()
        result = await ot_service.get_workorder_detail(code)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"OT {code} non trouvé")

@router.post("/workorders/create")
async def create_workorder(data: Dict[str, Any]):
    """Créer un ordre de travail"""
    try:
        ot_service = OTService()
        result = await ot_service.create_simple_workorder(data)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/workorders/{code}/status")
async def change_status(code: str, status_data: Dict[str, Any]):
    """Changer le statut d'un OT"""
    try:
        ot_service = OTService()
        result = await ot_service.change_status(code, status_data)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/workorders/{code}/actions")
async def get_actions(code: str):
    """Actions d'un OT"""
    try:
        ot_service = OTService()
        result = await ot_service.get_actions(code)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/workorders/{code}/diagnostics")
async def get_diagnostics(code: str):
    """Diagnostics d'un OT"""
    try:
        ot_service = OTService()
        result = await ot_service.get_diagnostics(code)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/workorders/{code}/history")
async def get_status_history(code: str):
    """Historique statut OT"""
    try:
        ot_service = OTService()
        result = await ot_service.get_status_history(code)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

#### 4. **Enregistrer Router** (`backend/app/main.py`)

```python
# Ajouter import
from app.routers.mobile.ot_router import router as ot_router_mobile

# Ajouter après les autres routers mobile
app.include_router(ot_router_mobile, prefix=f"{PREFIX}/mobile")
```

#### 5. **Variables Environnement** (`backend/.env`)

```env
# API OT
OT_API_BASE_URL=http://10.101.1.102:8083
OT_API_TIMEOUT=30
```

---

### Frontend Mobile

#### 1. **Configuration** (`frontend_mobile/lib/config/app_config.dart`)

Créer nouveau fichier:

```dart
class AppConfig {
  // API principale
  static const String mainApiUrl = 'https://domtec.senelec.sn:9099';
  
  // API OT (via backend FastAPI - recommandé)
  static const String otApiEndpoint = '/api/v1/mobile/ot';
  
  // OU directement (déconseillé - problèmes CORS potentiels)
  // static const String otApiUrl = 'http://10.101.1.102:8083';
  
  // Mode développement
  static const bool isDevelopment = true;
  static const bool useOTMockData = false; // ❌ Désactiver mock
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration otApiTimeout = Duration(seconds: 30);
}
```

#### 2. **Modifier OTService** (`frontend_mobile/lib/services/ot_service.dart`)

```dart
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/cache_service.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/config/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OTService {
  final ApiService _apiService;
  final CacheService _cacheService = CacheService();

  // ✅ Configuration nouvelle API
  static const bool useMockData = AppConfig.useOTMockData; // false
  static const String ordersEndpoint = AppConfig.otApiEndpoint;

  OTService(this._apiService);

  /// Vérifier connectivité Internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Récupérer tous les OT avec filtrage optionnel
  Future<List<WorkOrder>> getAllOrders({String? whereClause}) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [_getMockOrderDetails()];
    }

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      final cachedOrders = await _cacheService.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print('📱 ${cachedOrders.length} OT chargés depuis cache');
        return cachedOrders;
      }
      throw Exception('Aucune connexion Internet');
    }

    try {
      print('🌐 Chargement OT depuis API: $ordersEndpoint/workorders');
      
      final params = whereClause != null ? {'where': whereClause} : null;
      final response = await _apiService.get(
        '$ordersEndpoint/workorders',
        queryParameters: params,
      );

      List<WorkOrder> orders;
      
      // Adapter selon structure API
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          orders = data.map((json) => WorkOrder.fromJson(json)).toList();
        } else if (data is Map && data['items'] != null) {
          orders = (data['items'] as List)
              .map((json) => WorkOrder.fromJson(json))
              .toList();
        } else {
          orders = [WorkOrder.fromJson(data)];
        }
      } else {
        throw Exception('Format réponse invalide');
      }

      await _cacheService.cacheOrders(orders);
      print('✅ ${orders.length} OT sauvegardés en cache');

      return orders;
    } catch (e) {
      print('❌ Erreur API OT: $e');
      final cachedOrders = await _cacheService.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return cachedOrders;
      }
      rethrow;
    }
  }

  /// Récupérer détail OT par code
  Future<WorkOrder> getOTDetails(String otCode) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return _getMockOrderDetails();
    }

    try {
      print('🌐 Chargement détail OT: $otCode');
      final response = await _apiService.get(
        '$ordersEndpoint/workorders/$otCode',
      );

      if (response['success'] == true && response['data'] != null) {
        final order = WorkOrder.fromJson(response['data']);
        await _cacheService.cacheOrderDetails(otCode, order);
        return order;
      }
      throw Exception('OT non trouvé');
    } catch (e) {
      print('❌ Erreur détail OT: $e');
      final cached = await _cacheService.getCachedOrderDetails(otCode);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Créer nouvel OT
  Future<WorkOrder> createWorkOrder(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        '$ordersEndpoint/workorders/create',
        data: data,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return WorkOrder.fromJson(response['data']);
      }
      throw Exception('Erreur création OT');
    } catch (e) {
      print('❌ Erreur création OT: $e');
      rethrow;
    }
  }

  /// Changer statut OT
  Future<void> changeStatus(String otCode, Map<String, dynamic> statusData) async {
    try {
      await _apiService.put(
        '$ordersEndpoint/workorders/$otCode/status',
        data: statusData,
      );
      await _cacheService.clearCache(); // Invalider cache
    } catch (e) {
      print('❌ Erreur changement statut: $e');
      rethrow;
    }
  }

  /// Récupérer actions OT
  Future<List<dynamic>> getActions(String otCode) async {
    try {
      final response = await _apiService.get(
        '$ordersEndpoint/workorders/$otCode/actions',
      );
      return response['data'] ?? [];
    } catch (e) {
      print('❌ Erreur actions: $e');
      return [];
    }
  }

  /// Récupérer diagnostics OT
  Future<List<dynamic>> getDiagnostics(String otCode) async {
    try {
      final response = await _apiService.get(
        '$ordersEndpoint/workorders/$otCode/diagnostics',
      );
      return response['data'] ?? [];
    } catch (e) {
      print('❌ Erreur diagnostics: $e');
      return [];
    }
  }

  /// Récupérer historique statut
  Future<List<dynamic>> getStatusHistory(String otCode) async {
    try {
      final response = await _apiService.get(
        '$ordersEndpoint/workorders/$otCode/history',
      );
      return response['data'] ?? [];
    } catch (e) {
      print('❌ Erreur historique: $e');
      return [];
    }
  }

  // Mock data conservé pour dev
  WorkOrder _getMockOrderDetails() {
    // ... garder tel quel
  }
}
```

---

## 🧪 TESTS

### 1. Test Backend

```bash
cd backend
python -m pytest tests/ -v
```

Créer `backend/tests/test_ot_service.py`:

```python
import pytest
from app.services.ot_service import OTService

@pytest.mark.asyncio
async def test_get_workorders():
    service = OTService()
    result = await service.get_workorders()
    assert result is not None
    assert isinstance(result, (list, dict))

@pytest.mark.asyncio
async def test_get_workorder_detail():
    service = OTService()
    # Remplacer par un vrai code test
    result = await service.get_workorder_detail("CODE_TEST")
    assert result is not None
```

### 2. Test Frontend Mobile

```dart
// frontend_mobile/test/services/ot_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';

void main() {
  group('OTService Tests', () {
    late OTService otService;

    setUp(() {
      otService = OTService(ApiService());
    });

    test('getAllOrders devrait retourner une liste', () async {
      final orders = await otService.getAllOrders();
      expect(orders, isNotNull);
      expect(orders, isA<List>());
    });

    test('getOTDetails devrait retourner WorkOrder', () async {
      // Utiliser un vrai code OT de test
      final order = await otService.getOTDetails('CODE_TEST');
      expect(order, isNotNull);
      expect(order.code, isNotEmpty);
    });
  });
}
```

---

## ⚡ DÉMARRAGE RAPIDE

### Option A: Via Backend FastAPI (Recommandé)

```powershell
# 1. Configurer backend
cd backend
# Ajouter OT_API_BASE_URL=http://10.101.1.102:8083 dans .env

# 2. Créer fichiers
# - app/services/ot_service.py
# - app/routers/mobile/ot_router.py

# 3. Tester backend
uvicorn app.main:app --reload --port 9099

# 4. Tester endpoint
curl http://localhost:9099/api/v1/mobile/ot/workorders

# 5. Modifier frontend mobile
cd ../frontend_mobile
# Mettre useMockData = false dans ot_service.dart

# 6. Tester app
flutter run -d RFCW41GDR0W
```

### Option B: Direct depuis Flutter (Plus Simple)

```powershell
# 1. Modifier ot_service.dart
# Créer instance ApiService séparée pour OT

# 2. Tester
cd frontend_mobile
flutter run -d RFCW41GDR0W
```

---

## 📊 SUIVI PROGRESSION

| Tâche | Statut | Temps Estimé | Notes |
|-------|--------|--------------|-------|
| Investigation API | ☐ | 1-2h | Tests curl |
| Backend Service | ☐ | 2-3h | ot_service.py |
| Backend Router | ☐ | 1h | ot_router.py |
| Frontend Config | ☐ | 30min | app_config.dart |
| Frontend Service | ☐ | 2h | ot_service.dart |
| Adaptation Models | ☐ | 1-2h | work_order.dart |
| Tests Backend | ☐ | 1h | pytest |
| Tests Frontend | ☐ | 1h | flutter test |
| Tests UI | ☐ | 2h | Navigation complète |
| Documentation | ☐ | 1h | README.md |

---

## 🎯 PROCHAINE ACTION

**COMMENCER PAR**:

```powershell
# Tester API OT
curl http://10.101.1.102:8083/workorders

# Si succès → Analyser JSON → Adapter modèles
# Si échec → Vérifier réseau/firewall
```

**Ensuite**: Choisir Option A (Backend proxy) ou Option B (Direct Flutter)

---

**Auteur**: GitHub Copilot  
**Version**: 1.0  
**Projet**: AppMobileGMAO - SENELEC
