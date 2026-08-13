# 📱 AppMobileGMAO - SENELEC

[![Flutter](https://img.shields.io/badge/Flutter-3.29.2-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![Angular](https://img.shields.io/badge/Angular-20-red?logo=angular)](https://angular.io)
[![Oracle](https://img.shields.io/badge/Oracle-Database-red?logo=oracle)](https://www.oracle.com/database/)
[![Status](https://img.shields.io/badge/Status-80%25%20Opérationnel-brightgreen)](/)

**Application mobile et web de Gestion de Maintenance Assistée par Ordinateur (GMAO) pour SENELEC**

---

## 🎯 Vue d'Ensemble

Ce projet est une solution complète de GMAO permettant aux techniciens de terrain et aux administrateurs de gérer:
- 📦 **26,789+ équipements** (transformateurs, postes, disjoncteurs...)
- 🔧 **Ordres de travail (OT)** (maintenance préventive et corrective)
- 📊 **Statistiques et rapports** (web uniquement)
- 🔔 **Notifications temps réel** (WebSocket)
- 👥 **Gestion utilisateurs** (authentification LDAP)

---

## 📚 DOCUMENTATION COMPLÈTE

### 📖 Documents Principaux (Créés le 28/11/2025)

| Document | Description | Audience |
|----------|-------------|----------|
| [**RESUME_EXECUTIF.md**](RESUME_EXECUTIF.md) | Vue d'ensemble visuelle, statuts, plan d'action | 👔 Management, PM |
| [**REVUE_PROJET_ET_INTEGRATION_OT_API.md**](REVUE_PROJET_ET_INTEGRATION_OT_API.md) | Architecture détaillée, API endpoints, plan intégration | 👨‍💻 Développeurs |
| [**PLAN_INTEGRATION_OT_API.md**](PLAN_INTEGRATION_OT_API.md) | Checklist, code backend/frontend, tests | 👨‍💻 Dev, QA |
| [**TESTS_API_OT_RESULTATS.md**](TESTS_API_OT_RESULTATS.md) | Tests connectivité API OT, découvertes, bloqueurs | 👨‍💻 Dev, DevOps |

### 📂 Documentation Technique

- [Backend README](backend/README.md) - API FastAPI, Oracle, Redis
- [Frontend Mobile README](frontend_mobile/README.md) - Flutter, Hive, Provider
- [Swagger API](https://domtec.senelec.sn:9099/docs) - Documentation interactive

---

## 🏗️ Architecture

```
┌───────────────────────────────────────────────────────────┐
│               📱 Mobile (Flutter)                         │
│                                                           │
│  • Login & Auth JWT                    ✅ 100%           │
│  • 26,789 Équipements                  ✅ 100%           │
│  • Navigation (4 tabs)                 ✅ 100%           │
│  • OT UI (mock data)                   🟡 60%            │
│  • Cache Hive offline                  ✅ 100%           │
└───────────────────────────────────────────────────────────┘
                         ↓ HTTPS
┌───────────────────────────────────────────────────────────┐
│         ⚙️ Backend FastAPI (Python 3.8+)                  │
│         https://domtec.senelec.sn:9099                    │
│                                                           │
│  • /api/v1/auth         Authentification ✅               │
│  • /api/v1/mobile       Endpoints mobile ✅               │
│  • /api/v1/web          Endpoints web    ✅               │
│  • /ws/notifications    WebSocket        ✅               │
│  • Cache Redis                           ✅               │
└───────────────────────────────────────────────────────────┘
         ↓ SQL                              ↓ HTTP (à faire)
┌──────────────────────┐      ┌────────────────────────────┐
│  🗄️ Oracle COSWIN    │      │  🔧 API OT (Siveco)        │
│                      │      │  http://10.101.1.102:8083  │
│  • Équipements       │      │  /ws/rest/workorders       │
│  • Utilisateurs      │      │  ⚠️ Auth requise            │
│  • Entités           │      └────────────────────────────┘
│  • Zones, Familles   │
└──────────────────────┘
                         ↓ HTTP
┌───────────────────────────────────────────────────────────┐
│            🌐 Web (Angular 20)                            │
│                                                           │
│  • Admin & Statistiques                ✅ 100%           │
│  • PrimeNG + TailwindCSS               ✅ 100%           │
└───────────────────────────────────────────────────────────┘
```

---

## 🚀 Démarrage Rapide

### Prérequis

- **Backend**: Python 3.8+, Oracle client, Redis
- **Mobile**: Flutter 3.29.2+, Android SDK
- **Web**: Node.js 18+, Angular CLI

### Installation

#### 1. Backend

```bash
cd backend

# Environnement virtuel
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows
source venv/bin/activate      # Linux/Mac

# Dépendances
pip install -r requirements.txt

# Configuration
cp .env.example .env
# Éditer .env avec vos credentials Oracle, Redis

# Démarrage
uvicorn app.main:app --reload --port 9099
```

**Tester**: http://localhost:9099/docs

#### 2. Frontend Mobile

```bash
cd frontend_mobile

# Dépendances
flutter pub get

# Lancer émulateur ou connecter device
flutter devices

# Démarrer app
flutter run -d DEVICE_ID
```

#### 3. Frontend Web

```bash
cd frontend_web

# Dépendances
npm install
# ou
pnpm install

# Démarrage
ng serve
```

**Tester**: http://localhost:4200

---

## 📊 État du Projet

### Modules Opérationnels ✅

| Module | Backend | Mobile | Web | BDD | Status |
|--------|---------|--------|-----|-----|--------|
| Authentification | ✅ | ✅ | ✅ | ✅ | 100% |
| Équipements | ✅ | ✅ | ✅ | ✅ | 100% |
| Entités | ✅ | ✅ | ✅ | ✅ | 100% |
| Zones | ✅ | ✅ | ✅ | ✅ | 100% |
| Familles | ✅ | ✅ | ✅ | ✅ | 100% |
| WebSocket | ✅ | ✅ | ✅ | - | 100% |

### En Cours 🟡

| Module | Backend | Mobile | Web | BDD | Status | Bloqueur |
|--------|---------|--------|-----|-----|--------|----------|
| OT (Ordres Travail) | 🔴 | 🟡 | 🔴 | 🔴 | 60% | Auth API OT |

**OT Mobile**: UI complète ✅ | Navigation OK ✅ | Données mock ⚠️

---

## ⚠️ BLOQUEUR ACTUEL : API OT

### Situation

L'intégration de l'API OT externe est **bloquée** par manque de credentials d'authentification.

**API OT**: `http://10.101.1.102:8083/ws/rest/workorders`

**Tests effectués** (28/11/2025):
- ✅ Serveur accessible (WildFly, Siveco Group)
- ✅ Path REST identifié: `/ws/rest/`
- 🔴 Authentification requise (401 Unauthorized)

### Action Requise

**Contacter l'administrateur API OT** pour obtenir:
1. Type d'authentification (Basic Auth ? Bearer Token ?)
2. Credentials (username/password ou token)
3. Documentation complète (Swagger, exemples)

**Voir**: [TESTS_API_OT_RESULTATS.md](TESTS_API_OT_RESULTATS.md)

### Plan d'Intégration (Prêt)

Une fois credentials obtenus, suivre:
- [PLAN_INTEGRATION_OT_API.md](PLAN_INTEGRATION_OT_API.md)

**Estimation**: 8-11 heures de développement

---

## 📱 Fonctionnalités Mobile

### ✅ Opérationnelles

- **Authentification**
  - Login LDAP
  - JWT tokens (access + refresh)
  - Déconnexion

- **Équipements** (26,789 items)
  - Liste paginée avec infinite scroll
  - Filtres: Entité, Zone, Famille
  - Recherche textuelle
  - Détails complets
  - Cache local (Hive)
  - Mode offline/online

- **Navigation**
  - 4 tabs: Home, Équipements, OT, DI
  - Bottom navigation bar
  - Responsive design

- **Notifications**
  - WebSocket temps réel
  - Overlay notifications

### 🟡 En Cours

- **Ordres de Travail (OT)**
  - ✅ UI complète (3 screens)
  - ✅ Navigation: List → Info → Details
  - ✅ Formulaires
  - ⚠️ Données mock (5 OT fictifs)
  - 🔴 API réelle (bloqué auth)

---

## 🌐 Fonctionnalités Web

### ✅ Opérationnelles

- Dashboard statistiques
- Gestion utilisateurs
- Rapports équipements
- Interface admin PrimeNG

---

## 🔐 Sécurité

### Implémenté ✅

- JWT Authentication (access + refresh tokens)
- HTTPS en production
- CORS configuré
- SQL paramétré (anti-injection)
- Logs sanitisés
- Variables environnement (.env)

### Recommandations 🔒

- [ ] Chiffrement Hive database mobile
- [ ] Certificate pinning mobile app
- [ ] Rate limiting API
- [ ] API OT via backend proxy (pas direct mobile)

---

## 🧪 Tests

### Backend

```bash
cd backend
pytest tests/ -v
```

### Mobile

```bash
cd frontend_mobile
flutter test
```

### Web

```bash
cd frontend_web
ng test
```

---

## 📈 Statistiques

```
Projet: 80% Complet
│
├─ Backend FastAPI          100% ✅
├─ Base Oracle              100% ✅
├─ Frontend Mobile UI       100% ✅
├─ Frontend Web             100% ✅
├─ Module Équipements       100% ✅
├─ Authentification         100% ✅
├─ WebSocket                100% ✅
└─ Module OT                 60% 🟡 (bloqué API)

Total Données:
├─ 26,789 équipements
├─ ~50 entités
├─ ~100 zones
├─ ~20 familles
└─ ~200 centres de charge
```

---

## 🛠️ Technologies

### Backend
- **Framework**: FastAPI 0.104+
- **Langage**: Python 3.8+
- **BDD**: Oracle Database (cx_Oracle)
- **Cache**: Redis
- **Validation**: Pydantic
- **Server**: uvicorn (ASGI)

### Mobile
- **Framework**: Flutter 3.29.2
- **Langage**: Dart 3.7.2
- **State**: Provider
- **HTTP**: Dio 5.4.0
- **Storage**: Hive 2.2.3
- **WebSocket**: web_socket_channel

### Web
- **Framework**: Angular 20
- **Langage**: TypeScript
- **UI**: PrimeNG 20 + TailwindCSS 4
- **HTTP**: RxJS 7.8.2

---

## 📞 Support

### Documentation
- 📖 [RESUME_EXECUTIF.md](RESUME_EXECUTIF.md) - Vue d'ensemble
- 🔧 [PLAN_INTEGRATION_OT_API.md](PLAN_INTEGRATION_OT_API.md) - Plan OT
- 🧪 [TESTS_API_OT_RESULTATS.md](TESTS_API_OT_RESULTATS.md) - Tests API

### Liens Utiles
- **Swagger Backend**: https://domtec.senelec.sn:9099/docs
- **Health Check**: https://domtec.senelec.sn:9099/health
- **API OT**: http://10.101.1.102:8083/ (auth requise)

### Environnements

**Production**:
- Backend: `https://domtec.senelec.sn:9099`
- Oracle: COSWIN (production)

**Développement**:
- Backend: `http://10.101.2.46:9099`
- Device: Samsung S23 Ultra (RFCW41GDR0W)

---

## 📋 Checklist Prochaines Étapes

### Priorité Haute 🔴

- [ ] **Obtenir credentials API OT** (BLOQUANT)
- [ ] Tester authentification API OT
- [ ] Documenter structure JSON réponses
- [ ] Implémenter backend proxy OT
- [ ] Adapter WorkOrder model mobile

### Priorité Moyenne 🟡

- [ ] Intégrer frontend mobile avec API OT
- [ ] Tests end-to-end module OT
- [ ] Validation utilisateurs OT
- [ ] Optimiser cache OT

### Priorité Basse 🟢

- [ ] Améliorer logs monitoring
- [ ] Documentation utilisateur finale
- [ ] Tests performance charge
- [ ] CI/CD pipeline

---

## 🎯 Objectifs Court Terme

### Cette Semaine
- Débloquer API OT (credentials)
- Implémenter backend service OT
- Adapter frontend mobile OT

### Semaine Prochaine
- Tests complets module OT
- Validation utilisateurs
- Déploiement production OT

---

## 📄 Licence

**Propriété SENELEC** - Usage interne uniquement

---

## 👥 Équipe

- **Backend**: Équipe Dev SENELEC
- **Mobile**: Équipe Flutter
- **Web**: Équipe Angular
- **BDD**: Équipe Oracle DBA
- **API OT**: Siveco Group (externe)

---

## 📅 Historique

### 28 Novembre 2025
- ✅ Module Équipements opérationnel (26,789 items)
- ✅ Navigation mobile corrigée
- ✅ UI OT complète (mock data)
- 🔴 API OT bloquée (credentials manquants)
- 📚 Documentation complète créée (4 fichiers)

### Versions
- **Backend**: 1.0.0
- **Mobile**: 1.0.0+1
- **Web**: 20.0.0

---

## 🚀 Getting Started (Nouveau Dev)

1. **Lire** [RESUME_EXECUTIF.md](RESUME_EXECUTIF.md) pour comprendre le projet
2. **Consulter** [REVUE_PROJET_ET_INTEGRATION_OT_API.md](REVUE_PROJET_ET_INTEGRATION_OT_API.md) pour l'architecture
3. **Cloner** le repository et suivre "Installation" ci-dessus
4. **Tester** les modules fonctionnels (Équipements)
5. **Contribuer** au module OT une fois API débloquée

---

**Dernière mise à jour**: 28 Novembre 2025  
**Statut**: 🟢 80% Opérationnel | 🔴 20% Bloqué API OT  
**Contact**: Équipe Dev SENELEC

---

**README.md** | [RESUME_EXECUTIF.md](RESUME_EXECUTIF.md) | [REVUE_PROJET](REVUE_PROJET_ET_INTEGRATION_OT_API.md) | [PLAN_OT](PLAN_INTEGRATION_OT_API.md) | [TESTS_API](TESTS_API_OT_RESULTATS.md)
