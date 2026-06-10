# 📋 REVUE D'ENSEMBLE DU PROJET GMAO MOBILE

**Date**: 28 Novembre 2025  
**Branche actuelle**: OT_Alima  
**Auteur**: Revue technique complète

---

## 🏗️ ARCHITECTURE GÉNÉRALE DU PROJET

### Structure du Projet

Le projet AppMobileGMAO est une application de **Gestion de Maintenance Assistée par Ordinateur (GMAO)** pour SENELEC avec 3 composants principaux :

```
appmobilegmao/
├── backend/              # API FastAPI (Python)
├── frontend_mobile/      # Application Flutter
├── frontend_web/         # Application Angular
└── auto_merge_branch.sh  # Scripts automatisation
```

---

## 🔧 1. BACKEND (FastAPI + Oracle + Redis)

### Technologies
- **Framework**: FastAPI 0.104+
- **Langage**: Python 3.8+
- **Base de données**: Oracle Database (COSWIN)
- **Cache**: Redis
- **Documentation**: Swagger/OpenAPI

### Configuration Actuelle
- **URL Production**: `https://domtec.senelec.sn:9099`
- **URL Développement**: `http://10.101.2.46:9099`
- **Prefix API**: `/api/v1`

### Structure Backend
```
backend/app/
├── core/
│   ├── config.py          # Variables environnement
│   ├── cache.py           # Gestionnaire Redis
│   └── exceptions.py      # Exceptions personnalisées
├── db/
│   ├── requests.py        # Requêtes SQL Oracle
│   └── sqlalchemy/        # ORM
├── models/
│   ├── equipment_model.py
│   ├── user_model.py
│   ├── zone_model.py
│   └── ... (11+ modèles)
├── routers/
│   ├── auth_router.py
│   ├── mobile/            # Endpoints mobile
│   │   ├── equipment_router.py
│   │   ├── entity_router.py
│   │   ├── zone_router.py
│   │   ├── famille_router.py
│   │   └── ...
│   └── web/               # Endpoints web
│       ├── equipment_router.py
│       ├── user_router.py
│       └── statistique_router.py
├── services/
│   ├── auth_service.py
│   ├── centre_charge_service.py
│   └── ...
└── main.py                # Point d'entrée

```

### Endpoints Actuels (Mobile)

#### Authentification
```
POST /api/v1/auth/login?username=user&password=pass
POST /api/v1/auth/logout?username=user
```

#### Équipements
```
GET  /api/v1/mobile/equipments                    # Liste paginée
GET  /api/v1/mobile/equipments/{code}             # Détail
GET  /api/v1/mobile/equipments/feeders/{famille}  # Feeders
```

#### Données Référentielles
```
GET /api/v1/mobile/entities      # Entités
GET /api/v1/mobile/zones         # Zones
GET /api/v1/mobile/familles      # Familles
GET /api/v1/mobile/costcentres   # Centres de charge
GET /api/v1/mobile/unites        # Unités
```

#### WebSocket
```
WS /ws/notifications/{username}   # Notifications temps réel
```

### Base de Données Oracle

**Tables Principales** (Schéma COSWIN):
- `coswin.t_equipment` - Équipements (26,789+ entrées)
- `coswin.coswin_user` - Utilisateurs
- `coswin.entity` - Entités organisationnelles
- `coswin.zone` - Zones géographiques
- `coswin.category` - Familles d'équipements
- `coswin.costcentre` - Centres de charge

**Fonctions Oracle**:
- `coswin.sn_hierarchie(entity)` - Calcul hiérarchie automatique

---

## 📱 2. FRONTEND MOBILE (Flutter)

### Technologies
- **Framework**: Flutter 3.29.2 (stable)
- **Langage**: Dart ^3.7.2
- **State Management**: Provider
- **Storage Local**: Hive
- **HTTP Client**: Dio 5.4.0
- **Connectivité**: connectivity_plus 5.0.2

