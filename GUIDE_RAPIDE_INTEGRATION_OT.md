# 🎯 GUIDE RAPIDE - INTÉGRATION API OT

**Pour**: Développeur Backend/Mobile  
**Objectif**: Connecter module OT à l'API `http://10.101.1.102:8083/ws/rest`  
**Durée estimée**: 8-11 heures (après obtention credentials)

---

## ⚡ QUICK START

### Étape 1: Obtenir Credentials (BLOQUANT) 🔴

```bash
# Contacter admin API OT pour obtenir:
Username: _______________
Password: _______________
# OU
Token: _______________
```

### Étape 2: Tester API (5 min)

```powershell
# Windows PowerShell
$user = "USERNAME"
$pass = "PASSWORD"
$cred = "$user:$pass"
$encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
$headers = @{
    "Authorization" = "Basic $encoded"
    "Content-Type" = "application/json"
}

# Test connexion
Invoke-WebRequest -Uri "http://10.101.1.102:8083/ws/rest/workorders" `
    -Headers $headers -Method GET

# Sauvegarder structure JSON
Invoke-WebRequest -Uri "http://10.101.1.102:8083/ws/rest/workorders" `
    -Headers $headers | 
    Select-Object -ExpandProperty Content | 
    Out-File -FilePath "ot_response.json"
```

### Étape 3: Backend FastAPI (2-3h)

#### A. Configuration

```bash
# backend/.env
OT_API_BASE_URL=http://10.101.1.102:8083/ws/rest
OT_API_USERNAME=votre_username
OT_API_PASSWORD=votre_password
OT_API_TIMEOUT=30
```

#### B. Service

```bash
# Créer backend/app/services/ot_service.py
code backend/app/services/ot_service.py
```

<details>
<summary>Code complet ot_service.py (cliquer pour voir)</summary>

```python
import httpx
from base64 import b64encode
from typing import List, Optional, Dict, Any
from app.core.config import (
    OT_API_BASE_URL, 
    OT_API_USERNAME, 
    OT_API_PASSWORD,
    OT_API_TIMEOUT
)

class OTService:
    def __init__(self):
        self.base_url = OT_API_BASE_URL
        self.username = OT_API_USERNAME
        self.password = OT_API_PASSWORD
        self.timeout = OT_API_TIMEOUT
        
    def _get_auth_headers(self) -> Dict[str, str]:
        """Headers avec Basic Auth"""
        credentials = f"{self.username}:{self.password}"
        encoded = b64encode(credentials.encode()).decode()
        return {
            "Authorization": f"Basic {encoded}",
            "Content-Type": "application/json"
        }
    
    async def get_workorders(
        self, 
        where_clause: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """GET /workorders"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            params = {"where": where_clause} if where_clause else {}
            response = await client.get(
                f"{self.base_url}/workorders",
                headers=self._get_auth_headers(),
                params=params
            )
            response.raise_for_status()
            return response.json()
    
    async def get_workorder_detail(self, code: str) -> Dict[str, Any]:
        """GET /workorders/{code}"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}",
                headers=self._get_auth_headers()
            )
            response.raise_for_status()
            return response.json()
    
    async def create_simple_workorder(
        self, 
        data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """POST /workorders/createSimple"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/workorders/createSimple",
                headers=self._get_auth_headers(),
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
                headers=self._get_auth_headers(),
                json=status_data
            )
            response.raise_for_status()
            return response.json()
    
    async def get_actions(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/actions"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/actions",
                headers=self._get_auth_headers()
            )
            response.raise_for_status()
            return response.json()
    
    async def get_status_history(self, code: str) -> List[Dict[str, Any]]:
        """GET /workorders/{code}/statushistory"""
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                f"{self.base_url}/workorders/{code}/statushistory",
                headers=self._get_auth_headers()
            )
            response.raise_for_status()
            return response.json()
```
</details>

#### C. Router

```bash
# Créer backend/app/routers/mobile/ot_router.py
code backend/app/routers/mobile/ot_router.py
```

