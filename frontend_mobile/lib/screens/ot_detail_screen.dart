import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';
import 'package:appmobilegmao/screens/fichier_lie_screen.dart';
import 'package:appmobilegmao/screens/main_screen.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'ot_tabs/ot_details_tab.dart';
import 'ot_tabs/ot_mode_operatoire_tab.dart';
import 'ot_tabs/ot_commentaires_tab.dart';
import 'ot_tabs/ot_mains_oeuvre_tab.dart';
import 'ot_tabs/ot_materiel_tab.dart';
import 'ot_tabs/ot_sous_attributs_tab.dart';


/// Écran qui affiche les détails d'un Ordre de Travail (OT) avec des onglets
/// Principe SOLID: Single Responsibility - Cet écran gère l'affichage des détails OT avec navigation par onglets
class OTDetailScreen extends StatefulWidget {
  // L'ordre de travail dont on veut afficher les détails
  final Order order;

  const OTDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OTDetailScreen> createState() => _OTDetailScreenState();
}

class _OTDetailScreenState extends State<OTDetailScreen>
    with SingleTickerProviderStateMixin {
  // Contrôleur pour gérer les onglets (TabBar et TabBarView)
  late TabController _tabController;
  late final OTService _otService;

  // Index de l'onglet actuellement sélectionné (0 = Détails, 1 = Mode Opératoire, etc.)
  int _currentTabIndex = 0;

  // Index pour la barre de navigation en bas (initialisé à 2 pour "OT")
  int _currentBottomIndex = 2;

  @override
  void initState() {
    super.initState();
    _otService = OTService(ApiService());
    // Initialisation du TabController avec 6 onglets
    _tabController = TabController(length: 6, vsync: this);

    // Écouter les changements d'onglets pour mettre à jour l'état
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    // Libération de la mémoire en disposant le contrôleur
    _tabController.dispose();
    super.dispose();
  }

  /// Gestion du clic sur un élément de la barre de navigation en bas
  void _onBottomNavTapped(int index) {
    if (index == _currentBottomIndex) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Barre d'application en haut avec le titre et le bouton retour
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: 'Détails OT ${widget.order.code}',
        bottom: CustomTabBar(
          tabController: _tabController,
          tabLabels: const [
            'Détails',
            'Mode Opératoire',
            'Commentaires',
            'Mains d\'œuvre',
            'Matériel',
            'Sous d\'attributs',
          ],
        ),
      ),
      // Corps de l'écran avec le contenu des onglets
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Détails (contenu du formulaire)
          DetailsTab(order: widget.order),
          // Onglet 2: Mode Opératoire (actions Coswin)
          ModeOperatoireTab(otCode: widget.order.code, otService: _otService),
          // Onglet 3: Commentaires (employeefeedbacks Coswin)
          CommentairesTab(otCode: widget.order.code, otService: _otService),
          // Onglet 4: Mains d'œuvre (allocatedemployees Coswin)
          MainsOeuvreTab(otCode: widget.order.code, otService: _otService),
          // Onglet 5: Matériel (stockused Coswin)
          MaterielTab(otCode: widget.order.code, otService: _otService),
          // Onglet 6: Sous d'attributs (attributes Coswin)
          SousAttributsTab(otCode: widget.order.code, otService: _otService),
        ],
      ),
      // Barre de navigation en bas de l'écran
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}