### Configuration Actuelle
```dart
// ApiService Configuration
static const String _macIpAddress = 'domtec.senelec.sn';
static const int _defaultPort = 9099;
// Base URL: https://domtec.senelec.sn:9099
```

### Architecture Flutter
```
frontend_mobile/lib/
├── main.dart                    # Point d'entrée
├── models/
│   ├── equipment.dart          # 26,789 équipements en cache
│   ├── work_order.dart         # WorkOrder (API future)
│   ├── order.dart              # Order (UI actuelle)
│   ├── user.dart
│   ├── zone.dart
│   └── ... (14+ modèles)
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── main_screen.dart        # Navigation principale
│   ├── home/
│   ├── equipment/
│   ├── ot/                     # OT Screens
│   │   ├── ot_screen.dart      # Wrapper
│   │   ├── ot_list_screen.dart # Liste des 5 OTs
│   │   ├── ot_info_details_screen.dart  # Formulaire détails
│   │   └── ot_detail_screen.dart        # 6 tabs détails
│   └── di/
├── services/
│   ├── api_service.dart        # Client HTTP Dio
│   ├── auth_service.dart       # Authentification
│   ├── equipment_service.dart  # Équipements
│   ├── ot_service.dart         # ⚠️ OT (mock actuel)
│   ├── hive_service.dart       # Cache local
│   └── websocket_service.dart  # Notifications
├── provider/
│   ├── auth_provider.dart
│   └── equipment_provider.dart
├── widgets/
│   └── custom_bottom_navigation_bar.dart
├── utils/
│   └── responsive.dart
└── theme/
    └── app_theme.dart
```

### Services Principaux

#### 1. **ApiService** (HTTP Client)
```dart
class ApiService {
  - baseUrl: https://domtec.senelec.sn:9099
  - Timeout: 60 secondes
  - Headers: JWT Bearer token
  - Méthodes: get(), post(), put(), delete()
  - Gestion erreurs: ApiException personnalisée
}
```

#### 2. **EquipmentService** (Équipements)
```dart
- getEquipments() ✅ Fonctionnel (26,789 items)
- getEquipmentDetail()
- getEntities(), getZones(), getFamilles()
- getCostCentres(), getUnites()
- Cache automatique avec Hive
```

#### 3. **OTService** (⚠️ ACTUEL - MOCK DATA)
```dart
class OTService {
  static const bool useMockData = true; // ⚠️ À changer
  static const String ordersEndpoint = '/ws/rest/api/orders'; // ⚠️ À changer
  
  - getOTDetails(otNumber) // Mock 5 OTs
  - getAllOrders()         // Mock data
  - updateOT()
  - Cache avec CacheService
}
```

#### 4. **AuthService** (Authentification)
```dart
- login(username, password) ✅ Fonctionnel
- logout()
- JWT tokens (access_token, refresh_token)
- User actuel: Nafissatou DIAGNE
```

### Navigation Flutter

**Structure**: IndexedStack avec CustomBottomNavigationBar (4 tabs)

```
MainScreen
├── [0] HomeScreen
├── [1] EquipmentScreen  ✅ Fonctionnel
├── [2] OtScreen         ⚠️ Mock actuel
│   └── OTListScreen
│       └── OTInfoDetailsScreen (clic sur carte)
│           └── OTDetailScreen (bouton "Détails")
└── [3] DiScreen
```

**Flow OT Corrigé**:
1. User clique tab "OT" → `OTListScreen` (5 cartes bleues)
2. User clique carte → `OTInfoDetailsScreen` (formulaire)
3. User clique "Détails" → `OTDetailScreen` (6 tabs)

### État Actuel OT

**✅ Complété**:
- Navigation corrigée (List → Info → Details)
- Suppression duplication navigation bar
- Overflow UI corrigé (Flexible widgets)
- 5 OT mock affichés