<details>
<summary>Code complet ot_router.py (cliquer pour voir)</summary>

```python
from fastapi import APIRouter, HTTPException
from typing import Optional, Dict, Any
from app.services.ot_service import OTService

router = APIRouter(prefix="/ot", tags=["OT Mobile"])

@router.get("/workorders")
async def get_workorders(where: Optional[str] = None):
    """Liste des ordres de travail"""
    try:
        ot_service = OTService()
        result = await ot_service.get_workorders(where)
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
</details>

#### D. Enregistrer Router

```python
# backend/app/main.py
# Ajouter après les imports
from app.routers.mobile.ot_router import router as ot_router_mobile

# Ajouter après les autres routers mobile
app.include_router(ot_router_mobile, prefix=f"{PREFIX}/mobile")
```

#### E. Tester Backend

```bash
# Démarrer serveur
cd backend
uvicorn app.main:app --reload --port 9099

# Dans autre terminal
curl http://localhost:9099/api/v1/mobile/ot/workorders

# Ou ouvrir Swagger
# http://localhost:9099/docs#/OT%20Mobile
```

### Étape 4: Frontend Mobile (3-4h)

#### A. Configuration

```bash
# Créer frontend_mobile/lib/config/app_config.dart
code frontend_mobile/lib/config/app_config.dart
```

```dart
class AppConfig {
  static const String mainApiUrl = 'https://domtec.senelec.sn:9099';
  static const String otApiEndpoint = '/api/v1/mobile/ot';
  static const bool useOTMockData = false; // ❌ Désactiver mock
}
```

#### B. Modifier OTService

```bash
code frontend_mobile/lib/services/ot_service.dart
```

<details>
<summary>Changements requis (cliquer pour voir)</summary>

```dart
// Ligne 11-12
static const bool useMockData = false; // ❌ Changer
static const String ordersEndpoint = '/api/v1/mobile/ot'; // ✅ Changer

// Ligne 72 - Méthode getAllOrders()
Future<List<WorkOrder>> getAllOrders({String? whereClause}) async {
  if (useMockData) {
    // ... code mock existant
  }

  final hasInternet = await hasInternetConnection();
  if (!hasInternet) {
    // ... code cache existant
  }

  try {
    print('🌐 Chargement OT depuis API');
    
    final params = whereClause != null ? {'where': whereClause} : null;
    final response = await _apiService.get(
      '$ordersEndpoint/workorders',
      queryParameters: params,
    );

    List<WorkOrder> orders;
    
    // Adapter selon structure API réelle
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      if (data is List) {
        orders = data.map((json) => WorkOrder.fromJson(json)).toList();
      } else {
        // Adapter selon structure
        orders = [WorkOrder.fromJson(data)];
      }
    } else {
      throw Exception('Format réponse invalide');
    }

    await _cacheService.cacheOrders(orders);
    print('✅ ${orders.length} OT sauvegardés');

    return orders;
  } catch (e) {
    print('❌ Erreur: $e');
    final cached = await _cacheService.getCachedOrders();
    if (cached != null) return cached;
    rethrow;
  }
}
```
</details>

#### C. Adapter WorkOrder Model

**IMPORTANT**: Analyser `ot_response.json` de l'étape 2 pour adapter le modèle.

```bash
code frontend_mobile/lib/models/work_order.dart
```

Exemple adaptation selon JSON réel:

```dart
factory WorkOrder.fromJson(Map<String, dynamic> json) {
  return WorkOrder(
    // Mapper selon noms réels de l'API
    pkWorkOrder: json['id'] ?? json['pkWorkOrder'],
    wowoCode: json['code'] ?? json['wowoCode'],
    wowoUserStatus: json['status'] ?? json['wowoUserStatus'],
    // ... adapter tous les champs
  );
}
```

#### D. Tester Mobile

```bash
cd frontend_mobile
flutter run -d RFCW41GDR0W

# Observer logs
# 🌐 Chargement OT depuis API
# ✅ X OT sauvegardés
```

### Étape 5: Tests (2-3h)

#### Backend

```bash
cd backend

