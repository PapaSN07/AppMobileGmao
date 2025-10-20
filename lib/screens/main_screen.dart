import 'package:appmobilegmao/screens/equipments/history_equipment_screen.dart';
import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/screens/home_screen.dart';
import 'package:appmobilegmao/screens/ot/ot_screen.dart';
import 'package:appmobilegmao/screens/di/di_screen.dart';
import 'package:appmobilegmao/screens/equipments/equipment_screen.dart';
import 'package:appmobilegmao/screens/equipments/add_equipment_screen.dart';
import 'package:appmobilegmao/screens/settings/menu_screen.dart';
import 'package:appmobilegmao/screens/auth/login_screen.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  // Retirer _pages initialisé dans initState, au lieu de ça : getter dynamique
  List<Widget> get _pages {
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    if (role == 'PRESTATAIRE') {
      return [
        const EquipmentScreen(), // index 0
        const HistoryEquipmentScreen(), // index 1
      ];
    }
    // rôle normal : pages complètes
    return [
      const HomeScreen(),
      const EquipmentScreen(),
      const OtScreen(),
      const DiScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getPageTitle(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isPrestataire) {
      // ✅ PRESTATAIRE : 2 onglets
      switch (index) {
        case 0:
          return 'Équipements';
        case 1:
          return 'Historiques';
        default:
          return 'GMAO';
      }
    }

    // ✅ LDAP : 4 onglets
    switch (index) {
      case 0:
        return 'Accueil';
      case 1:
        return 'Équipements';
      case 2:
        return 'Ordres de Travail';
      case 3:
        return 'Demandes d\'Intervention';
      default:
        return 'GMAO';
    }
  }

  // Obtenir la couleur de l'AppBar selon la page
  Color _getAppBarBackgroundColor() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isPrestataire) {
      // ✅ PRESTATAIRE : toujours couleur secondaire (bleu)
      return AppTheme.secondaryColor;
    }

    // ✅ LDAP : couleurs selon page
    switch (_currentIndex) {
      case 0: // Home
        return AppTheme.primaryColor;
      case 1: // Equipment
      case 2: // OT
      case 3: // DI
      default:
        return AppTheme.secondaryColor;
    }
  }

  // Obtenir la couleur du texte selon la page
  Color _getAppBarTextColor() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isPrestataire) {
      // ✅ PRESTATAIRE : toujours texte blanc
      return Colors.white;
    }

    // ✅ LDAP : couleurs selon page
    switch (_currentIndex) {
      case 0: // Home
        return AppTheme.secondaryColor;
      case 1: // Equipment
      case 2: // OT
      case 3: // DI
      default:
        return Colors.white;
    }
  }

  void _openProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => ProfilMenu(
                nom: user.username.split('.').last,
                prenom: user.username.split('.').first,
                email: user.email,
                role:
                    (user.group?.trim().isNotEmpty == true)
                        ? user.group!.trim()
                        : (user.role?.trim().isNotEmpty == true)
                        ? user.role!.trim()
                        : 'Utilisateur',
                onLogout: _handleLogout,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  // ✅ NOUVELLE MÉTHODE: Action conditionnelle pour le bouton de droite
  void _handleRightButtonAction() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isPrestataire) {
      if (_currentIndex == 0) {
        // Equipment pour Prestataire
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEquipmentScreen()),
        );
      }
    } else {
      if (_currentIndex == 1) {
        // Equipment pour LDAP
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEquipmentScreen()),
        );
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE: Obtenir l'icône du bouton de droite
  Widget _getRightButton() {
    final responsive = context.responsive;
    final spacing = context.spacing;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final user = authProvider.currentUser;
    final textColor = _getAppBarTextColor();

    // ✅ CORRECTION: isHome doit être false pour Prestataire sur page Equipment
    final isHome = authProvider.isPrestataire ? false : _currentIndex == 0;

    // ✅ CORRECTION: Logique basée sur le rôle et l'index
    bool shouldShowAddButton = false;
    if (authProvider.isPrestataire) {
      shouldShowAddButton = _currentIndex == 0; // Equipment pour Prestataire
    } else {
      shouldShowAddButton = _currentIndex == 1; // Equipment pour LDAP
    }

    if (shouldShowAddButton) {
      // Page Equipment - Bouton +
      return IconButton(
        icon: Container(
          padding: spacing.custom(all: 8),
          decoration: BoxDecoration(
            color:
                AppTheme
                    .primaryColor20, // ✅ TOUJOURS primaryColor20 pour Equipment
            borderRadius: BorderRadius.circular(responsive.spacing(8)),
          ),
          child: Icon(
            Icons.add,
            color: textColor,
            size: responsive.iconSize(20),
          ),
        ),
        onPressed: _handleRightButtonAction,
        tooltip: 'Ajouter un équipement',
      );
    } else {
      // Autres pages - Affichage des infos utilisateur
      if (user != null) {
        return Padding(
          padding: spacing.custom(right: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: spacing.custom(all: 8),
                  decoration: BoxDecoration(
                    color:
                        isHome
                            ? AppTheme.secondaryColor10
                            : AppTheme.primaryColor20,
                    borderRadius: BorderRadius.circular(responsive.spacing(20)),
                  ),
                  child: Text(
                    user.username
                        .split('.')
                        .map((part) => part[0].toUpperCase())
                        .join(''),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.sp(14),
                    ),
                  ),
                ),
                SizedBox(width: spacing.small),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: TextStyle(
                        color: textColor,
                        fontSize: responsive.sp(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      (user.group?.trim().isNotEmpty == true)
                          ? user.group!.trim()
                          : (user.role?.trim().isNotEmpty == true)
                          ? user.role!.trim()
                          : 'Utilisateur',
                      style: TextStyle(
                        color:
                            isHome
                                ? textColor.withValues(alpha: 0.7)
                                : textColor.withValues(alpha: 0.8),
                        fontSize: responsive.sp(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleLogout() async {
    final responsive = context.responsive;
    final spacing = context.spacing;

    // Afficher dialog de confirmation
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive.spacing(16),
            ), // ✅ Border radius responsive
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.secondaryColor,
                size: responsive.iconSize(28),
              ), // ✅ Icône responsive
              SizedBox(width: spacing.medium), // ✅ Espacement responsive
              Text(
                'Déconnexion',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w500,
                  fontSize: responsive.sp(24), // ✅ Texte responsive
                  color: AppTheme.secondaryColor, // ✅ Couleur du titre
                ),
              ),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: responsive.sp(16)), // ✅ Texte responsive
          ),
          actions: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween, // ✅ Aligne les boutons à droite
              children: [
                SecondaryButton(
                  text: 'Annuler',
                  onPressed: () => Navigator.of(context).pop(false),
                  width: responsive.spacing(100), // ✅ Largeur responsive
                  height: responsive.spacing(42), // ✅ Hauteur responsive
                ),
                // const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ), // ✅ Border radius responsive
                    ),
                  ),
                  child: const Text(
                    'Déconnecter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: spacing.allPadding, // ✅ Padding responsive
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    responsive.spacing(12),
                  ), // ✅ Border radius responsive
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryColor,
                      ),
                    ),
                    SizedBox(height: spacing.medium), // ✅ Espacement responsive
                    Text(
                      'Déconnexion en cours...',
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                      ), // ✅ Texte responsive
                    ),
                  ],
                ),
              ),
            ),
      );

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de chargement

          // Naviguer vers l'écran de connexion et supprimer toute la pile
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de chargement

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  responsive.spacing(8),
                ), // ✅ Border radius responsive
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final appBarBgColor = _getAppBarBackgroundColor();
        final textColor = _getAppBarTextColor();
        // ✅ CORRECTION: isHome doit être false pour Prestataire sur page Equipment
        final isHome = authProvider.isPrestataire ? false : _currentIndex == 0;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              _getPageTitle(_currentIndex),
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: textColor, // ✅ CHANGÉ: Couleur conditionnelle
                fontSize: responsive.sp(20), // ✅ Texte responsive
              ),
            ),
            backgroundColor: appBarBgColor, // ✅ CHANGÉ: Couleur conditionnelle
            elevation:
                isHome ? 0.5 : 0, // ✅ AJOUTÉ: Légère ombre pour l'accueil
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: Container(
                      padding: spacing.custom(all: 8), // ✅ Padding responsive
                      decoration: BoxDecoration(
                        color:
                            isHome
                                ? AppTheme.secondaryColor10
                                : AppTheme.primaryColor20,
                        borderRadius: BorderRadius.circular(
                          responsive.spacing(8),
                        ), // ✅ Border radius responsive
                      ),
                      child: Icon(
                        Icons.menu,
                        color: textColor, // ✅ CHANGÉ: Couleur conditionnelle
                        size: responsive.iconSize(20), // ✅ Icône responsive
                      ),
                    ),
                    onPressed: _openProfile,
                    tooltip: 'Profil utilisateur',
                  ),
            ),
            actions: [_getRightButton()], // ✅ CHANGÉ: Action conditionnelle
          ),
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }
}