**⚠️ En Attente**:
- Connexion à API OT réelle `http://10.101.1.102:8083/`
- Modèles à adapter selon API
- Synchronisation données

---

## 🌐 3. FRONTEND WEB (Angular)

### Technologies
- **Framework**: Angular 20.3.1
- **UI Library**: PrimeNG 20.3.0
- **Styling**: TailwindCSS 4.1.13
- **State Management**: RxJS 7.8.2
- **Build Tool**: Angular CLI 20.3.2

### Configuration
```typescript
// environment.ts
export const environment = {
    PRODUCTION: true,
    API_URL: 'http://10.101.2.46:9099/api/v1/web',
    API_URL_BASE: 'http://10.101.2.46:9099',
    API_URL_AUTH: 'http://10.101.2.46:9099/api/v1/auth',
    WEBSOCKET_URL: 'ws://10.101.2.46:9099/ws/notifications'
}
```

### Structure Angular
```
frontend_web/src/app/
├── core/
│   ├── services/api/
│   │   ├── auth.service.ts
│   │   ├── equipment.service.ts
│   │   ├── entity.service.ts
│   │   ├── user.service.ts
│   │   ├── statistics.service.ts
│   │   └── websocket.service.ts
│   └── models/
├── layout/
│   ├── component/
│   │   ├── topbar/
│   │   ├── configurator/
│   │   └── ...
│   └── state/layout.service.ts
└── ...
```

---

## 🚀 NOUVELLE INTÉGRATION : API OT

### 📍 Nouvelle API OT

**URL de base**: `http://10.101.1.102:8083/`

### Endpoints Disponibles

#### **Work Order** (Ordre de Travail)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders` | Liste OT avec WHERE clause |
| GET | `/workorders/{id00}` | Détail OT par CODE |
| POST | `/workorders` | Créer OT |
| POST | `/workorders/createSimple` | Créer OT simplifié |
| PUT | `/workorders/{id00}` | Modifier OT |
| DELETE | `/workorders/{id00}` | Supprimer OT |
| GET | `/workorders/{id00}/getStatus` | Statut OT |
| PUT | `/workorders/{id00}/changeStatus` | Changer statut |
| PUT | `/workorders/{id00}/changeStatusAndDates` | Changer statut + dates |
| GET | `/workorders/nextPage` | Liste paginée |
| GET | `/workorders/findSimple` | Liste simple |
| GET | `/workorders/findSimple/nextPage` | Liste simple paginée |

#### **Actions** (Actions OT)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/actions` | Liste actions |
| POST | `/workorders/{id10}/actions` | Ajouter action |
| PUT | `/workorders/{id10}/actions/{id00}` | Modifier action |
| DELETE | `/workorders/{id10}/actions/{id00}` | Supprimer action |
| PUT | `/workorders/{id10}/actions/{id00}/addLinkedFile` | Ajouter fichier |

#### **Diagnostics**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/diagnostics` | Liste diagnostics |
| POST | `/workorders/{id10}/diagnostics` | Ajouter diagnostic |
| PUT | `/workorders/{id10}/diagnostics/{id00}` | Modifier diagnostic |
| DELETE | `/workorders/{id10}/diagnostics/{id00}` | Supprimer diagnostic |

#### **Employés Alloués**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/allocatedemployees` | Liste employés |
| POST | `/workorders/{id10}/allocatedemployees` | Ajouter employé |
| PUT | `/workorders/{id10}/allocatedemployees/{id00}` | Modifier |
| DELETE | `/workorders/{id10}/allocatedemployees/{id00}` | Supprimer |

#### **Feedback Employés**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/employeefeedbacks` | Liste feedbacks |
| POST | `/workorders/{id10}/employeefeedbacks` | Ajouter feedback |
| PUT | `/workorders/{id10}/employeefeedbacks/{id00}` | Modifier |
| DELETE | `/workorders/{id10}/employeefeedbacks/{id00}` | Supprimer |

