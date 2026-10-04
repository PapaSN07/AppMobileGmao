import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/screens/pending_sync_screen.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/connectivity_service.dart';
import 'package:appmobilegmao/services/ot_sync_service.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'dart:async';
import 'package:appmobilegmao/screens/equipments/history_equipment_screen.dart';
import 'package:appmobilegmao/utils/string_utils.dart';
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
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Saisies faites sans réseau : envoyées à l'ouverture et à chaque retour du réseau
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendPending());
    _reconnection = ConnectivityService().onReconnected(_onNetworkBack);
  }

  /// Retour du réseau : session ouverte hors ligne → on la rouvre en ligne (le serveur des
  /// équipements exige un jeton, que la connexion hors ligne ne donne pas), puis on envoie.
  Future<void> _onNetworkBack() async {
    if (!mounted) return;
    if (context.read<AuthProvider>().isOfflineSession) await _reconnectOnline();
    await _sendPending();
  }

  bool _askingPassword = false;

  Future<void> _reconnectOnline() async {
    if (_askingPassword) return;
    _askingPassword = true;
    try {
      final auth = context.read<AuthProvider>();
      final username = auth.currentUser?.username ?? '';
      final password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ReconnectDialog(),
      );
      if (password == null || username.isEmpty || !mounted) return;

      final ok = await auth.login(username, password);
      if (!mounted) return;
      final online = ok && !auth.isOfflineSession;
      if (online) context.read<EquipmentProvider>().fetchEquipments(forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(online
            ? 'Session en ligne rétablie : données à jour.'
            : auth.lastLoginError ?? 'Reconnexion impossible pour le moment.'),
      ));
    } finally {
      _askingPassword = false;
    }
  }

  late final StreamSubscription<bool> _reconnection;

  @override
  void dispose() {
    _reconnection.cancel();
    super.dispose();
  }

  Future<void> _sendPending() async {
    if (!mounted) return;
    final report = await context.read<OtSyncService>().syncNow();
    if (!mounted || report.sent == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saisies hors ligne : ${report.summary}'),
        action: report.blocked > 0 ? SnackBarAction(label: 'Voir', onPressed: _openPendingSync) : null,
      ),
    );
  }

  void _openPendingSync() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingSyncScreen()));
  }

  /// Icône des envois en attente (visible seulement s'il en reste).
  Widget _pendingSyncButton(Color color) {
    return ValueListenableBuilder<List<PendingOtAction>>(
      valueListenable: PendingOtQueue.actions,
      builder: (context, actions, _) {
        final username = HiveService.getCurrentUser()?.username;
        final mine = actions.where((a) => a.username == username).toList();
        if (mine.isEmpty) return const SizedBox.shrink();
        final blocked = mine.any((a) => a.status != PendingStatus.pending);
        return IconButton(
          tooltip: 'Envois en attente',
          onPressed: _openPendingSync,
          icon: Badge(
            label: Text('${mine.length}'),
            backgroundColor: blocked ? Colors.red.shade700 : Colors.orange.shade800,
            child: Icon(Icons.cloud_upload_outlined, color: color),
          ),
        );
      },
    );
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
      HomeScreen(onOpenTab: _onTabTapped),
      const EquipmentScreen(),
      const OtScreen(), // HomeScreen.otTabIndex
      const DiScreen(), // HomeScreen.diTabIndex
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
    return Colors.white;
  }

  // Obtenir la couleur du texte selon la page
  Color _getAppBarTextColor() {
    return AppTheme.senelecIndigo;
  }

  /// Prévient l'agent que ses saisies hors ligne partiront à sa prochaine connexion.
  String _logoutMessage() {
    final username = HiveService.getCurrentUser()?.username;
    final count = PendingOtQueue.all().where((a) => a.username == username).length;
    if (count == 0) return 'Êtes-vous sûr de vouloir vous déconnecter ?';
    return '$count saisie${count > 1 ? 's' : ''} pas encore envoyée${count > 1 ? 's' : ''} à Coswin '
        '(faite${count > 1 ? 's' : ''} sans réseau). Elle${count > 1 ? 's' : ''} partira à votre '
        'prochaine connexion sur ce téléphone.\n\nSe déconnecter quand même ?';
  }

  void _openProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    // ✅ UTILISATION: Parser le username avec la méthode utilitaire
    final userInfo = StringUtils.parseUserName(user?.username);
    if (user != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => ProfilMenu(
                nom: userInfo['nom']!,
                prenom: userInfo['prenom']!,
                email: user.email,
                role: user.subtitleInfo,
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
    final isHome = authProvider.isPrestataire ? false : _currentIndex == 0;

    // Onglet Équipements (le premier onglet pour un prestataire) : bouton d'ajout
    final shouldShowAddButton = authProvider.isPrestataire ? _currentIndex == 0 : _currentIndex == 1;

    if (shouldShowAddButton) {
      // Page Equipment - Bouton +
      return IconButton(
        padding: EdgeInsets.zero, // ✅ Supprime le padding interne
        icon: Container(
          padding: spacing.custom(all: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
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
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: spacing.custom(all: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
            _logoutMessage(),
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
        final pages = _pages;
        final effectiveIndex = _currentIndex.clamp(0, pages.length - 1);
        final appBarBgColor = _getAppBarBackgroundColor();
        final textColor = _getAppBarTextColor();
        final isHome = authProvider.isPrestataire ? false : effectiveIndex == 0;

        return Scaffold(
          key: _scaffoldKey,
          // ✅ MODIFIÉ: Augmenter la hauteur de l'AppBar
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              responsive.spacing(70),
            ), // ✅ Hauteur augmentée: 56 → 70
            child: AppBar(
              titleSpacing: 0,
              title: Padding(
                padding: spacing.custom(
                  left: 4,
                  right: 16,
                ), // ✅ AJOUTÉ: Espacement à gauche
                child: Text(
                  _getPageTitle(effectiveIndex),
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: responsive.sp(18),
                  ),
                ),
              ),
              backgroundColor: appBarBgColor,
              elevation: isHome ? 0.5 : 0,
              leading: Padding(
                padding: spacing.custom(
                  left: 12,
                  right: 4,
                ), // ✅ MODIFIÉ: Espacement augmenté (12→16, 4→8)
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Container(
                    padding: spacing.custom(all: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                    ),
                    child: Icon(
                      Icons.menu,
                      color: textColor,
                      size: responsive.iconSize(20),
                    ),
                  ),
                  onPressed: _openProfile,
                  tooltip: 'Profil utilisateur',
                ),
              ),
              actions: [
                _pendingSyncButton(textColor),
                Padding(
                  padding: spacing.custom(
                    right: 16,
                  ), // ✅ Espacement à droite maintenu
                  child: _getRightButton(),
                ),
              ],
            ),
          ),
          body: IndexedStack(index: effectiveIndex, children: pages),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: effectiveIndex,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }
}

/// Mot de passe demandé au retour du réseau après une connexion hors ligne.
class _ReconnectDialog extends StatefulWidget {
  const _ReconnectDialog();

  @override
  State<_ReconnectDialog> createState() => _ReconnectDialogState();
}

class _ReconnectDialogState extends State<_ReconnectDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isNotEmpty) Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Le réseau est revenu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vous êtes connecté hors ligne. Entrez votre mot de passe pour mettre à jour '
            'les équipements et envoyer vos ajouts.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
        TextButton(onPressed: _submit, child: const Text('Se reconnecter')),
      ],
    );
  }
}
