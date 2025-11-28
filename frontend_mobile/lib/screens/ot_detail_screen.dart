import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/widgets/custom_bottom_navigation_bar.dart';
import 'package:appmobilegmao/widgets/custom_app_bar.dart';
import 'package:appmobilegmao/screens/fichier_lie_screen.dart';

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

  // Index de l'onglet actuellement sélectionné (0 = Détails, 1 = Mode Opératoire, etc.)
  int _currentTabIndex = 0;

  // Index pour la barre de navigation en bas (initialisé à 2 pour "OT")
  int _currentBottomIndex = 2;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _currentBottomIndex = index;
    });
    // TODO: Ajouter la navigation vers d'autres écrans selon l'index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Barre d'application en haut avec le titre et le bouton retour
      appBar: CustomAppBar(
        backgroundColor: AppTheme.secondaryColor,
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
          _DetailsTab(order: widget.order),
          // Onglet 2: Mode Opératoire (vide pour l'instant)
          _ModeOperatoireTab(),
          // Onglet 3: Commentaires (vide pour l'instant)
          _CommentairesTab(),
          // Onglet 4: Mains d'œuvre (vide pour l'instant)
          _MainsOeuvreTab(),
          // Onglet 5: Matériel (vide pour l'instant)
          _MaterielTab(),
          // Onglet 6: Sous d'attributs (vide pour l'instant)
          _SousAttributsTab(),
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

/// Onglet "Détails" - Affiche le taux de réalisation et un bouton pour accéder aux détails complets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du taux de réalisation
class _DetailsTab extends StatefulWidget {
  final Order order;

  const _DetailsTab({required this.order});

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  // Contrôleur pour le champ taux de réalisation
  late TextEditingController _tauxRealisationController;

  @override
  void initState() {
    super.initState();
    _tauxRealisationController = TextEditingController(text: '0%');
  }

  @override
  void dispose() {
    _tauxRealisationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SingleChildScrollView(
      padding: spacing.custom(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ "Taux de réalisation"
          const Text(
            'Taux de réalisation',
            style: TextStyle(
              color: Color(0xFF015CC0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tauxRealisationController,
                    readOnly: true,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                    onTap: () => _showTauxRealisationPicker(context),
                  ),
                ),
                InkWell(
                  onTap: () => _showTauxRealisationPicker(context),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF015CC0),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTauxRealisationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Sélectionner le taux de réalisation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF015CC0),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 101,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        '$index%',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        setState(() {
                          _tauxRealisationController.text = '$index%';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Onglet "Mode Opératoire" - Affiche les prérequis et permet d'ajouter des fichiers
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du mode opératoire
class _ModeOperatoireTab extends StatelessWidget {
  // Liste des prérequis à afficher (données d'exemple)
  final List<String> prerequis = [
    "Charger/recharger/compléter le transport lors le chargement est défectueux",
    "Décharger/décontaminer les entités contaminées en les prenant en charge",
    "Débrancher et remonter le transport par les pieds de barre des crochets",
    "Suivre/assister les travaux de l'excavation",
    "Retirer et stocker les terres souillées",
    "Remettre l'escalat dans l'armement et le serrer pour respecter le temps",
    "Mettre/retirer les cottes ou les tubes de chutes",
    "Fixer les plaques du chantier en toiture pour dévider ou distribuer les actions",
    "Installer l'asteiment avec mégaconcontre",
    "Poser les conduits/bacs pour le remplissage/découpage le couloir",
    "Localiser les zones de service",
    "Canaliser et marquer/précondre le défaut ou les chutes",
    "Dédouler et identifier le tronçon par les exécutions de chauffe selon leurs locations",
    "Bloquer/remonter et adonner la cote des réglages",
    "Localiser les marches précisées pour définir les",
    "Resserrer à vide/coller les trous",
    "Surveiller et bloquer le refroidissement",
    "Installer/éteindre la mégaconcontre",
    "Relancer le poste pour découvrir des têtes",
  ];

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        // Liste scrollable des prérequis
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre "Prérequis"
                Text(
                  'Prérequis',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: responsive.sp(18),
                  ),
                ),
                SizedBox(height: spacing.medium),

                // Liste des prérequis avec des puces numérotées
                ...prerequis.asMap().entries.map((entry) {
                  int index = entry.key;
                  String prerequis = entry.value;
                  return Padding(
                    padding: spacing.custom(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numéro de la puce
                        Text(
                          '${index + 1}. ',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                            fontSize: responsive.sp(14),
                          ),
                        ),
                        // Texte du prérequis
                        Expanded(
                          child: Text(
                            prerequis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontWeight: FontWeight.normal,
                              color: AppTheme.secondaryColor,
                              fontSize: responsive.sp(14),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // Bouton "Retour" en bas avec icône de trombone (ajout de fichiers)
        _ModeOperatoireBottomButton(),
      ],
    );
  }
}

/// Widget qui affiche le bouton en bas de l'onglet Mode Opératoire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du bouton avec icône
class _ModeOperatoireBottomButton extends StatelessWidget {
  /// Gestion du clic sur l'icône de trombone (ajout de fichiers)
  void _handleAttachFile(BuildContext context) {
    // TODO: Implémenter la logique d'ajout de fichiers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout de fichiers (à implémenter)')),
    );
  }

  /// Gestion du clic sur le bouton Retour
  void _handleBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.white,
      padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
      child: Row(
        children: [
          // Bouton avec icône de trombone pour ajouter des fichiers
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: IconButton(
              icon: Icon(
                Icons.attach_file,
                color: AppTheme.primaryColor,
                size: responsive.iconSize(24),
              ),
              onPressed: () => _handleAttachFile(context),
            ),
          ),
          SizedBox(width: spacing.medium),

          // Bouton "Retour" qui prend le reste de l'espace
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleBack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet "Commentaires" - Affiche les commentaires et les pièces jointes
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des commentaires et pièces jointes
class _CommentairesTab extends StatefulWidget {
  @override
  State<_CommentairesTab> createState() => _CommentairesTabState();
}

class _CommentairesTabState extends State<_CommentairesTab> {
  // Liste dynamique des pièces jointes
  int nombrePiecesJointes = 3;

  // Méthode pour ajouter une nouvelle pièce jointe
  void _ajouterPieceJointe() {
    setState(() {
      nombrePiecesJointes++;
    });
  }

  // Méthode pour supprimer une pièce jointe
  void _supprimerPieceJointe(int index) {
    // Ne pas supprimer s'il n'y a qu'une seule pièce jointe
    if (nombrePiecesJointes > 1) {
      setState(() {
        nombrePiecesJointes--;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins une pièce jointe doit être présente'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      children: [
        // Barre d'actions en haut avec les 3 icônes
        _CommentairesActionBar(onAddTap: _ajouterPieceJointe),

        // Contenu scrollable avec les pièces jointes et leurs commentaires
        Expanded(
          child: ListView.builder(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            itemCount: nombrePiecesJointes,
            itemBuilder: (context, index) {
              return Padding(
                padding: spacing.custom(bottom: 20),
                child: _CommentaireWithAttachmentItem(
                  onDelete: () => _supprimerPieceJointe(index),
                ),
              );
            },
          ),
        ),

        // Bouton "Retour" en bas
        _CommentairesBottomButton(),
      ],
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Commentaires
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
class _CommentairesActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const _CommentairesActionBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Icône maison (home)
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.home, color: Color(0xFF015CC0), size: 24),
          ),
          SizedBox(width: spacing.medium),
          // Icône ajouter - ajoute une nouvelle pièce jointe
          InkWell(
            onTap: onAddTap,
            child: const Icon(Icons.add, color: Color(0xFF015CC0), size: 24),
          ),
          SizedBox(width: spacing.medium),
          // Icône télécharger
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Télécharger')));
            },
            child: const Icon(
              Icons.download,
              color: Color(0xFF015CC0),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche une pièce jointe avec son commentaire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bloc pièce jointe + commentaire
/// Principe DRY: Widget réutilisable pour tous les blocs
class _CommentaireWithAttachmentItem extends StatelessWidget {
  final VoidCallback onDelete;

  const _CommentaireWithAttachmentItem({required this.onDelete});

  /// Gestion du clic sur l'icône de trombone
  void _handleAttachFile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FichierLieScreen()),
    );
  }

  /// Gestion du clic sur l'icône de microphone
  void _handleMicrophone(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enregistrement vocal (à implémenter)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone de pièce jointe avec icône de trombone et poubelle
        Container(
          width: double.infinity,
          height: responsive.hp(10),
          padding: spacing.custom(all: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Icône de trombone dans un cercle bleu (cliquable)
              InkWell(
                onTap: () => _handleAttachFile(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: responsive.wp(10),
                  height: responsive.wp(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF015CC0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_file,
                    color: Colors.white,
                    size: responsive.iconSize(20),
                  ),
                ),
              ),
              SizedBox(width: spacing.small),
              // Espace pour afficher le nom du fichier
              Expanded(
                child: Text(
                  '', // Vide pour l'instant
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              // Icône de poubelle pour supprimer
              InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: responsive.iconSize(24),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.small),

        // Zone de commentaire avec icône de microphone cliquable
        Container(
          width: double.infinity,
          height: responsive.hp(12),
          padding: spacing.custom(all: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de microphone cliquable
              InkWell(
                onTap: () => _handleMicrophone(context),
                child: Icon(
                  Icons.mic_none,
                  color: const Color(0xFF015CC0),
                  size: responsive.iconSize(24),
                ),
              ),
              SizedBox(width: spacing.small),
              // Zone de texte pour écrire le commentaire
              Expanded(
                child: TextFormField(
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Écrire un commentaire...',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontSize: responsive.sp(14),
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                    color: const Color.fromRGBO(1, 92, 192, 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche les boutons en bas de l'onglet Commentaires
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des boutons d'action
class _CommentairesBottomButton extends StatelessWidget {
  /// Gestion du clic sur le bouton Enregistrer
  void _handleSave(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Commentaires enregistrés')));
  }

  /// Gestion du clic sur le bouton Retour - retour à la page OT Info
  void _handleBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.white,
      padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
      child: Row(
        children: [
          // Bouton Enregistrer
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 92, 192), // bleu
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Enregistrer',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.medium),
          // Bouton Retour
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleBack(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: const Color.fromARGB(255, 1, 92, 192),
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onglet "Mains d'œuvre" - Affiche la liste des employés affectés avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des mains d'œuvre
class _MainsOeuvreTab extends StatefulWidget {
  @override
  State<_MainsOeuvreTab> createState() => _MainsOeuvreTabState();
}

class _MainsOeuvreTabState extends State<_MainsOeuvreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Liste des employés (données d'exemple inspirées de l'image)
  final List<Map<String, dynamic>> employes = [
    {
      'employe': 'EXTERNE',
      'description': 'EXTERNE',
      'dateDebut': '22/10/2025 00:00',
      'dateFin': '22/10/2025 05:00',
      'heuresRealisees': '5.00',
      'etatOT': 'AV',
      'ressource': 'RDEF',
      'heuresPlanifiees': '0.00',
      'heuresJour': '10.00',
      'taux': 'Taux normal',
    },
    {
      'employe': 'EXTERNE',
      'description': 'EXTERNE',
      'dateDebut': '22/10/2025 00:00',
      'dateFin': '22/10/2025 05:00',
      'heuresRealisees': '5.00',
      'etatOT': 'AV',
      'ressource': 'RDEF',
      'heuresPlanifiees': '0.00',
      'heuresJour': '10.00',
      'taux': 'Taux normal',
    },
    {
      'employe': '5893',
      'description': 'Mbaye NIANG',
      'dateDebut': '22/10/2025 00:00',
      'dateFin': '22/10/2025 05:00',
      'heuresRealisees': '5.00',
      'etatOT': 'AV',
      'ressource': 'ELEC',
      'heuresPlanifiees': '0.00',
      'heuresJour': '5.00',
      'taux': 'Taux normal',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialisation du TabController avec 2 onglets (index 1 = Employés Alloués)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      children: [
        // Barre d'actions avec icônes et "Sélect. une action"
        _MainsOeuvreActionBar(),

        // Barre avec "Action" et champ de recherche
        _ActionSearchBar(),

        // Onglets Intervenants / Employés Alloués / Ressources (fonctionnels)
        _MainsOeuvreTabBar(tabController: _tabController),

        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet Intervenants
              _IntervenantsContent(employes: employes),
              // Onglet Employés Alloués (par défaut)
              _EmployesAllouesContent(employes: employes),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'onglets fonctionnelle (Intervenants / Employés Alloués / Ressources)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets cliquables
/// Principe DRY: Réutilise le pattern TabBar standard de Flutter
class _MainsOeuvreTabBar extends StatelessWidget {
  final TabController tabController;

  const _MainsOeuvreTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF015CC0),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(12),
        ),
        tabs: const [Tab(text: 'INTERVENANTS'), Tab(text: 'EMPLOYÉS ALLOUÉS')],
      ),
    );
  }
}

/// Widget pour afficher le contenu de l'onglet Intervenants
/// Principe SOLID: Single Responsibility - Gère uniquement le contenu de l'onglet Intervenants
class _IntervenantsContent extends StatelessWidget {
  final List<Map<String, dynamic>> employes;

  const _IntervenantsContent({required this.employes});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      children: [
        // En-tête du tableau
        _TableHeader(),
        // Corps du tableau avec liste d'employés
        Expanded(
          child: ListView.builder(
            padding: spacing.custom(horizontal: 10, vertical: 5),
            itemCount: employes.length,
            itemBuilder: (context, index) {
              final employe = employes[index];
              return _EmployeRow(
                index: index + 1,
                employe: employe['employe']!,
                description: employe['description']!,
                dateDebut: employe['dateDebut']!,
                dateFin: employe['dateFin']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le contenu de l'onglet Employés Alloués avec sous-onglet DÉTAILS
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du contenu Employés Alloués
class _EmployesAllouesContent extends StatefulWidget {
  final List<Map<String, dynamic>> employes;

  const _EmployesAllouesContent({required this.employes});

  @override
  State<_EmployesAllouesContent> createState() =>
      _EmployesAllouesContentState();
}

class _EmployesAllouesContentState extends State<_EmployesAllouesContent> {
  bool _showDetails = false; // État pour afficher ou masquer les détails

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    if (_showDetails) {
      // Affiche le formulaire de détails
      return _EmployesAllouesDetailsTab(onBack: _toggleDetails);
    }

    // Affiche directement le tableau des employés alloués (image fournie)
    return Column(
      children: [
        // En-tête du tableau avec toutes les colonnes
        _EmployesAllouesTableHeader(),

        // Liste scrollable des employés
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.employes.length,
            itemBuilder: (context, index) {
              final employe = widget.employes[index];
              return _EmployesAllouesRow(
                index: index + 1,
                employe: employe['employe'] ?? '',
                description: employe['description'] ?? '',
                dateAllocation: employe['dateDebut'] ?? '',
                heuresAllouees: employe['heuresRealisees'] ?? '3.00',
                etatAllocation: employe['etatOT'] ?? '0. Non réalisé',
                etatRejet: '0. Pas d\'objection',
                aPermis: '0. Non',
                numeroSequence: '',
              );
            },
          ),
        ),

        // Bouton DÉTAILS en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'DÉTAILS',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le formulaire de détails d'un employé alloué
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise les patterns de formulaire existants
class _EmployesAllouesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _EmployesAllouesDetailsTab({required this.onBack});

  @override
  State<_EmployesAllouesDetailsTab> createState() =>
      _EmployesAllouesDetailsTabState();
}

class _EmployesAllouesDetailsTabState
    extends State<_EmployesAllouesDetailsTab> {
  // Contrôleurs pour les champs du formulaire
  late TextEditingController _employeController;
  late TextEditingController _dateAllocationController;
  late TextEditingController _heuresAlloueesController;
  late TextEditingController _etatAllocationController;
  late TextEditingController _etatRejetController;
  late TextEditingController _aPermisController;
  late TextEditingController _numeroSequenceController;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs avec données d'exemple
    _employeController = TextEditingController(text: '5893');
    _dateAllocationController = TextEditingController(text: '22/10/2025 07:30');
    _heuresAlloueesController = TextEditingController(text: '3.00');
    _etatAllocationController = TextEditingController(text: '0. Non réalisé');
    _etatRejetController = TextEditingController(text: '0. Pas d\'objection');
    _aPermisController = TextEditingController(text: '0. Non');
    _numeroSequenceController = TextEditingController();
  }

  @override
  void dispose() {
    _employeController.dispose();
    _dateAllocationController.dispose();
    _heuresAlloueesController.dispose();
    _etatAllocationController.dispose();
    _etatRejetController.dispose();
    _aPermisController.dispose();
    _numeroSequenceController.dispose();
    super.dispose();
  }

  /// Affiche le sélecteur de date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.secondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateAllocationController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre d'icônes d'action (similaire à l'image)
                _EmployesAllouesActionBar(),
                SizedBox(height: spacing.large),

                // Ligne 1: Employé et Description de l'employé
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Employé',
                        controller: _employeController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Description de l\'employé',
                        controller: TextEditingController(text: 'Mbaye NIANG'),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Date d'allocation et Heures allouées
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date d\'allocation',
                        controller: _dateAllocationController,
                        isDateField: true,
                        backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                        onDateTap: _selectDate,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Heures allouées',
                        controller: _heuresAlloueesController,
                        backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: État de l'allocation et État de rejet de la qualification
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'État de l\'allocation',
                        controller: _etatAllocationController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'État de rejet de la qualification',
                        controller: _etatRejetController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 4: À des permis de travail
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'À des permis de travail',
                        controller: _aPermisController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide pour alignement
                  ],
                ),
                SizedBox(height: spacing.large),

                // Ligne 5: N° de séquence et Action
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'N° de séquence',
                        controller: _numeroSequenceController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Action',
                        controller: TextEditingController(),
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Champ Action large (en dessous)
                Container(
                  width: double.infinity,
                  height: responsive.hp(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextFormField(
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      contentPadding: spacing.custom(all: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'action avec icônes pour les employés alloués
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des icônes d'action
class _EmployesAllouesActionBar extends StatelessWidget {
  const _EmployesAllouesActionBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconButton(icon: Icons.arrow_back_ios, onPressed: () {}),
        _ActionIconButton(icon: Icons.arrow_forward_ios, onPressed: () {}),
        _ActionIconButton(icon: Icons.add, onPressed: () {}),
        _ActionIconButton(icon: Icons.copy, onPressed: () {}),
        _ActionIconButton(icon: Icons.remove_red_eye, onPressed: () {}),
        _ActionIconButton(icon: Icons.refresh, onPressed: () {}),
        _ActionIconButton(icon: Icons.delete, onPressed: () {}),
        _ActionIconButton(icon: Icons.filter_list, onPressed: () {}),
        _ActionIconButton(icon: Icons.search, onPressed: () {}),
        _ActionIconButton(icon: Icons.find_replace, onPressed: () {}),
        _ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
      ],
    );
  }
}

/// Widget pour un champ de formulaire employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Réutilisable pour tous les champs du formulaire
class _EmployeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final bool readOnly;
  final bool enabled;
  final Color? backgroundColor;
  final VoidCallback? onDateTap;
  final Function(String)? onChanged;

  const _EmployeFormField({
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.readOnly = false,
    this.enabled = true,
    this.backgroundColor,
    this.onDateTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(13),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration:
              backgroundColor != null
                  ? BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly || isDateField,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(13),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border:
                        backgroundColor == null
                            ? const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            )
                            : InputBorder.none,
                  ),
                ),
              ),
              if (hasDropdown)
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(20),
                    ),
                  ),
                ),
              if (isDateField)
                InkWell(
                  onTap: onDateTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre de sous-onglets avec bouton +
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des sous-onglets
class _SubTabsBar extends StatelessWidget {
  final List<String> tabs;
  final TabController tabController;
  final VoidCallback onAddTap;

  const _SubTabsBar({
    required this.tabs,
    required this.tabController,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          // Flèche gauche pour navigation
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
          // Flèche droite pour navigation
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
          // Bouton +
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: onAddTap,
            color: AppTheme.secondaryColor,
            tooltip: 'Ajouter un employé',
          ),
          SizedBox(width: spacing.small),
          // Onglets DÉTAILS / GLOBAL
          Expanded(
            child: TabBar(
              controller: tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.secondaryColor,
              indicator: BoxDecoration(
                color: const Color(0xFF015CC0),
                borderRadius: BorderRadius.circular(4),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                fontSize: responsive.sp(12),
              ),
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'onglet DÉTAILS avec les informations de l'employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des détails de l'employé
/// Principe DRY: Réutilise le pattern de formulaire de ot_info_details_screen
class _EmployeDetailsTab extends StatelessWidget {
  final Map<String, dynamic> employe;

  const _EmployeDetailsTab({required this.employe});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: spacing.custom(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1: Employé et Description
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Employé',
                  value: employe['employe'] ?? '5893',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: '',
                  value: employe['description'] ?? 'Mbaye NIANG',
                  readOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 2: Date d'allocation et Heures allouées
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Date d\'allocation',
                  value: employe['dateDebut'] ?? '22/10/2025 07:30',
                  hasDatePicker: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: 'Heures allouées',
                  value: employe['heuresRealisees'] ?? '3,00',
                  backgroundColor: const Color(0xFFFFFF99), // Fond jaune
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 3: État de l'allocation et État de rejet de la qualification
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'État de l\'allocation',
                  value: employe['etatOT'] ?? '0. Non réalisé',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                child: _DetailField(
                  label: 'État de rejet de la qualification',
                  value: '0. Pas d\'objection',
                  hasDropdown: true,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 4: À des permis de travail et N° de séquence
          Row(
            children: [
              Expanded(
                child: _DetailField(
                  label: 'À des permis de travail',
                  value: '0. Non',
                  hasDropdown: true,
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(child: _DetailField(label: 'N° de séquence', value: '')),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Ligne 5: Action
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _DetailField(label: 'Action', value: ''),
              ),
              SizedBox(width: spacing.medium),
              Expanded(flex: 1, child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'onglet GLOBAL
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la vue globale
class _GlobalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Vue globale (à implémenter)',
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

/// Widget pour afficher un champ de détail avec label
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Réutilisable pour tous les champs de détails
class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasDropdown;
  final bool hasDatePicker;
  final bool readOnly;
  final Color? backgroundColor;

  const _DetailField({
    required this.label,
    required this.value,
    this.hasDropdown = false,
    this.hasDatePicker = false,
    this.readOnly = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(13),
            ),
          ),
        if (label.isNotEmpty) SizedBox(height: spacing.tiny),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: AppTheme.thirdColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  readOnly: readOnly,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(13),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (hasDropdown)
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.secondaryColor,
                  size: responsive.iconSize(24),
                ),
              if (hasDatePicker)
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.secondaryColor,
                  size: responsive.iconSize(18),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher une carte d'employé avec ses informations
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une carte d'employé
/// Principe DRY: Réutilise le pattern _FormField pour chaque champ
class _EmployeCard extends StatelessWidget {
  final String employe;
  final String dateDebut;
  final String dateFin;

  const _EmployeCard({
    required this.employe,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      padding: spacing.custom(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ Employé (lecture seule via _DetailField)
          _DetailField(label: 'Employé', value: employe, readOnly: true),
          SizedBox(height: spacing.large),

          // Champ Date de début (utilise hasDatePicker pour afficher l'icône)
          _DetailField(
            label: 'Date de début',
            value: dateDebut,
            hasDatePicker: true,
          ),
          SizedBox(height: spacing.large),

          // Champ Date de fin
          _DetailField(
            label: 'Date de fin',
            value: dateFin,
            hasDatePicker: true,
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un champ de formulaire dans la carte employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Inspiré du widget _FormField de ot_info_details_screen
/// Widget pour afficher le contenu de l'onglet Ressources
/// Principe SOLID: Single Responsibility - Gère uniquement le contenu de l'onglet Ressources
class _RessourcesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Contenu Ressources à implémenter',
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Mains d'œuvre
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions avec icônes
/// Principe DRY: Réutilise le pattern des autres barres d'action
class _MainsOeuvreActionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[100],
      padding: spacing.custom(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sélect. une action',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF015CC0),
              fontSize: responsive.sp(14),
            ),
          ),
          SizedBox(width: spacing.small),
          // Icônes d'action
          _ActionIconButton(icon: Icons.add, onPressed: () {}),
          _ActionIconButton(icon: Icons.close, onPressed: () {}),
          _ActionIconButton(icon: Icons.refresh, onPressed: () {}),
          _ActionIconButton(icon: Icons.list, onPressed: () {}),
          _ActionIconButton(icon: Icons.grid_view, onPressed: () {}),
          _ActionIconButton(icon: Icons.view_column, onPressed: () {}),
          _ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
          const Spacer(),
          // Icône d'horloge à droite
          Icon(
            Icons.access_time,
            color: AppTheme.secondaryColor,
            size: responsive.iconSize(24),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une icône d'action cliquable
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une icône d'action
/// Principe DRY: Réutilisable pour toutes les icônes d'action
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: const Color(0xFF015CC0),
          size: responsive.iconSize(20),
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre "Action" avec champ de recherche
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre de recherche
class _ActionSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.white,
      padding: spacing.custom(horizontal: 15, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Action',
          labelStyle: TextStyle(
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(14),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF015CC0), width: 2),
          ),
          contentPadding: spacing.custom(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre des onglets (Intervenants / Employés Alloués / Ressources)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets
class _TabsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          _TabButton(label: 'INTERVENANTS', isActive: true),
          SizedBox(width: spacing.small),
          _TabButton(label: 'EMPLOYÉS ALLOUÉS', isActive: false),
          SizedBox(width: spacing.small),
          _TabButton(label: 'RESSOURCES', isActive: false),
        ],
      ),
    );
  }
}

/// Widget pour afficher un bouton d'onglet
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un bouton d'onglet
/// Principe DRY: Réutilisable pour tous les onglets
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabButton({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF015CC0) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xFF015CC0) : AppTheme.thirdColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppTheme.secondaryColor,
          fontSize: responsive.sp(12),
        ),
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête du tableau
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          // Colonne numéro
          SizedBox(width: 40, child: _HeaderText('', responsive)),
          // Colonne Employé
          Expanded(flex: 2, child: _HeaderText('Employé', responsive)),
          // Colonne Description
          Expanded(
            flex: 3,
            child: _HeaderText('Description de l\'employé', responsive),
          ),
          // Colonne Date de début
          Expanded(flex: 2, child: _HeaderText('Date de début', responsive)),
          // Colonne Date de fin
          Expanded(flex: 2, child: _HeaderText('Date de fin', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: responsive.sp(12),
      ),
    );
  }
}

/// Widget pour afficher une ligne d'employé dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne d'employé
/// Principe DRY: Réutilisable pour toutes les lignes d'employés
class _EmployeRow extends StatelessWidget {
  final int index;
  final String employe;
  final String description;
  final String dateDebut;
  final String dateFin;

  const _EmployeRow({
    required this.index,
    required this.employe,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: index.isOdd ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Numéro de ligne
          SizedBox(width: 40, child: _CellText(index.toString(), responsive)),
          // Employé
          Expanded(flex: 2, child: _CellText(employe, responsive)),
          // Description
          Expanded(flex: 3, child: _CellText(description, responsive)),
          // Date de début
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          // Date de fin
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(12),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Employés Alloués
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête du tableau
/// Principe DRY: Réutilise le pattern de _TableHeader
class _EmployesAllouesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          // Numéro
          SizedBox(width: 40, child: _HeaderText('', responsive)),
          // Employé
          Expanded(flex: 2, child: _HeaderText('Employé', responsive)),
          // Description de l'employé
          Expanded(
            flex: 2,
            child: _HeaderText('Description de l\'employé', responsive),
          ),
          // Date d'allocation
          Expanded(
            flex: 2,
            child: _HeaderText('Date d\'allocation', responsive),
          ),
          // Heures allouées
          Expanded(flex: 2, child: _HeaderText('Heures allouées', responsive)),
          // État de l'allocation
          Expanded(
            flex: 2,
            child: _HeaderText('État de l\'allocation', responsive),
          ),
          // État de rejet de la qualification
          Expanded(
            flex: 2,
            child: _HeaderText('État de rejet de la qualification', responsive),
          ),
          // A des permis de travail
          Expanded(
            flex: 2,
            child: _HeaderText('À des permis de travail', responsive),
          ),
          // N° de séquence
          Expanded(flex: 2, child: _HeaderText('N° de séquence', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: responsive.sp(11),
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}

/// Widget pour afficher une ligne d'employé alloué dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilisable pour toutes les lignes
class _EmployesAllouesRow extends StatelessWidget {
  final int index;
  final String employe;
  final String description;
  final String dateAllocation;
  final String heuresAllouees;
  final String etatAllocation;
  final String etatRejet;
  final String aPermis;
  final String numeroSequence;

  const _EmployesAllouesRow({
    required this.index,
    required this.employe,
    required this.description,
    required this.dateAllocation,
    required this.heuresAllouees,
    required this.etatAllocation,
    required this.etatRejet,
    required this.aPermis,
    required this.numeroSequence,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      padding: spacing.custom(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: index.isOdd ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Numéro
          SizedBox(width: 40, child: _CellText(index.toString(), responsive)),
          // Employé
          Expanded(flex: 2, child: _CellText(employe, responsive)),
          // Description
          Expanded(flex: 2, child: _CellText(description, responsive)),
          // Date d'allocation
          Expanded(flex: 2, child: _CellText(dateAllocation, responsive)),
          // Heures allouées
          Expanded(flex: 2, child: _CellText(heuresAllouees, responsive)),
          // État de l'allocation
          Expanded(flex: 2, child: _CellText(etatAllocation, responsive)),
          // État de rejet
          Expanded(flex: 2, child: _CellText(etatRejet, responsive)),
          // A des permis
          Expanded(flex: 2, child: _CellText(aPermis, responsive)),
          // N° de séquence
          Expanded(flex: 2, child: _CellText(numeroSequence, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(11),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet "Matériel" - Affiche la liste du matériel utilisé avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du matériel
/// Principe DRY: Réutilise le pattern TabController comme _MainsOeuvreTab
class _MaterielTab extends StatefulWidget {
  @override
  State<_MaterielTab> createState() => _MaterielTabState();
}

class _MaterielTabState extends State<_MaterielTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialisation du TabController avec 2 onglets (Moyens, Stock)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'onglets (Moyens / Stock)
        _MaterielTabBar(tabController: _tabController),
        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet MOYENS
              _MoyensTab(),
              // Onglet STOCK (avec sous-onglets Pièces et Services)
              _StockTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'onglets du matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des onglets
/// Principe DRY: Réutilise le pattern de _MainsOeuvreTabBar
class _MaterielTabBar extends StatelessWidget {
  final TabController tabController;

  const _MaterielTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[200],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF015CC0),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(11),
        ),
        tabs: const [Tab(text: 'MOYENS'), Tab(text: 'STOCK')],
      ),
    );
  }
}

/// Onglet STOCK - Contient les sous-onglets Pièces et Services
/// Principe SOLID: Single Responsibility - Gère uniquement l'onglet Stock
/// Principe DRY: Réutilise le pattern TabController
class _StockTab extends StatefulWidget {
  @override
  State<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<_StockTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    // Initialisation du sous-TabController avec 2 onglets (Pièces, Services)
    _subTabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de sous-onglets (Pièces / Services)
        _StockSubTabBar(tabController: _subTabController),
        // Contenu des sous-onglets
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Sous-onglet PIÈCES
              _StockPiecesTab(),
              // Sous-onglet SERVICES
              _StockServicesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre de sous-onglets Stock (Pièces / Services)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des sous-onglets
class _StockSubTabBar extends StatelessWidget {
  final TabController tabController;

  const _StockSubTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[300],
      child: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.secondaryColor,
        indicator: BoxDecoration(
          color: const Color(0xFF015CC0),
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
          fontSize: responsive.sp(11),
        ),
        tabs: const [Tab(text: 'PIÈCES'), Tab(text: 'SERVICES')],
      ),
    );
  }
}

/// Onglet MOYENS - Affiche le tableau des moyens avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement les moyens
/// Principe DRY: Réutilise le pattern de _EmployesAllouesContent
class _MoyensTab extends StatefulWidget {
  @override
  State<_MoyensTab> createState() => _MoyensTabState();
}

class _MoyensTabState extends State<_MoyensTab> {
  bool _showDetails = false;

  // Liste du matériel (données d'exemple)
  final List<Map<String, dynamic>> materiels = [
    {
      'moyen': 'VEHICULE LEGER',
      'equipement': 'AA-555-BA',
      'dateDebut': '22/10/2025 00:00',
      'tempsUtilise': '7.00',
    },
    {
      'moyen': 'VEHICULE LOURD',
      'equipement': 'EX 0704',
      'dateDebut': '22/10/2025 00:00',
      'tempsUtilise': '1.00',
    },
  ];

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  /// Calcule la date de fin en ajoutant le temps utilisé à la date de début
  String _calculateDateFin(String dateDebut, String tempsUtilise) {
    try {
      final parts = dateDebut.split(' ');
      final dateParts = parts[0].split('/');

      if (dateParts.length >= 3) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);

        DateTime debut = DateTime(year, month, day);
        final heures = double.parse(tempsUtilise);
        final fin = debut.add(Duration(hours: heures.toInt()));

        return '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}/${fin.year} ${fin.hour.toString().padLeft(2, '0')}:00';
      }
    } catch (e) {
      return '00/00/0000 00:00';
    }
    return '00/00/0000 00:00';
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _MoyensDetailsTab(onBack: _toggleDetails);
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        _MaterielActionBar(onAddTap: _toggleDetails),
        SizedBox(height: spacing.small),
        // En-tête du tableau
        _MoyensTableHeader(),
        // Liste des matériels
        Expanded(
          child: ListView.builder(
            itemCount: materiels.length,
            itemBuilder: (context, index) {
              final materiel = materiels[index];
              final dateDebut = materiel['dateDebut'] ?? '22/10/2025 00:00';
              final tempsUtilise = materiel['tempsUtilise'] ?? '0.00';
              final dateFin = _calculateDateFin(dateDebut, tempsUtilise);

              return _MoyensRow(
                index: index,
                moyen: materiel['moyen'] ?? '',
                equipement: materiel['equipement'] ?? '',
                dateDebut: dateDebut,
                tempsUtilise: tempsUtilise,
                dateFin: dateFin,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le formulaire de détails des moyens
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _MoyensDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _MoyensDetailsTab({required this.onBack});

  @override
  State<_MoyensDetailsTab> createState() => _MoyensDetailsTabState();
}

class _MoyensDetailsTabState extends State<_MoyensDetailsTab> {
  late TextEditingController _moyenController;
  late TextEditingController _equipementController;
  late TextEditingController _dateDebutController;
  late TextEditingController _tempsUtiliseController;
  late TextEditingController _dateFinController;

  @override
  void initState() {
    super.initState();
    _moyenController = TextEditingController();
    _equipementController = TextEditingController(text: 'AA-555-BA');
    _dateDebutController = TextEditingController(text: '21/10/2025 07:30');
    _tempsUtiliseController = TextEditingController(text: '0.00');
    _dateFinController = TextEditingController(text: '21/10/2025 07:30');
  }

  @override
  void dispose() {
    _moyenController.dispose();
    _equipementController.dispose();
    _dateDebutController.dispose();
    _tempsUtiliseController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDateDebut() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF015CC0)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateDebutController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year} 07:30';
        _calculateDateFin();
      });
    }
  }

  /// Calcule automatiquement la date de fin en fonction de la date de début et du temps utilisé
  void _calculateDateFin() {
    try {
      final dateDebutText = _dateDebutController.text;
      final tempsUtiliseText = _tempsUtiliseController.text;

      final parts = dateDebutText.split(' ');
      final dateParts = parts[0].split('/');

      if (dateParts.length >= 3 && tempsUtiliseText.isNotEmpty) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);

        DateTime debut = DateTime(year, month, day);
        final heures = double.parse(tempsUtiliseText);
        final fin = debut.add(Duration(hours: heures.toInt()));

        setState(() {
          _dateFinController.text =
              '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}/${fin.year} ${fin.hour.toString().padLeft(2, '0')}:00';
        });
      }
    } catch (e) {
      // En cas d'erreur, ne rien faire
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Moyen et Équipement
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Moyen',
                        controller: _moyenController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Équipement',
                        controller: _equipementController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Date de début et Temps utilisé
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date de début',
                        controller: _dateDebutController,
                        isDateField: true,
                        onDateTap: _selectDateDebut,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Temps utilisé',
                        controller: _tempsUtiliseController,
                        onChanged: (value) => _calculateDateFin(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: Date de fin (calculée automatiquement)
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Date de fin (calculée)',
                        controller: _dateFinController,
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide pour alignement
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
/// Principe DRY: Réutilise le pattern _ActionIconButton
class _MaterielActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const _MaterielActionBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _ActionIconButton(icon: Icons.add, onPressed: onAddTap),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.refresh, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.check, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.close, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.insert_chart, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.view_module, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Moyens
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
/// Principe DRY: Réutilise le pattern _HeaderText
class _MoyensTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Moyen', responsive)),
          Expanded(flex: 2, child: _HeaderText('Équipement', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date début', responsive)),
          Expanded(flex: 2, child: _HeaderText('Temps utilisé', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date fin', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de moyens dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilise le pattern _CellText
class _MoyensRow extends StatelessWidget {
  final int index;
  final String moyen;
  final String equipement;
  final String dateDebut;
  final String tempsUtilise;
  final String dateFin;

  const _MoyensRow({
    required this.index,
    required this.moyen,
    required this.equipement,
    required this.dateDebut,
    required this.tempsUtilise,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(moyen, responsive)),
          Expanded(flex: 2, child: _CellText(equipement, responsive)),
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          Expanded(flex: 2, child: _CellText(tempsUtilise, responsive)),
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet STOCK/PIÈCES - Affiche le tableau des pièces avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement les pièces
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _StockPiecesTab extends StatefulWidget {
  @override
  State<_StockPiecesTab> createState() => _StockPiecesTabState();
}

class _StockPiecesTabState extends State<_StockPiecesTab> {
  bool _showDetails = false;

  // Liste des pièces (données d'exemple)
  final List<Map<String, dynamic>> pieces = [
    {'article': 'HUILE MOTEUR 5W30', 'quantiteUtilise': '2.00'},
    {'article': 'FILTRE À AIR', 'quantiteUtilise': '1.00'},
  ];

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _StockPiecesDetailsTab(onBack: _toggleDetails);
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        _MaterielActionBar(onAddTap: _toggleDetails),
        SizedBox(height: spacing.small),
        // En-tête du tableau
        _StockPiecesTableHeader(),
        // Liste des pièces
        Expanded(
          child: ListView.builder(
            itemCount: pieces.length,
            itemBuilder: (context, index) {
              final piece = pieces[index];
              return _StockPiecesRow(
                index: index,
                article: piece['article'] ?? '',
                quantiteUtilise: piece['quantiteUtilise'] ?? '0.00',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le formulaire de détails des pièces
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _StockPiecesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _StockPiecesDetailsTab({required this.onBack});

  @override
  State<_StockPiecesDetailsTab> createState() => _StockPiecesDetailsTabState();
}

class _StockPiecesDetailsTabState extends State<_StockPiecesDetailsTab> {
  late TextEditingController _articleController;
  late TextEditingController _quantiteUtiliseController;

  @override
  void initState() {
    super.initState();
    _articleController = TextEditingController();
    _quantiteUtiliseController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _articleController.dispose();
    _quantiteUtiliseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Article et Quantité utilisée
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Article',
                        controller: _articleController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité utilisée',
                        controller: _quantiteUtiliseController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Stock/Pièces
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _StockPiecesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _HeaderText('Article', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité utilisée', responsive),
          ),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de pièce dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _StockPiecesRow extends StatelessWidget {
  final int index;
  final String article;
  final String quantiteUtilise;

  const _StockPiecesRow({
    required this.index,
    required this.article,
    required this.quantiteUtilise,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _CellText(article, responsive)),
          Expanded(flex: 1, child: _CellText(quantiteUtilise, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet STOCK/SERVICES - Affiche le tableau des services avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement les services
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _StockServicesTab extends StatefulWidget {
  @override
  State<_StockServicesTab> createState() => _StockServicesTabState();
}

class _StockServicesTabState extends State<_StockServicesTab> {
  bool _showDetails = false;

  // Liste des services (données d'exemple)
  final List<Map<String, dynamic>> services = [
    {
      'article': 'SERVICE MAINTENANCE',
      'quantitePlanifiee': '10.00',
      'quantiteConsommee': '8.00',
    },
    {
      'article': 'SERVICE DIAGNOSTIC',
      'quantitePlanifiee': '5.00',
      'quantiteConsommee': '5.00',
    },
  ];

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _StockServicesDetailsTab(onBack: _toggleDetails);
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        _MaterielActionBar(onAddTap: _toggleDetails),
        SizedBox(height: spacing.small),
        // En-tête du tableau
        _StockServicesTableHeader(),
        // Liste des services
        Expanded(
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _StockServicesRow(
                index: index,
                article: service['article'] ?? '',
                quantitePlanifiee: service['quantitePlanifiee'] ?? '0.00',
                quantiteConsommee: service['quantiteConsommee'] ?? '0.00',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher le formulaire de détails des services
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _StockServicesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _StockServicesDetailsTab({required this.onBack});

  @override
  State<_StockServicesDetailsTab> createState() =>
      _StockServicesDetailsTabState();
}

class _StockServicesDetailsTabState extends State<_StockServicesDetailsTab> {
  late TextEditingController _articleController;
  late TextEditingController _quantitePlanifieeController;
  late TextEditingController _quantiteConsommeeController;

  @override
  void initState() {
    super.initState();
    _articleController = TextEditingController();
    _quantitePlanifieeController = TextEditingController(text: '0.00');
    _quantiteConsommeeController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _articleController.dispose();
    _quantitePlanifieeController.dispose();
    _quantiteConsommeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Article et Quantité planifiée
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Article',
                        controller: _articleController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité planifiée',
                        controller: _quantitePlanifieeController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Quantité consommée
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Quantité consommée',
                        controller: _quantiteConsommeeController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(child: Container()), // Espace vide
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Stock/Services
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _StockServicesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Article', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité planifiée', responsive),
          ),
          Expanded(
            flex: 1,
            child: _HeaderText('Quantité consommée', responsive),
          ),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de service dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _StockServicesRow extends StatelessWidget {
  final int index;
  final String article;
  final String quantitePlanifiee;
  final String quantiteConsommee;

  const _StockServicesRow({
    required this.index,
    required this.article,
    required this.quantitePlanifiee,
    required this.quantiteConsommee,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(article, responsive)),
          Expanded(flex: 1, child: _CellText(quantitePlanifiee, responsive)),
          Expanded(flex: 1, child: _CellText(quantiteConsommee, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(11),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Matériel (ancien code conservé pour compatibilité)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
/// Principe DRY: Réutilise le pattern _ActionIconButton
class _MaterielActionBarOld extends StatelessWidget {
  final VoidCallback onAddTap;

  const _MaterielActionBarOld({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _ActionIconButton(icon: Icons.add, onPressed: onAddTap),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.refresh, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.check, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.close, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.insert_chart, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.view_module, onPressed: () {}),
          SizedBox(width: spacing.small),
          _ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _MaterielTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Moyen', responsive)),
          Expanded(flex: 2, child: _HeaderText('Équipement', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date début', responsive)),
          Expanded(flex: 2, child: _HeaderText('Temps utilisé', responsive)),
          Expanded(flex: 2, child: _HeaderText('Date fin', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(12),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne de matériel dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
class _MaterielRow extends StatelessWidget {
  final int index;
  final String moyen;
  final String equipement;
  final String dateDebut;
  final String tempsUtilise;
  final String dateFin;

  const _MaterielRow({
    required this.index,
    required this.moyen,
    required this.equipement,
    required this.dateDebut,
    required this.tempsUtilise,
    required this.dateFin,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: _CellText(moyen, responsive)),
          Expanded(flex: 2, child: _CellText(equipement, responsive)),
          Expanded(flex: 2, child: _CellText(dateDebut, responsive)),
          Expanded(flex: 2, child: _CellText(tempsUtilise, responsive)),
          Expanded(flex: 2, child: _CellText(dateFin, responsive)),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontSize: responsive.sp(11),
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Onglet "Attributs" - Affiche le tableau des attributs avec formulaire
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des attributs
/// Principe DRY: Réutilise le pattern de _MoyensTab
class _SousAttributsTab extends StatefulWidget {
  @override
  State<_SousAttributsTab> createState() => _SousAttributsTabState();
}

class _SousAttributsTabState extends State<_SousAttributsTab> {
  bool _showDetails = false;

  // Liste des attributs (données d'exemple inspirées de l'image)
  // Chaque attribut peut avoir 'etat', 'verifie' ou 'attributMaj' coché (un seul à la fois)
  final List<Map<String, dynamic>> attributs = [
    {
      'classeAttribut': '3',
      'attribut': 'PUISSANCE EN KVA',
      'valeur': '400',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox':
          'etat', // Peut être: 'etat', 'verifie', 'attributMaj', ou null
    },
    {
      'classeAttribut': '3',
      'attribut': 'Numéro de série',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Tension de service US (V)',
      'valeur': 'B2',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Type',
      'valeur': 'H59',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Tension en KV',
      'valeur': '30',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Numéro ordre',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Broche',
      'valeur': 'EMBROCHABLE',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Position curseur',
      'valeur': '2',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Fournisseur',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Constructeur',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Date mise en service',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
    {
      'classeAttribut': '3',
      'attribut': 'Année de fabrication',
      'valeur': '',
      'unite': '',
      'symboleUnite': '',
      'valeurEtalon': '',
      'selectedCheckbox': null,
    },
  ];

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  /// Change la checkbox sélectionnée pour un attribut donné
  /// Principe SOLID: Single Responsibility - Gère uniquement le changement d'état
  void _onCheckboxChanged(int index, String checkboxType) {
    setState(() {
      final currentSelection = attributs[index]['selectedCheckbox'];
      // Si la même checkbox est cliquée, on la décoche
      if (currentSelection == checkboxType) {
        attributs[index]['selectedCheckbox'] = null;
      } else {
        // Sinon on coche la nouvelle checkbox
        attributs[index]['selectedCheckbox'] = checkboxType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _AttributsDetailsTab(onBack: _toggleDetails);
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        _MaterielActionBar(onAddTap: _toggleDetails),
        SizedBox(height: spacing.small),
        // Champs d'en-tête (Numéro de jeu, Créateur, Date)
        _AttributsHeaderFields(),
        SizedBox(height: spacing.medium),
        // En-tête du tableau
        _AttributsTableHeader(),
        // Liste des attributs
        Expanded(
          child: ListView.builder(
            itemCount: attributs.length,
            itemBuilder: (context, index) {
              final attribut = attributs[index];
              return _AttributsRow(
                index: index,
                classeAttribut: attribut['classeAttribut'] ?? '',
                attribut: attribut['attribut'] ?? '',
                valeur: attribut['valeur'] ?? '',
                unite: attribut['unite'] ?? '',
                symboleUnite: attribut['symboleUnite'] ?? '',
                valeurEtalon: attribut['valeurEtalon'] ?? '',
                selectedCheckbox: attribut['selectedCheckbox'],
                onCheckboxChanged:
                    (checkboxType) => _onCheckboxChanged(index, checkboxType),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher les champs d'en-tête des attributs
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des champs d'en-tête
/// Principe DRY: Réutilise le pattern de formulaire
class _AttributsHeaderFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: Colors.grey[100],
      padding: spacing.custom(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          // Ligne 1: Numéro de jeu
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Numéro de jeu',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.sp(12),
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: spacing.custom(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontFamily: AppTheme.fontRoboto,
                      fontSize: responsive.sp(12),
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.medium),
          // Ligne 2: Créateur et Date
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Text(
                      'Créateur',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.sp(12),
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    SizedBox(width: spacing.small),
                    Expanded(
                      child: Container(
                        padding: spacing.custom(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Cheikhou Oumar Kane',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(11),
                            color: AppTheme.secondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.medium),
              Expanded(
                flex: 1,
                child: Container(
                  padding: spacing.custom(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '20/10/2025 17:57',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontSize: responsive.sp(11),
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: responsive.iconSize(16),
                        color: AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher le formulaire de détails d'un attribut
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise _EmployeFormField
class _AttributsDetailsTab extends StatefulWidget {
  final VoidCallback onBack;

  const _AttributsDetailsTab({required this.onBack});

  @override
  State<_AttributsDetailsTab> createState() => _AttributsDetailsTabState();
}

class _AttributsDetailsTabState extends State<_AttributsDetailsTab> {
  late TextEditingController _classeAttributController;
  late TextEditingController _attributController;
  late TextEditingController _valeurController;
  late TextEditingController _uniteController;
  late TextEditingController _symboleUniteController;
  late TextEditingController _valeurEtalonController;

  @override
  void initState() {
    super.initState();
    _classeAttributController = TextEditingController(text: '3');
    _attributController = TextEditingController();
    _valeurController = TextEditingController();
    _uniteController = TextEditingController();
    _symboleUniteController = TextEditingController();
    _valeurEtalonController = TextEditingController();
  }

  @override
  void dispose() {
    _classeAttributController.dispose();
    _attributController.dispose();
    _valeurController.dispose();
    _uniteController.dispose();
    _symboleUniteController.dispose();
    _valeurEtalonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: spacing.custom(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Classe d'attribut et Attribut
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Classe d\'attribut',
                        controller: _classeAttributController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Attribut',
                        controller: _attributController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Valeur et Unité
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Valeur',
                        controller: _valeurController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Unité',
                        controller: _uniteController,
                        hasDropdown: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: Symbole de l'unité et Valeur étalon
                Row(
                  children: [
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Symbole de l\'unité',
                        controller: _symboleUniteController,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: _EmployeFormField(
                        label: 'Valeur étalon',
                        controller: _valeurEtalonController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bouton Retour en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF015CC0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'Retour',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.sp(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Attributs
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _AttributsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF015CC0),
      padding: spacing.custom(horizontal: 5, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _HeaderText('Classe d\'attribut', responsive),
          ),
          Expanded(flex: 2, child: _HeaderText('Attribut', responsive)),
          Expanded(flex: 1, child: _HeaderText('Valeur', responsive)),
          Expanded(flex: 1, child: _HeaderText('Unité', responsive)),
          Expanded(
            flex: 1,
            child: _HeaderText('Symbole de l\'unité', responsive),
          ),
          Expanded(flex: 1, child: _HeaderText('Valeur étalon', responsive)),
          Expanded(flex: 1, child: _HeaderText('État', responsive)),
          Expanded(flex: 1, child: _HeaderText('Vérifié', responsive)),
          Expanded(flex: 1, child: _HeaderText('Attribut MAJ', responsive)),
        ],
      ),
    );
  }

  Widget _HeaderText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontMontserrat,
        fontWeight: FontWeight.w600,
        fontSize: responsive.sp(10),
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Widget pour afficher une ligne d'attribut dans le tableau
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une ligne
/// Principe DRY: Réutilise le pattern de checkbox avec callback
class _AttributsRow extends StatelessWidget {
  final int index;
  final String classeAttribut;
  final String attribut;
  final String valeur;
  final String unite;
  final String symboleUnite;
  final String valeurEtalon;
  final String? selectedCheckbox;
  final Function(String) onCheckboxChanged;

  const _AttributsRow({
    required this.index,
    required this.classeAttribut,
    required this.attribut,
    required this.valeur,
    required this.unite,
    required this.symboleUnite,
    required this.valeurEtalon,
    required this.selectedCheckbox,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: index % 2 == 0 ? Colors.white : Colors.grey[100],
      padding: spacing.custom(horizontal: 5, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 1, child: _CellText(classeAttribut, responsive)),
          Expanded(flex: 2, child: _CellText(attribut, responsive)),
          Expanded(flex: 1, child: _CellText(valeur, responsive)),
          Expanded(flex: 1, child: _CellText(unite, responsive)),
          Expanded(flex: 1, child: _CellText(symboleUnite, responsive)),
          Expanded(flex: 1, child: _CellText(valeurEtalon, responsive)),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'etat',
              onTap: () => onCheckboxChanged('etat'),
            ),
          ),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'verifie',
              onTap: () => onCheckboxChanged('verifie'),
            ),
          ),
          Expanded(
            flex: 1,
            child: _RadioCheckboxCell(
              isSelected: selectedCheckbox == 'attributMaj',
              onTap: () => onCheckboxChanged('attributMaj'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _CellText(String text, Responsive responsive) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontRoboto,
        color: AppTheme.secondaryColor,
        fontSize: responsive.sp(10),
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Widget pour afficher une checkbox cliquable (comportement radio button)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage et le clic d'une checkbox
/// Principe DRY: Réutilisable pour toutes les checkboxes du tableau
class _RadioCheckboxCell extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioCheckboxCell({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        child: Icon(
          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
          color: isSelected ? const Color(0xFF015CC0) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

/// Widget qui affiche un champ de formulaire avec ou sans dropdown
/// Principe SOLID: Single Responsibility - Responsable uniquement de l'affichage d'un champ
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final VoidCallback? onDropdownTap;

  const _FormField({
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label du champ en bleu
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF015CC0), // Bleu
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Champ de saisie avec icône dropdown ou calendrier
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly:
                      isDateField, // Seul le champ date est en lecture seule
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E), // Gris clair pour la valeur
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onTap: isDateField ? () => _selectDate(context) : null,
                ),
              ),
              if (isDateField)
                InkWell(
                  onTap: () => _selectDate(context),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF015CC0),
                    size: 20,
                  ),
                )
              else if (hasDropdown)
                InkWell(
                  onTap: onDropdownTap ?? () => _showDropdownOptions(context),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF015CC0),
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF015CC0), // Couleur bleue
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _showDropdownOptions(BuildContext context) {
    // Pour l'instant, affiche un message simple
    // Plus tard, on pourra afficher une liste de choix spécifiques
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF015CC0),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Options à venir...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
