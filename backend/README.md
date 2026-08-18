# 🏢 SENELEC GMAO Mobile API

![Python](https://img.shields.io/badge/Python-3.8+-blue?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green?logo=fastapi&logoColor=white)
![Oracle](https://img.shields.io/badge/Oracle-Database-red?logo=oracle&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-Cache-red?logo=redis&logoColor=white)
![License](https://img.shields.io/badge/License-SENELEC-blue)
![Status](https://img.shields.io/badge/Status-Production-brightgreen)
![API](https://img.shields.io/badge/API-REST-orange)
![Mobile](https://img.shields.io/badge/Mobile-Optimized-purple)

[![Documentation](https://img.shields.io/badge/Documentation-Swagger-85EA2D?logo=swagger&logoColor=white)](http://localhost:8000/docs)
[![Health Check](https://img.shields.io/badge/Health-Check-success?logo=github&logoColor=white)](http://localhost:8000/health)
[![Code Style](https://img.shields.io/badge/Code%20Style-PEP8-black)](https://www.python.org/dev/peps/pep-0008/)

Une API REST optimisée pour l'application mobile de gestion de maintenance assistée par ordinateur (GMAO) de SENELEC, développée avec FastAPI et Oracle Database.

## 📋 Table des matières

- 🎯 Aperçu du projet
- ✨ Fonctionnalités
- 🏗️ Architecture
- 🚀 Installation
- ⚙️ Configuration
- 📖 Documentation API
- 🔄 Cache Redis
- 📊 Base de données
- 🧪 Tests
- 📱 Endpoints Mobile
- 🛠️ Développement

## 🎯 Aperçu du projet

Cette API backend fournit les services nécessaires pour l'application mobile GMAO de SENELEC, permettant aux techniciens de terrain d'accéder aux informations des équipements, gérer les maintenances et consulter les données hiérarchiques des entités.

### 🔧 Technologies utilisées

- **Backend**: FastAPI (Python 3.8+)
- **Base de données**: Oracle Database
- **Cache**: Redis
- **ORM**: Pydantic Models
- **Documentation**: Swagger/OpenAPI
- **Logs**: Python Logging

## ✨ Fonctionnalités

### 🔐 Authentification

- Connexion/déconnexion utilisateur
- Gestion de sessions avec cache
- Hiérarchie utilisateur automatique

### 📦 Gestion des équipements

- **Infinite scroll** optimisé pour mobile
- Filtrage par entité, zone, famille
- Recherche textuelle avancée
- Détails complets d'équipement
- Coordonnées GPS intégrées

### 🏢 Endpoints données référentielles

- **Entités** avec hiérarchie automatique
- **Zones géographiques**
- **Familles d'équipements**
- **Centres de charge**
- **Unités organisationnelles**
- **Feeders** (équipements de référence)

### ⚡ Performance

- Cache Redis intelligent
- Pagination optimisée
- Gestion automatique de la hiérarchie
- Fallback gracieux sans cache

## 🏗️ Architecture

```
backend/
├── app/
│   ├── core/           # Configuration et cache
│   │   ├── config.py   # Variables d'environnement
│   │   └── cache.py    # Gestionnaire Redis
│   ├── db/             # Base de données
│   │   ├── database.py # Connexion Oracle
│   │   └── requests.py # Requêtes SQL
│   ├── models/         # Modèles Pydantic
│   │   └── models.py   # Tous les modèles
│   ├── routers/        # Endpoints API
│   │   ├── equipment_router.py
│   │   ├── user_router.py
│   │   ├── entity_router.py
│   │   └── ...
│   ├── services/       # Logique métier
│   │   ├── equipment_service.py
│   │   ├── user_service.py
│   │   └── ...
│   ├── schemas/        # Schémas de réponse
│   └── main.py         # Point d'entrée
├── .env.prod          # Variables d'environnement
├── requirements.txt   # Dépendances Python
└── README.md
```

## 🚀 Installation

### Prérequis

- Python 3.8+
- Oracle Database (accessible)
- Redis Server (optionnel)
- pip ou conda

### 1. Cloner le projet

```bash
git clone <repository-url>
cd backend
```

### 2. Créer l'environnement virtuel

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows
```

### 3. Installer les dépendances

```bash
pip install -r requirements.txt
```

### 4. Configuration des variables d'environnement

Créer le fichier .env.prod :

```env
# Base de données Oracle
DB_NAME=COSWIN
DB_USERNAME=your_username
DB_PASSWORD=your_password
DB_HOST=your_oracle_host
DB_SERVICE_NAME=your_service_name

# Redis (optionnel)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Limites
DEFAULT_LIMIT=20
MAX_LIMIT=100
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=50
```

### 5. Démarrer l'application

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## ⚙️ Configuration

### Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|---------|
| `DB_HOST` | Serveur Oracle | - |
| `DB_USERNAME` | Nom d'utilisateur Oracle | - |
| `DB_PASSWORD` | Mot de passe Oracle | - |
| `DB_SERVICE_NAME` | Service Oracle | - |
| `REDIS_HOST` | Serveur Redis | localhost |
| `REDIS_PORT` | Port Redis | 6379 |
| `DEFAULT_LIMIT` | Limite par défaut | 20 |
| `MAX_LIMIT` | Limite maximale | 100 |

### Cache Redis

- **CACHE_TTL_SHORT**: 5 minutes (données fréquemment modifiées)
- **CACHE_TTL_MEDIUM**: 30 minutes (données moyennement stables)
- **CACHE_TTL_LONG**: 1 heure (données de référence)

## 📖 Documentation API

### Accès à la documentation

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

### Health Check

```bash
curl http://localhost:8000/health
```

## 📱 Endpoints Mobile

### 🔐 Authentification

```http
POST /api/v1/auth/login?username=user&password=pass
POST /api/v1/auth/logout?username=user
```

### 📦 Équipements

```http
# Liste avec hiérarchie automatique
GET /api/v1/equipments?entity=SDDV&zone=ZONE_A&famille=EPI&search=transfo

# Détail d'un équipement
GET /api/v1/equipments/{code}

# Feeders par famille
GET /api/v1/equipments/feeders/{famille}
```

### 🏢 Données référentielles

```http
# Entités avec hiérarchie
GET /api/v1/entity?limit=50&code=SDDV
GET /api/v1/entity/hierarchy/{entity_code}

# Zones par entité
GET /api/v1/zone?entity=SDDV

# Familles par entité
GET /api/v1/famille?entity=SDDV

# Centres de charge
GET /api/v1/centre-charge?entity=SDDV

# Unités
GET /api/v1/unite?entity=SDDV
```

## 🔄 Cache Redis

### Stratégies de cache

- **Équipements**: Cache par entité + filtres
- **Hiérarchie**: Cache long terme
- **Authentification**: Cache session utilisateur
- **Données référentielles**: Cache moyen terme

### Gestion du cache

```python
# Vider le cache
cache.clear_all()

# Statistiques
cache.get_cache_info()

# Cache spécifique
cache.delete("mobile_eq_SDDV_*")
```

## 📊 Base de données

### Tables principales

- **`coswin.t_equipment`**: Équipements
- **`coswin.coswin_user`**: Utilisateurs
- **`coswin.entity`**: Entités organisationnelles
- **`coswin.zone`**: Zones géographiques
- **`coswin.category`**: Familles d'équipements
- **`coswin.costcentre`**: Centres de charge

### Fonction Oracle

- **`coswin.sn_hierarchie(entity)`**: Calcul de hiérarchie

## 🧪 Tests

### Test de connexion

```bash
python -c "from app.db.database import test_connection; test_connection()"
```

### Test Redis

```bash
python -c "from app.core.cache import cache; print(f'Redis: {cache.is_available}')"
```

### Tests d'endpoints

```bash
# Test équipements
curl "http://localhost:8000/api/v1/equipments?entity=DD&limit=5"

# Test authentification
curl -X POST "http://localhost:8000/api/v1/auth/login?username=test&password=test"
```

## 🛠️ Développement

### Structure des modèles Pydantic

```python
class EquipmentModel(BaseModel):
    id: str
    code: str
    description: str
    entity: str
    zone: str
    famille: str
    # ... autres champs
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'EquipmentModel':
        # Mapping depuis Oracle
        
    def to_mobile_dict(self) -> Dict[str, Any]:
        # Format optimisé mobile
```

### Ajout d'un nouveau service

1. Créer le modèle dans models.py
2. Ajouter la requête SQL dans requests.py
3. Créer le service dans `services/`
4. Créer le routeur dans `routers/`
5. Inclure le routeur dans main.py

### Gestion des erreurs

```python
try:
    result = service_function()
    return {"status": "success", "data": result}
except oracledb.DatabaseError as e:
    logger.error(f"❌ Erreur DB: {e}")
    raise HTTPException(status_code=500, detail="Erreur base de données")
except Exception as e:
    logger.error(f"❌ Erreur: {e}")
    raise HTTPException(status_code=500, detail=str(e))
```

---