#### **Installations Utilisées**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/facilitiesused` | Liste installations |
| POST | `/workorders/{id10}/facilitiesused` | Ajouter installation |
| PUT | `/workorders/{id10}/facilitiesused/{id00}` | Modifier |
| DELETE | `/workorders/{id10}/facilitiesused/{id00}` | Supprimer |

#### **Ressources Utilisées**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/resourcesused` | Liste ressources |
| POST | `/workorders/{id10}/resourcesused` | Ajouter ressource |
| PUT | `/workorders/{id10}/resourcesused/{id00}` | Modifier |
| DELETE | `/workorders/{id10}/resourcesused/{id00}` | Supprimer |

#### **Stock Utilisé**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/stockused` | Liste stock |
| POST | `/workorders/{id10}/stockused` | Ajouter stock |
| PUT | `/workorders/{id10}/stockused/{id00}` | Modifier |
| DELETE | `/workorders/{id10}/stockused/{id00}` | Supprimer |
| PUT | `/workorders/{id10}/stockused/updateorcreate` | Modifier/Créer |

#### **Historique Statut**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/statushistory` | Historique statut |

#### **Statuts Validation**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/validationstatuses` | Transitions valides |
| GET | `/workorders/userstatuses/{id00}` | Statut utilisateur |
| GET | `/workorders/userstatuses` | Liste statuts |
| GET | `/workorders/userstatuses/nextPage` | Statuts paginés |

#### **Autres Entités**

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/workorders/{id10}/attributes` | Attributs OT |
| GET | `/workorders/{id10}/free1` | Champs libres 1 |
| GET | `/workorders/{id10}/free2` | Champs libres 2 |
| GET | `/workorders/{id10}/indication` | Indications |

---

## 📝 PLAN D'INTÉGRATION API OT

### Phase 1: Configuration Backend (Si nécessaire)

Si vous souhaitez proxy l'API OT via votre backend FastAPI :

```python
# backend/app/core/config.py
OT_API_BASE_URL = os.getenv("OT_API_BASE_URL", "http://10.101.1.102:8083")
```

```python
# backend/app/services/ot_service.py
import httpx

class OTService:
    def __init__(self):
        self.base_url = "http://10.101.1.102:8083"
        
    async def get_workorders(self, where_clause: str = None):
        async with httpx.AsyncClient() as client:
            params = {"where": where_clause} if where_clause else {}
            response = await client.get(
                f"{self.base_url}/workorders",
                params=params
            )
            return response.json()
```

### Phase 2: Modification Frontend Mobile

#### 1. **Mise à jour OTService**

```dart
// frontend_mobile/lib/services/ot_service.dart

class OTService {
  final ApiService _apiService;
  
  // ⚠️ CHANGEMENTS REQUIS:
  static const bool useMockData = false; // ❌ Désactiver mock
  
  // Option A: Via Backend FastAPI (recommandé pour sécurité)
  static const String ordersEndpoint = '/api/v1/mobile/workorders';
  
  // Option B: Directement vers API OT (si cross-platform OK)
  // Créer une instance séparée pour OT API
  late final ApiService _otApiService;
  
  OTService(this._apiService) {
    // Configuration spécifique pour OT API
    _otApiService = ApiService(
      customBaseUrl: 'http://10.101.1.102:8083'
    );
  }
  
  /// GET /workorders?where=...
  Future<List<WorkOrder>> getAllOrders({String? whereClause}) async {
    try {
      final params = whereClause != null ? {'where': whereClause} : null;
      final response = await _otApiService.get(
        '/workorders',
        queryParameters: params,
      );
      
      // Adapter selon structure réponse API
      List<WorkOrder> orders;
      if (response is List) {
        orders = response.map((json) => WorkOrder.fromJson(json)).toList();
      } else if (response['data'] != null) {
        orders = (response['data'] as List)
            .map((json) => WorkOrder.fromJson(json))
            .toList();
      }
      
      // Cache optionnel
      await _cacheService.cacheOrders(orders);
      return orders;
    } catch (e) {
      // Fallback cache si erreur
      return await _cacheService.getCachedOrders() ?? [];
    }
  }
  
