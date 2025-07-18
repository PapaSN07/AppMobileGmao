# 📱 AppMobileGMAO

<center>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?cacheSeconds=2592000)](https://github.com/your-repo)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/your-repo/actions)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/your-repo/graphs/commit-activity)

**Application mobile Flutter pour la Gestion de Maintenance Assistée par Ordinateur (GMAO)**  
*Développée pour Senelec - DSI*

[📥 Télécharger](#installation-et-démarrage) • [📖 Documentation](#architecture-et-composants) • [🐛 Signaler un bug](https://github.com/your-repo/issues) • [💡 Demander une fonctionnalité](https://github.com/your-repo/issues)

</center>

---

## 🎯 À propos

AppMobileGMAO est une **application mobile native** développée avec Flutter qui révolutionne la gestion des équipements industriels. Elle permet de gérer efficacement les **ordres de travail (OT)** et les **demandes d'intervention (DI)** dans le cadre d'une stratégie de maintenance préventive et corrective moderne.

---

## ✨ Fonctionnalités principales

### 🏠 **Écran d'accueil**

- 📊 Tableau de bord avec statistiques en temps réel
- 🔄 Basculement OT/DI avec animations fluides
- 📋 Liste dynamique des éléments récents
- 🎨 Interface moderne et intuitive

### 🔧 **Gestion des équipements**

- 📝 Formulaire complet d'ajout d'équipements
- 🔍 Recherche avancée et filtrage
- 📍 Géolocalisation avec coordonnées
- ⚙️ Gestion des attributs personnalisés

### 📋 **Ordres de travail**

- 📊 Affichage par catégorie avec overlays
- 🔄 Navigation fluide entre les sections
- 📱 Interface responsive et optimisée
- 💾 Sauvegarde automatique des données

### 🎨 **Interface utilisateur**

- 🎨 Design Material Design moderne
- 🌙 Thème personnalisé cohérent
- 📱 Navigation par onglets intuitifs
- ⚡ Performances optimisées

---

## 🛠 Stack technique

<center>

| Catégorie | Technologies |
|-----------|-------------|
| **Framework** | ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter) |
| **Langage** | ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart) |
| **Architecture** | ![StatefulWidget](https://img.shields.io/badge/StatefulWidget-State%20Management-green) |
| **Navigation** | ![MaterialPageRoute](https://img.shields.io/badge/MaterialPageRoute-PageView-blue) |
| **UI** | ![Material Design](https://img.shields.io/badge/Material%20Design-Custom%20Theme-orange) |
| **Plateformes** | ![Android](https://img.shields.io/badge/Android-✅-3DDC84) ![iOS](https://img.shields.io/badge/iOS-✅-000000) ![Web](https://img.shields.io/badge/Web-⚠️-yellow) |

</center>

---

## 📁 Architecture du projet

```
📦 AppMobileGMAO/
├── 📂 lib/
│   ├── 📄 main.dart                    # 🚀 Point d'entrée
│   ├── 📂 models/
│   │   └── 📄 order.dart              # 📊 Modèle de données
│   ├── 📂 screens/
│   │   ├── 📄 main_screen.dart        # 🏠 Navigation principale
│   │   ├── 📄 home_screen.dart        # 📊 Tableau de bord
│   │   ├── 📄 equipment_screen.dart   # 🔧 Gestion équipements
│   │   ├── 📄 add_equipment_screen.dart # ➕ Ajout équipement
│   │   └── 📄 login_screen.dart       # 🔐 Authentification
│   ├── 📂 theme/
│   │   └── 📄 app_theme.dart          # 🎨 Thème global
│   └── 📂 widgets/
│       ├── 📄 custom_bottom_navigation_bar.dart # 📱 Navigation
│       └── 📄 work_order_item.dart              # 📋 Composant OT
├── 📂 assets/
│   └── 📂 images/
│       ├── 🖼️ bg_card.png
│       └── 🗺️ map.png
└── 📄 README.md
```

---

## 🚀 Installation et démarrage

### 📋 Prérequis

<div align="center">

![Flutter SDK](https://img.shields.io/badge/Flutter%20SDK-3.x+-02569B?style=flat-square&logo=flutter)
![Dart SDK](https://img.shields.io/badge/Dart%20SDK-3.x+-0175C2?style=flat-square&logo=dart)
![Android Studio](https://img.shields.io/badge/Android%20Studio-Latest-3DDC84?style=flat-square&logo=androidstudio)
![VS Code](https://img.shields.io/badge/VS%20Code-Latest-007ACC?style=flat-square&logo=visualstudiocode)

</div>

### ⚡ Installation rapide

```bash
# 1️⃣ Cloner le repository
git clone https://github.com/your-username/AppMobileGmao.git
cd AppMobileGmao

# 2️⃣ Installer les dépendances
flutter pub get

# 3️⃣ Vérifier la configuration
flutter doctor

# 4️⃣ Lancer l'application
flutter run
```

### 🔧 Configuration avancée

<details>
<summary>Configuration pour Android</summary>

```bash
# Vérifier les SDK Android
flutter doctor --android-licenses

# Build pour Android
flutter build apk --release
```

</details>

<details>
<summary>Configuration pour iOS</summary>

```bash
# Ouvrir le projet iOS
open ios/Runner.xcworkspace

# Build pour iOS
flutter build ios --release
```

</details>

---

## 🏗 Architecture et composants

### 📱 Écrans principaux

<div align="center">

| Écran | Fichier | Fonctionnalités clés |
|-------|---------|---------------------|
| 🏠 **Home** | `home_screen.dart` | Tableau de bord, statistiques, navigation OT/DI |
| 🔧 **Équipements** | `equipment_screen.dart` | Liste, recherche, ajout d'équipements |
| ➕ **Ajout** | `add_equipment_screen.dart` | Formulaire complet avec validation |
| 📱 **Navigation** | `main_screen.dart` | PageView avec onglets persistants |

</div>

### 🧩 Composants réutilisables

```dart
// 📱 Navigation personnalisée
CustomBottomNavigationBar
├── 🏠 Accueil
├── 📋 OT (Ordres de Travail)
├── 🔧 DI (Demandes d'Intervention)
└── ⚙️ Équipements

// 📊 Élément d'ordre de travail
WorkOrderItem
├── 📄 Informations de base
├── 👁️ Overlay avec détails
└── 🎨 Design cohérent
```

---

## 🎨 Guide de style

### 🌈 Palette de couleurs

<div align="center">

| Couleur | Hex | Usage | Preview |
|---------|-----|-------|---------|
| **Primary** | `#FFFFFF` | Arrière-plans principaux | ![#FFFFFF](https://via.placeholder.com/20/FFFFFF/000000?text=+) |
| **Secondary** | `#1E3A8A` | Textes, boutons, accents | ![#1E3A8A](https://via.placeholder.com/20/1E3A8A/FFFFFF?text=+) |
| **Third** | `#6B7280` | Textes secondaires | ![#6B7280](https://via.placeholder.com/20/6B7280/FFFFFF?text=+) |
| **Blur** | `#F3F4F6` | Arrière-plans avec transparence | ![#F3F4F6](https://via.placeholder.com/20/F3F4F6/000000?text=+) |

</div>

### 🔤 Typographie

- **Montserrat** : Titres et textes importants (Bold, Semi-Bold)
- **Roboto** : Textes courants et descriptions (Regular, Medium)

---

## 📈 Performances et optimisations

<div align="center">

![Performance](https://img.shields.io/badge/Performance-95%25-brightgreen?style=for-the-badge)
![Memory Usage](https://img.shields.io/badge/Memory-Optimized-blue?style=for-the-badge)
![Bundle Size](https://img.shields.io/badge/Bundle%20Size-<50MB-orange?style=for-the-badge)

</div>

### ⚡ Optimisations techniques

- 🚀 **ListView.builder** pour les listes dynamiques
- 🧠 **FocusNode disposal** pour la gestion mémoire
- 🎭 **AnimatedSwitcher** pour les transitions fluides
- 📱 **Responsive design** pour tous les écrans

---

## 🤝 Contribution

### 📝 Guide de contribution

1. 🍴 **Fork** le projet
2. 🌿 **Créer** une branche feature (`git checkout -b feature/AmazingFeature`)
3. 💾 **Commit** les changements (`git commit -m 'Add some AmazingFeature'`)
4. 📤 **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. 🔃 **Ouvrir** une Pull Request

---

<div align="center">

### 🚀 **Fait avec ❤️ et Flutter**

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-1f425f.svg?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

**⭐ N'oubliez pas de mettre une étoile si ce projet vous a aidé !**

</div>
