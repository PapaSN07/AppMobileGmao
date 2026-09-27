import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/services/ot_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';

/// Onglet "Mains d'œuvre" - Affiche la liste des employés affectés avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des mains d'œuvre
class MainsOeuvreTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const MainsOeuvreTab({super.key, required this.otCode, required this.otService});

  @override
  State<MainsOeuvreTab> createState() => MainsOeuvreTabState();
}

class MainsOeuvreTabState extends State<MainsOeuvreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> employes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadWorkforce();
  }

  Future<void> _loadWorkforce() async {
    try {
      final list = await widget.otService.getWorkforce(widget.otCode);
      setState(() {
        employes = list.map((item) {
          final isPlanned = item['woeaIsPlanned'] == true ? 'Planifié' : 'Non planifié';
          return {
            'pk':               (item['pkWorkforce'] ?? item['pkEmployeeAllocated'] ?? 0) as int,
            'employe':          item['reemCode']?.toString() ?? item['woeaEmployee']?.toString() ?? '',
            'description':      item['reemDescription']?.toString() ?? item['woeaResource']?.toString() ?? 'Intervenant',
            'dateDebut':        _formatDate(item['woeaAllocationDate']),
            'dateFin':          '',
            'heuresRealisees':  '0',
            'etatOT':           isPlanned,
            'ressource':        item['woeaResource']?.toString() ?? 'RDEF',
            'heuresPlanifiees': item['woeaPlannedHours']?.toString() ?? '0',
            'heuresJour':       '0',
            'taux':             'Taux normal',
            'etatRejet':        item['woeaQualifRejection']?.toString()
                               ?? item['woeaQualificationRejection']?.toString()
                               ?? item['woeaQualifRej']?.toString()
                               ?? '',
            'aPermis':          item['woeaWorkPermit']?.toString()
                               ?? item['woeaPermit']?.toString()
                               ?? item['woeaHasPermit']?.toString()
                               ?? '',
            'sequence':         item['woeaSequence']?.toString()
                               ?? item['woeaSeq']?.toString()
                               ?? item['woeaSequenceNumber']?.toString()
                               ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }




  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    return Column(
      children: [
        _MainsOeuvreActionBar(),
        ActionSearchBar(),
        MainsOeuvreTabBar(tabController: _tabController),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _IntervenantsContent(
                employes: employes,
              ),
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
class MainsOeuvreTabBar extends StatelessWidget {
  final TabController tabController;

  const MainsOeuvreTabBar({super.key, required this.tabController});

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
          color: const Color(0xFF0F1B80),
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
        // Corps du tableau avec liste d'employés (lecture seule)
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

  Map<String, dynamic>? _selectedEmployee;

  void _toggleDetails([Map<String, dynamic>? employee]) {
    setState(() {
      _selectedEmployee = employee;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_showDetails) {
      // Affiche le formulaire de détails avec les données de l'employé sélectionné
      return _EmployesAllouesDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedEmployee,
      );
    }

    // Affiche directement le tableau des employés alloués (image fournie)
    return Column(
      children: [
        // En-tête du tableau avec toutes les colonnes
        _EmployesAllouesTableHeader(),

        // Liste scrollable des employés
        Expanded(
          child: widget.employes.isEmpty
              ? const Center(child: Text('Aucun employé alloué pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.employes.length,
                  itemBuilder: (context, index) {
                    final employe = widget.employes[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(employe),
                      behavior: HitTestBehavior.opaque,
                      child: _EmployesAllouesRow(
                        index: index + 1,
                        employe: employe['employe'] ?? '',
                        description: employe['description'] ?? '',
                        dateAllocation: employe['dateDebut'] ?? '',
                        heuresAllouees: employe['heuresPlanifiees'] ?? '0',
                        etatAllocation: employe['etatOT'] ?? '0. Non réalisé',
                        etatRejet: '0. Pas d\'objection',
                        aPermis: '0. Non',
                        numeroSequence: '',
                      ),
                    );
                  },
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
  final Map<String, dynamic>? initialData;

  const _EmployesAllouesDetailsTab({required this.onBack, this.initialData});

  @override
  State<_EmployesAllouesDetailsTab> createState() =>
      _EmployesAllouesDetailsTabState();
}

class _EmployesAllouesDetailsTabState
    extends State<_EmployesAllouesDetailsTab> {
  // Contrôleurs pour les champs du formulaire
  late TextEditingController _employeController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateAllocationController;
  late TextEditingController _heuresAlloueesController;
  late TextEditingController _etatAllocationController;
  late TextEditingController _etatRejetController;
  late TextEditingController _aPermisController;
  late TextEditingController _numeroSequenceController;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final currentUser = HiveService.getCurrentUser();
    
    // Initialisation des contrôleurs avec données réelles si disponibles, sinon exemples
    _employeController = TextEditingController(
      text: data != null ? '${data['employe']}' : currentUser?.code ?? "5893",
    );
    _descriptionController = TextEditingController(
      text: data != null ? (data['description']?.toString() ?? '') : (currentUser?.username ?? 'Intervenant'),
    );
    _dateAllocationController = TextEditingController(
      text: data != null ? (data['dateDebut']?.toString() ?? '') : '22/10/2025 07:30',
    );
    _heuresAlloueesController = TextEditingController(
      text: data != null ? (data['heuresPlanifiees']?.toString() ?? '0') : '3.00',
    );
    _etatAllocationController = TextEditingController(
      text: data != null ? (data['etatOT']?.toString() ?? '0. Non réalisé') : '0. Non réalisé',
    );
    _etatRejetController = TextEditingController(
      text: data != null && data['etatRejet'] != null ? data['etatRejet'].toString() : '',
    );
    _aPermisController = TextEditingController(
      text: data != null && data['aPermis'] != null ? data['aPermis'].toString() : '',
    );
    _numeroSequenceController = TextEditingController(
      text: data != null && data['sequence'] != null ? data['sequence'].toString() : '',
    );
  }

  @override
  void dispose() {
    _employeController.dispose();
    _descriptionController.dispose();
    _dateAllocationController.dispose();
    _heuresAlloueesController.dispose();
    _etatAllocationController.dispose();
    _etatRejetController.dispose();
    _aPermisController.dispose();
    _numeroSequenceController.dispose();
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
                // Barre d'icônes d'action (similaire à l'image)
                _EmployesAllouesActionBar(),
                SizedBox(height: spacing.large),

                // Ligne 1: Employé et Description de l'employé
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Employé',
                        controller: _employeController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Description de l\'employé (Auto)',
                        controller: _descriptionController,
                        readOnly: true,
                        backgroundColor: const Color(0xFFEEEEEE),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 2: Date d'allocation et Heures allouées
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Date d\'allocation',
                        controller: _dateAllocationController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Heures allouées',
                        controller: _heuresAlloueesController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 3: État de l'allocation et État de rejet de la qualification
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'État de l\'allocation',
                        controller: _etatAllocationController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'État de rejet de la qualification',
                        controller: _etatRejetController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),

                // Ligne 4: À des permis de travail
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'À des permis de travail',
                        controller: _aPermisController,
                        readOnly: true,
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
                      child: EmployeFormField(
                        label: 'N° de séquence',
                        controller: _numeroSequenceController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Action',
                        controller: TextEditingController(),
                        readOnly: true,
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
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextFormField(
                    readOnly: true,
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
        Builder(
          builder: (context) {
            final bottomInset = MediaQuery.of(context).viewPadding.bottom > 0
                ? MediaQuery.of(context).viewPadding.bottom
                : MediaQuery.of(context).padding.bottom;
            return Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: bottomInset + 14,
              ),
              child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1B80),
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
        );
      },
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
    return const SizedBox.shrink();
  }
}

/// Widget pour un champ de formulaire employé
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'un champ
/// Principe DRY: Réutilisable pour tous les champs du formulaire
class EmployeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final bool readOnly;
  final bool enabled;
  final Color? backgroundColor;
  final VoidCallback? onDateTap;
  final Function(String)? onChanged;

  const EmployeFormField({super.key, 
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

/// Widget pour afficher la barre d'actions en haut de l'onglet Mains d'œuvre
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions avec icônes
/// Principe DRY: Réutilise le pattern des autres barres d'action
class _MainsOeuvreActionBar extends StatelessWidget {
  const _MainsOeuvreActionBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Widget pour afficher une icône d'action cliquable
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage d'une icône d'action
/// Principe DRY: Réutilisable pour toutes les icônes d'action
class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ActionIconButton({super.key, required this.icon, required this.onPressed});

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
          color: const Color(0xFF0F1B80),
          size: responsive.iconSize(20),
        ),
      ),
    );
  }
}

/// Widget pour afficher la barre "Action" avec champ de recherche
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre de recherche
class ActionSearchBar extends StatelessWidget {
  const ActionSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
      color: const Color(0xFF0F1B80),
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
      color: const Color(0xFF0F1B80),
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