  /// GET /workorders/{code}
  Future<WorkOrder> getOTDetails(String otCode) async {
    final response = await _otApiService.get('/workorders/$otCode');
    return WorkOrder.fromJson(response);
  }
  
  /// POST /workorders/createSimple
  Future<WorkOrder> createSimpleWorkOrder(Map<String, dynamic> data) async {
    final response = await _otApiService.post(
      '/workorders/createSimple',
      data: data,
    );
    return WorkOrder.fromJson(response);
  }
  
  /// PUT /workorders/{code}/changeStatus
  Future<void> changeStatus(String otCode, String newStatus) async {
    await _otApiService.put(
      '/workorders/$otCode/changeStatus',
      data: {'status': newStatus},
    );
  }
  
  /// GET /workorders/{code}/actions
  Future<List<dynamic>> getActions(String otCode) async {
    return await _otApiService.get('/workorders/$otCode/actions');
  }
  
  /// GET /workorders/{code}/diagnostics
  Future<List<dynamic>> getDiagnostics(String otCode) async {
    return await _otApiService.get('/workorders/$otCode/diagnostics');
  }
  
  /// GET /workorders/{code}/allocatedemployees
  Future<List<dynamic>> getAllocatedEmployees(String otCode) async {
    return await _otApiService.get('/workorders/$otCode/allocatedemployees');
  }
  
  /// GET /workorders/{code}/statushistory
  Future<List<dynamic>> getStatusHistory(String otCode) async {
    return await _otApiService.get('/workorders/$otCode/statushistory');
  }
}
```

#### 2. **Adapter WorkOrder Model**

Vous devez adapter `frontend_mobile/lib/models/work_order.dart` selon la structure JSON réelle de l'API `http://10.101.1.102:8083/`.

**Test l'API d'abord**:
```bash
# Tester structure réponse
curl http://10.101.1.102:8083/workorders
curl http://10.101.1.102:8083/workorders/{CODE_TEST}
```

Exemple adaptation:
```dart
class WorkOrder {
  final String code;
  final String? status;
  final String? equipment;
  // ... adapter selon JSON API
  
  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      code: json['code'] ?? json['wowoCode']?.toString() ?? '',
      status: json['userStatus'] ?? json['wowoUserStatus'],
      equipment: json['equipment'] ?? json['wowoEquipment'],
      // ... mapper tous les champs
    );
  }
}
```

#### 3. **Mise à jour UI Screens**

Les screens actuels devraient fonctionner si WorkOrder model est bien adapté:

- `ot_list_screen.dart` - Afficher liste réelle
- `ot_info_details_screen.dart` - Formulaire avec vraies données
- `ot_detail_screen.dart` - 6 tabs avec données API

### Phase 3: Tests

```dart
// Test dans ot_service.dart
void testOTAPI() async {
  final otService = OTService(ApiService());
  
  // Test 1: Liste OT
  final orders = await otService.getAllOrders();
  print('📋 ${orders.length} OT récupérés');
  
  // Test 2: Détail OT
  if (orders.isNotEmpty) {
    final detail = await otService.getOTDetails(orders.first.code);
    print('✅ Détail OT: ${detail.code}');
  }
  
  // Test 3: Actions
  final actions = await otService.getActions(orders.first.code);
  print('🔧 ${actions.length} actions');
}
```

---

## 🔐 SÉCURITÉ ET BONNES PRATIQUES

### 1. **Authentification**

L'API OT `http://10.101.1.102:8083/` nécessite-t-elle une authentification ?

**Si OUI**:
```dart
// Ajouter headers auth
_otApiService.dio.options.headers['Authorization'] = 'Bearer $token';
// ou
_otApiService.dio.options.headers['API-Key'] = 'votre_clé';
```

