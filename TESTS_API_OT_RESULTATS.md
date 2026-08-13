# 🔍 DÉCOUVERTES API OT - Tests Initiaux

**Date**: 28 Novembre 2025  
**API Testée**: `http://10.101.1.102:8083/`

---

## ✅ RÉSULTATS TESTS

### 1. Connectivité de Base

```powershell
curl http://10.101.1.102:8083/
```

**Résultat**: ✅ **SUCCÈS** (HTTP 200)

**Détails**:
- Serveur: **WildFly** (JBoss Application Server)
- Company: Siveco Group
- Headers sécurité présents:
  - X-XSS-Protection: 1; mode=block
  - X-Frame-Options: SAMEORIGIN
  - Referrer-Policy: strict-origin-when-cross-origin
  - Content-Security-Policy configurée

**Conclusion**: L'API est accessible sur le réseau.

---

### 2. Test Endpoint `/workorders`

```powershell
GET http://10.101.1.102:8083/workorders
```

**Résultat**: ❌ **404 - Not Found**

**Analyse**: L'endpoint n'existe pas à la racine. Le path complet est probablement différent.

---

### 3. Test Endpoint REST `/ws/rest/workorders`

```powershell
GET http://10.101.1.102:8083/ws/rest/workorders
```

**Résultat**: 🔐 **401 - Unauthorized**

**Analyse**: 
- ✅ L'endpoint **EXISTE** !
- ❌ Nécessite une **authentification**
- Le path correct semble être: `/ws/rest/workorders`

---

## 📋 INFORMATIONS CRITIQUES

### Structure URL Corrigée

**Base URL API OT**: `http://10.101.1.102:8083/ws/rest`

**Endpoints Probables**:
```
GET  http://10.101.1.102:8083/ws/rest/workorders
GET  http://10.101.1.102:8083/ws/rest/workorders/{id00}
POST http://10.101.1.102:8083/ws/rest/workorders
PUT  http://10.101.1.102:8083/ws/rest/workorders/{id00}
...
```

### Authentification Requise

L'API nécessite une authentification. Méthodes possibles:

1. **Basic Authentication**
   ```
   Authorization: Basic base64(username:password)
   ```

2. **Bearer Token**
   ```
   Authorization: Bearer TOKEN
   ```

3. **API Key**
   ```
   X-API-Key: YOUR_KEY
   ```

4. **Session Cookie**
   ```
   Cookie: JSESSIONID=...
   ```

---

## ✅ SOLUTION TROUVÉE (28 Nov 2025)

### Authentification Réussie

**Type**: Basic Authentication (Windows credentials)

**Credentials**:
- Username: `coswinws`
- Password: `supervisor`

**Paramètres Requis**:
- `dataSource=coswin`
- `cwUser=supervisor`

**Test Réussi**:
```bash
GET http://10.101.1.102:8083/ws/rest/workorders/2025248525?cwUser=supervisor&dataSource=coswin
Status: 200 OK
```

### 2. Tester Authentification

Une fois les credentials obtenus:

```powershell
# Test Basic Auth
$cred = "username:password"
$encodedCred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cred))
$headers = @{
    "Authorization" = "Basic $encodedCred"
    "Content-Type" = "application/json"
}

Invoke-WebRequest -Uri "http://10.101.1.102:8083/ws/rest/workorders" `
    -Headers $headers -Method GET
```

```powershell
# Test Bearer Token
$headers = @{
    "Authorization" = "Bearer YOUR_TOKEN"
    "Content-Type" = "application/json"
}

Invoke-WebRequest -Uri "http://10.101.1.102:8083/ws/rest/workorders" `
    -Headers $headers -Method GET
```

### 3. Documenter Structure JSON

Une fois authentifié, sauvegarder la réponse:

```powershell
Invoke-WebRequest -Uri "http://10.101.1.102:8083/ws/rest/workorders" `
    -Headers $headers | 
    Select-Object -ExpandProperty Content | 
    Out-File -FilePath "workorders_response.json"
```

---

## 📝 MODIFICATIONS CODE REQUISES

### Backend FastAPI

```python
# backend/app/core/config.py
OT_API_BASE_URL = "http://10.101.1.102:8083/ws/rest"  # ✅ Corriger path
OT_API_USERNAME = os.getenv("OT_API_USERNAME")
OT_API_PASSWORD = os.getenv("OT_API_PASSWORD")
# OU
OT_API_TOKEN = os.getenv("OT_API_TOKEN")
```

```python
# backend/app/services/ot_service.py
import httpx
from base64 import b64encode

class OTService:
    def __init__(self):
        self.base_url = "http://10.101.1.102:8083/ws/rest"
        self.username = OT_API_USERNAME
        self.password = OT_API_PASSWORD
        
    def _get_auth_headers(self):
        # Option 1: Basic Auth
        credentials = f"{self.username}:{self.password}"
        encoded = b64encode(credentials.encode()).decode()
        return {
            "Authorization": f"Basic {encoded}",
            "Content-Type": "application/json"
        }
        
        # Option 2: Bearer Token
        # return {
        #     "Authorization": f"Bearer {self.token}",
        #     "Content-Type": "application/json"
        # }
    
    async def get_workorders(self, where_clause=None):
        async with httpx.AsyncClient(timeout=30) as client:
            params = {"where": where_clause} if where_clause else {}
            response = await client.get(
                f"{self.base_url}/workorders",
                headers=self._get_auth_headers(),
                params=params
            )
            response.raise_for_status()
            return response.json()