# Créer tests/test_ot_service.py
pytest tests/test_ot_service.py -v
```

#### Mobile

```bash
cd frontend_mobile

# Tests unitaires
flutter test test/services/ot_service_test.dart

# Tests UI
flutter run -d RFCW41GDR0W
# Naviguer: OT tab → Cliquer carte → Vérifier données
```

---

## ✅ CHECKLIST VALIDATION

### Backend ✓

- [ ] OT_API credentials dans .env
- [ ] ot_service.py créé et fonctionne
- [ ] ot_router.py créé et enregistré
- [ ] GET /workorders retourne données
- [ ] GET /workorders/{code} retourne détail
- [ ] Swagger docs mise à jour
- [ ] Tests pytest passent

### Mobile ✓

- [ ] useMockData = false
- [ ] ordersEndpoint configuré
- [ ] WorkOrder.fromJson adapté
- [ ] getAllOrders() retourne vraies données
- [ ] getOTDetails() retourne détail
- [ ] Cache fonctionne
- [ ] Mode offline OK
- [ ] Navigation List→Info→Details OK
- [ ] Tests flutter passent

### Validation Finale ✓

- [ ] Login mobile → Liste OT s'affiche
- [ ] Clic carte OT → Info details charge
- [ ] Bouton "Détails" → Details screen avec données
- [ ] Mode avion → Cache fonctionne
- [ ] Reconnexion → Sync données
- [ ] Pas d'erreurs console
- [ ] Performance acceptable (<2s chargement)

---

## 🐛 TROUBLESHOOTING

### Erreur: 401 Unauthorized

```python
# Vérifier credentials dans .env
print(f"Username: {OT_API_USERNAME}")
print(f"Password: {'*' * len(OT_API_PASSWORD)}")
```

### Erreur: Structure JSON invalide

```dart
// Ajouter debug
print('📋 Response structure: ${response.runtimeType}');
print('📋 Response keys: ${response.keys}');
```

### Erreur: Network timeout

```python
# Augmenter timeout
OT_API_TIMEOUT=60  # .env
```

### Erreur: CORS

```python
# Backend main.py - Ajouter IP API OT
allow_origins=[
    "*",
    "http://10.101.1.102:8083",
]
```

---

## 📊 ESTIMATION TEMPS

| Tâche | Durée | Dépendance |
|-------|-------|------------|
| Obtenir credentials | 1-48h | Admin API |
| Tester API | 30min | Credentials |
| Backend service | 2h | Tests API |
| Backend router | 1h | Service |
| Mobile config | 30min | Backend |
| Mobile service | 2h | Config |
| Adapter modèle | 1h | JSON structure |
| Tests backend | 1h | Backend complet |
| Tests mobile | 1h | Mobile complet |
| Validation finale | 1h | Tout |
| **TOTAL** | **10h** | + délai admin |

---

## 🎯 RÉSULTAT FINAL

Après cette intégration:

```
✅ Module OT 100% Fonctionnel
  ├─ Backend proxy sécurisé
  ├─ API OT connectée
  ├─ Données réelles
  ├─ Cache fonctionnel
  ├─ Mode offline
  └─ Navigation complète

📱 User Experience
  └─ Login → OT tab → Liste vraies OTs
      └─ Clic carte → Détails formulaire
          └─ Bouton "Détails" → 6 tabs complets
```

---

## 📞 AIDE

- **Bloqué sur API**: Voir [TESTS_API_OT_RESULTATS.md](TESTS_API_OT_RESULTATS.md)
- **Architecture**: Voir [REVUE_PROJET_ET_INTEGRATION_OT_API.md](REVUE_PROJET_ET_INTEGRATION_OT_API.md)
- **Plan complet**: Voir [PLAN_INTEGRATION_OT_API.md](PLAN_INTEGRATION_OT_API.md)

---

**Bon courage ! 🚀**

**Version**: 1.0  
**Date**: 28 Novembre 2025  
**Auteur**: GitHub Copilot