### 2. **Variables d'Environnement**

Créer un fichier de configuration:

```dart
// frontend_mobile/lib/config/app_config.dart
class AppConfig {
  static const String mainApiUrl = 'https://domtec.senelec.sn:9099';
  static const String otApiUrl = 'http://10.101.1.102:8083';
  
  static const bool useOTMockData = false; // Production
  static const bool useOTMockData = true;  // Dev
}
```

### 3. **Gestion Erreurs**

```dart
try {
  final orders = await otService.getAllOrders();
} on ApiException catch (e) {
  if (e.statusCode == 404) {
    // Aucun OT trouvé
  } else if (e.statusCode == 401) {
    // Non autorisé
  }
} catch (e) {
  // Erreur réseau générique
}
```

---

## 📊 ÉTAT ACTUEL DU PROJET

### ✅ Fonctionnel
- Backend FastAPI avec Oracle + Redis
- Frontend Mobile Flutter (Équipements)
- Frontend Web Angular
- Authentification JWT
- Cache local Hive (26,789 équipements)
- WebSocket notifications
- Navigation OT corrigée
- UI responsive

### ⚠️ En Cours
- **Intégration API OT** `http://10.101.1.102:8083/`
- Connexion données réelles OT
- Tests end-to-end OT

### 🔜 À Faire
1. Tester API OT avec curl/Postman
2. Analyser structure JSON réponses
3. Adapter WorkOrder model
4. Modifier OTService (désactiver mock)
5. Tester navigation complète
6. Valider CRUD OT
7. Gestion erreurs robuste
8. Synchronisation offline/online

---

## 🛠️ PROCHAINES ÉTAPES RECOMMANDÉES

### Étape 1: Investigation API OT
```bash
# Tester endpoints
curl http://10.101.1.102:8083/workorders
curl http://10.101.1.102:8083/workorders/validationstatuses
```

### Étape 2: Créer Service Backend (Option Recommandée)
Créer proxy dans FastAPI pour sécuriser et centraliser:
```
backend/app/routers/mobile/ot_router.py
backend/app/services/ot_service.py
```

### Étape 3: Adapter Frontend
- Désactiver `useMockData = false`
- Configurer `otApiUrl`
- Adapter modèles
- Tests

### Étape 4: Tests Complets
- Liste OT
- Détail OT
- Création OT
- Modification statut
- Actions, diagnostics, etc.

---

## 📚 DOCUMENTATION UTILE

### Endpoints API Actuels
- **Swagger Backend**: `https://domtec.senelec.sn:9099/docs`
- **Health Check**: `https://domtec.senelec.sn:9099/health`

### Commandes Utiles

```bash
# Backend
cd backend
uvicorn app.main:app --reload --port 9099

# Frontend Mobile
cd frontend_mobile
flutter run -d RFCW41GDR0W

# Frontend Web
cd frontend_web
ng serve
```

---

## 🎯 RÉSUMÉ EXÉCUTIF

### Projet GMAO Mobile SENELEC

**Objectif**: Application mobile/web pour gestion maintenance équipements SENELEC

**Stack**:
- Backend: FastAPI + Oracle + Redis
- Mobile: Flutter 3.29.2 + Hive
- Web: Angular 20 + PrimeNG

**État Actuel**:
- ✅ Module Équipements: Opérationnel (26,789 items)
- ✅ Authentification: Fonctionnelle
- ✅ Navigation: Corrigée
- ⚠️ Module OT: Mock data (5 OTs fictifs)

**Action Immédiate**: 
Intégrer API OT réelle `http://10.101.1.102:8083/` pour remplacer données mockées

**Bénéfices**:
- Données temps réel
- CRUD complet OT
- Historique statuts
- Gestion actions/diagnostics/ressources

---

**Auteur**: GitHub Copilot  
**Version**: 1.0  
**Dernière mise à jour**: 28 Novembre 2025