```

### Frontend Mobile

```dart
// frontend_mobile/lib/services/ot_service.dart

class OTService {
  // ✅ URL corrigée
  static const String otApiBaseUrl = 'http://10.101.1.102:8083/ws/rest';
  
  // Si authentification directe depuis Flutter (déconseillé)
  final String username = 'YOUR_USERNAME';
  final String password = 'YOUR_PASSWORD';
  
  Map<String, String> _getAuthHeaders() {
    // Basic Auth
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }
  
  Future<List<WorkOrder>> getAllOrders() async {
    // Option A: Via backend FastAPI (RECOMMANDÉ)
    final response = await _apiService.get('/api/v1/mobile/ot/workorders');
    
    // Option B: Direct (nécessite auth)
    // final dio = Dio();
    // final response = await dio.get(
    //   '$otApiBaseUrl/workorders',
    //   options: Options(headers: _getAuthHeaders()),
    // );
    
    return parseWorkOrders(response);
  }
}
```

---

## 🎯 PROCHAINES ÉTAPES IMMÉDIATES

### Étape 1: Obtenir Authentification

**PRIORITÉ MAXIMALE** : Contacter l'équipe/admin de l'API OT pour:
1. Type d'authentification
2. Credentials (username/password ou token)
3. Documentation API complète
4. Exemples d'appels

### Étape 2: Valider Endpoints

Une fois authentifié, tester tous les endpoints:

```powershell
# Liste OT
GET /ws/rest/workorders

# Détail OT
GET /ws/rest/workorders/{CODE}

# Statuts
GET /ws/rest/workorders/validationstatuses

# Actions
GET /ws/rest/workorders/{CODE}/actions

# Diagnostics
GET /ws/rest/workorders/{CODE}/diagnostics
```

### Étape 3: Mapper Structure JSON

Analyser la structure pour adapter `WorkOrder` model:

```dart
class WorkOrder {
  // Adapter selon JSON réel de l'API
  final String code;
  final String? status;
  // ...
  
  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    // Mapper selon structure réelle
  }
}
```

### Étape 4: Implémenter Service

Une fois structure connue:
1. Créer `backend/app/services/ot_service.py`
2. Créer `backend/app/routers/mobile/ot_router.py`
3. Modifier `frontend_mobile/lib/services/ot_service.dart`
4. Tester end-to-end

---

## 📊 COMPARAISON OPTIONS

| Approche | Avantages | Inconvénients |
|----------|-----------|---------------|
| **Via Backend FastAPI** | ✅ Sécurité (credentials serveur)<br>✅ Logs centralisés<br>✅ Cache possible<br>✅ Transformation données | ⚠️ Point de passage supplémentaire<br>⚠️ Latence légère |
| **Direct depuis Flutter** | ✅ Appels directs rapides<br>✅ Moins de complexité | ❌ Credentials exposés dans app<br>❌ Pas de cache serveur<br>❌ CORS potentiels |

**RECOMMANDATION**: **Via Backend FastAPI** pour sécurité et flexibilité.

---

## 🔐 SÉCURITÉ

### ⚠️ NE JAMAIS

- ❌ Hardcoder credentials dans le code source
- ❌ Commiter credentials dans Git
- ❌ Exposer API keys dans l'application mobile

### ✅ TOUJOURS

- ✅ Utiliser variables d'environnement (backend)
- ✅ Passer par backend proxy pour authentification
- ✅ Utiliser HTTPS en production
- ✅ Implémenter rate limiting
- ✅ Logger les erreurs (pas les credentials)

---

## 📞 CONTACT REQUIS

**À DEMANDER À L'ÉQUIPE API OT**:

1. **Type d'authentification** ?
   - [ ] Basic Auth (username/password)
   - [ ] Bearer Token
   - [ ] API Key
   - [ ] OAuth2
   - [ ] Session Cookie

2. **Credentials** ?
   - Username: _____________
   - Password: _____________
   - Token: _____________
   - API Key: _____________

3. **Documentation API** ?
   - URL Swagger/OpenAPI: _____________
   - Exemples Postman: _____________
   - Wiki/Confluence: _____________

4. **Limitations** ?
   - Rate limiting: _____________
   - Max résultats par requête: _____________
   - Timeout: _____________

5. **Environnements** ?
   - Dev: _____________
   - Test: _____________
   - Production: http://10.101.1.102:8083

---

## 📝 RÉSUMÉ EXÉCUTIF

### ✅ Ce qu'on sait

- **API accessible**: http://10.101.1.102:8083/
- **Serveur**: WildFly (JBoss)
- **Path REST**: `/ws/rest/workorders`
- **Authentification**: Requise (401 Unauthorized)

### ❌ Ce qu'on ne sait pas (BLOQUANT)

- **Type d'authentification** : Basic Auth ? Bearer ? API Key ?
- **Credentials** : Username/password ? Token ?
- **Structure JSON** : Format des work orders ?
- **Documentation** : Swagger ? Postman ?

### 🎯 Action Immédiate

**CONTACTER L'ADMINISTRATEUR API OT** pour obtenir:
1. Credentials d'authentification
2. Documentation complète
3. Exemples d'utilisation

Une fois obtenu → Continuer avec implémentation backend/frontend.

---

**Statut**: ✅ **DÉBLOQUÉ** - Authentification réussie  
**Prochaine étape**: Implémenter backend/frontend  
**Auteur**: GitHub Copilot  
**Date**: 28 Novembre 2025  
**Exemple**: Voir `API_OT_SUCCESS_EXAMPLE.json`
