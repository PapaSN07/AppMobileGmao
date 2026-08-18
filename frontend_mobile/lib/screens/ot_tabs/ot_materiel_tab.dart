import 'package:flutter/material.dart';
import 'ot_shared_widgets.dart';
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

/// Onglet "Matériel" - Affiche la liste du matériel utilisé avec sous-onglets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du matériel
/// Principe DRY: Réutilise le pattern TabController comme _MainsOeuvreTab
class MaterielTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const MaterielTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<MaterielTab> createState() => MaterielTabState();
}

class MaterielTabState extends State<MaterielTab>
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
        MaterielTabBar(tabController: _tabController),
        // Contenu des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet MOYENS
              _MoyensTab(otCode: widget.otCode, otService: widget.otService),
              // Onglet STOCK (avec sous-onglets Pièces et Services)
              _StockTab(otCode: widget.otCode, otService: widget.otService),
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
class MaterielTabBar extends StatelessWidget {
  final TabController tabController;

  const MaterielTabBar({required this.tabController});

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
  final String otCode;
  final OTService otService;

  const _StockTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

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
              _StockPiecesTab(otCode: widget.otCode, otService: widget.otService),
              // Sous-onglet SERVICES
              _StockServicesTab(otCode: widget.otCode, otService: widget.otService),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre de sous-onglets Stock (Pièces / Services)
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage des sous-onglets
/// Principe DRY: Réutilise le pattern de _StockSubTabBar
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
          color: const Color(0xFF0F1B80),
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

/// Onglet MOYENS - Affiche le tableau des moyens depuis les API réelles
class _MoyensTab extends StatefulWidget {
  final String otCode;
  final OTService otService;

  const _MoyensTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_MoyensTab> createState() => _MoyensTabState();
}

class _MoyensTabState extends State<_MoyensTab> {
  bool _showDetails = false;

  Map<String, dynamic>? _selectedMoyen;

  void _toggleDetails([Map<String, dynamic>? moyen]) {
    setState(() {
      _selectedMoyen = moyen;
      _showDetails = !_showDetails;
    });
  }

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_showDetails) {
      return _MoyensDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedMoyen,
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: widget.otService.getMoyens(widget.otCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.commute, size: 64, color: Color(0xFF0F1B80)),
                SizedBox(height: 16),
                Text('Aucun moyen utilisé pour cet OT', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: [
            MaterielActionBar(onAddTap: () => _toggleDetails(list.isNotEmpty ? list.first : null)),
            SizedBox(height: spacing.small),
            _MoyensTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item         = list[index];
                  final moyen        = item['wofuFacility']?.toString() ?? '';
                  final equipement   = item['wofuEquipment']?.toString() ?? item['reemDescription']?.toString() ?? moyen;
                  final dateDebut    = _formatDate(item['wofuStartDate'] ?? item['wofuAllocationDate'] ?? '');
                  final tempsUtilise = item['wofuDuration']?.toString() ?? item['wofuQuantity']?.toString() ?? '0.00';
                  final dateFin      = _formatDate(item['wofuEndDate'] ?? '');

                  return GestureDetector(
                    onTap: () => _toggleDetails(item),
                    behavior: HitTestBehavior.opaque,
                    child: _MoyensRow(
                      index: index,
                      moyen: moyen,
                      equipement: equipement,
                      dateDebut: dateDebut.isNotEmpty ? dateDebut : '-',
                      tempsUtilise: tempsUtilise,
                      dateFin: dateFin.isNotEmpty ? dateFin : '-',
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


/// Widget pour afficher le formulaire de détails des moyens
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du formulaire
/// Principe DRY: Réutilise EmployeFormField
class _MoyensDetailsTab extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const _MoyensDetailsTab({required this.onBack, this.initialData});

  @override
  State<_MoyensDetailsTab> createState() => _MoyensDetailsTabState();
}

class _MoyensDetailsTabState extends State<_MoyensDetailsTab> {
  late TextEditingController _moyenController;
  late TextEditingController _equipementController;
  late TextEditingController _dateDebutController;
  late TextEditingController _tempsUtiliseController;
  late TextEditingController _dateFinController;

  String _formatDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return s.replaceAll('T', ' ').substring(0, s.length > 16 ? 16 : s.length);
  }

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    final moyen        = data?['wofuFacility']?.toString() ?? '';
    final equipement   = data?['reemDescription']?.toString() ?? moyen;
    final dateDebut    = _formatDate(data?['wofuStartDate'] ?? data?['wofuAllocationDate'] ?? '');
    final tempsUtilise = data?['wofuDuration']?.toString() ?? data?['wofuQuantity']?.toString() ?? '0.00';
    final dateFin      = _formatDate(data?['wofuEndDate'] ?? '');

    _moyenController = TextEditingController(text: moyen.isNotEmpty ? moyen : 'VEHICULE');
    _equipementController = TextEditingController(text: equipement.isNotEmpty ? equipement : 'AA-555-BA');
    _dateDebutController = TextEditingController(text: dateDebut.isNotEmpty ? dateDebut : '21/10/2025 07:30');
    _tempsUtiliseController = TextEditingController(text: tempsUtilise);
    _dateFinController = TextEditingController(text: dateFin.isNotEmpty ? dateFin : '21/10/2025 07:30');
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF0F1B80)),
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
                MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Moyen et Équipement
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Moyen',
                        controller: _moyenController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
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
                      child: EmployeFormField(
                        label: 'Date de début',
                        controller: _dateDebutController,
                        isDateField: true,
                        onDateTap: _selectDateDebut,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
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
                      child: EmployeFormField(
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
        ),
      ],
    );
  }
}

/// Widget pour afficher la barre d'actions en haut de l'onglet Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de la barre d'actions
/// Principe DRY: Réutilise le pattern ActionIconButton
class MaterielActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const MaterielActionBar({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
      color: const Color(0xFF0F1B80),
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
  final String otCode;
  final OTService otService;

  const _StockPiecesTab({Key? key, required this.otCode, required this.otService}) : super(key: key);

  @override
  State<_StockPiecesTab> createState() => _StockPiecesTabState();
}

class _StockPiecesTabState extends State<_StockPiecesTab> {
  bool _showDetails = false;
  List<Map<String, dynamic>> pieces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    try {
      final list = await widget.otService.getParts(widget.otCode);
      setState(() {
        pieces = list.map((item) {
          final partCode = item['wosyPart']?.toString()
              ?? item['wosyCode']?.toString()
              ?? item['stockPart']?.toString()
              ?? '';
          final description = item['wosyDescription']?.toString()
              ?? item['partDescription']?.toString()
              ?? partCode;
          final label = description.isNotEmpty ? description : partCode;
          final qty = item['wosyUsedQuantity']?.toString()
              ?? item['wosyQuantity']?.toString()
              ?? item['usedQuantity']?.toString()
              ?? '0';
          return {
            'pk': (item['pkPart'] ?? item['pkStockUsed'] ?? 0) as int,
            'partCode': partCode,
            'article': label.isNotEmpty ? label : 'Article',
            'quantiteUtilise': qty,
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

  Map<String, dynamic>? _selectedPiece;

  void _toggleDetails([Map<String, dynamic>? piece]) {
    setState(() {
      _selectedPiece = piece;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_showDetails) {
      return _StockPiecesDetailsTab(
        otCode: widget.otCode,
        otService: widget.otService,
        onBack: () => _toggleDetails(null),
        onSaved: _loadParts,
        initialData: _selectedPiece,
      );
    }

    return Column(
      children: [
        MaterielActionBar(onAddTap: () => _toggleDetails(null)),
        SizedBox(height: spacing.small),
        _StockPiecesTableHeader(),
        Expanded(
          child: pieces.isEmpty
              ? const Center(child: Text('Aucune pièce de rechange pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: pieces.length,
                  itemBuilder: (context, index) {
                    final piece = pieces[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(piece),
                      behavior: HitTestBehavior.opaque,
                      child: _StockPiecesRow(
                        index: index,
                        article: piece['article'] ?? '',
                        quantiteUtilise: piece['quantiteUtilise'] ?? '0.00',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StockPiecesDetailsTab extends StatefulWidget {
  final String otCode;
  final OTService otService;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final Map<String, dynamic>? initialData;

  const _StockPiecesDetailsTab({
    required this.otCode,
    required this.otService,
    required this.onBack,
    required this.onSaved,
    this.initialData,
  });

  @override
  State<_StockPiecesDetailsTab> createState() => _StockPiecesDetailsTabState();
}

class _StockPiecesDetailsTabState extends State<_StockPiecesDetailsTab> {
  late TextEditingController _partCodeController;
  late TextEditingController _articleController;
  late TextEditingController _quantiteUtiliseController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _partCodeController = TextEditingController(text: data?['partCode'] ?? '');
    _articleController = TextEditingController(text: data?['article'] ?? '');
    _quantiteUtiliseController = TextEditingController(text: data?['quantiteUtilise'] ?? '1.0');
  }

  @override
  void dispose() {
    _partCodeController.dispose();
    _articleController.dispose();
    _quantiteUtiliseController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final partCode = _partCodeController.text.trim();
    final article = _articleController.text.trim();
    final qty = double.tryParse(_quantiteUtiliseController.text) ?? 1.0;

    if (partCode.isEmpty || article.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le code article et la description.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.initialData == null) {
        // Ajouter
        await widget.otService.createPart(widget.otCode, {
          "wosyPart": partCode,
          "wosyCode": partCode,
          "wosyDescription": article,
          "wosyUsedQuantity": qty,
          "wosyQuantity": qty,
          "wosyUnit": "U",
        });
      } else {
        // Modifier
        final pk = widget.initialData!['pk'] as int;
        await widget.otService.updatePart(widget.otCode, pk, {
          "wosyPart": partCode,
          "wosyCode": partCode,
          "wosyDescription": article,
          "wosyUsedQuantity": qty,
          "wosyQuantity": qty,
          "wosyUnit": "U",
        });
      }
      widget.onSaved();
      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    final pk = widget.initialData!['pk'] as int;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la pièce'),
          content: const Text('Voulez-vous retirer cette pièce de rechange de l\'OT ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  await widget.otService.deletePart(widget.otCode, pk);
                  widget.onSaved();
                  widget.onBack();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e')));
                } finally {
                  setState(() => _isSaving = false);
                }
              },
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Code Article *',
                        controller: _partCodeController,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
                        label: 'Quantité utilisée *',
                        controller: _quantiteUtiliseController,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.medium),
                EmployeFormField(
                  label: 'Description Article *',
                  controller: _articleController,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ),

        // Actions en bas
        Container(
          color: Colors.white,
          padding: spacing.custom(horizontal: 20, vertical: 10, bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: responsive.hp(1.8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Retour',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.sp(14),
                    ),
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

/// Widget pour afficher l'en-tête du tableau Stock/Pièces
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class _StockPiecesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
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
  final String otCode;
  final OTService otService;

  const _StockServicesTab({required this.otCode, required this.otService});

  @override
  State<_StockServicesTab> createState() => _StockServicesTabState();
}

class _StockServicesTabState extends State<_StockServicesTab> {
  bool _showDetails = false;
  List<Map<String, dynamic>> services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final list = await widget.otService.getServices(widget.otCode);
      setState(() {
        services = list.map((item) {
          final serviceCode = item['woseService']?.toString()
              ?? item['woseCode']?.toString()
              ?? item['service']?.toString()
              ?? '';
          final description = item['woseDescription']?.toString()
              ?? item['serviceDescription']?.toString()
              ?? serviceCode;
          final label = description.isNotEmpty ? description : serviceCode;
          
          final qtyPlan = item['wosePlannedQuantity']?.toString()
              ?? item['woseQuantity']?.toString()
              ?? item['wosePlannedTime']?.toString()
              ?? '0.00';
              
          final qtyCons = item['woseUsedQuantity']?.toString()
              ?? item['woseActualQuantity']?.toString()
              ?? item['woseActualTime']?.toString()
              ?? qtyPlan;
          
          return {
            'article': label.isNotEmpty ? label : 'Service',
            'quantitePlanifiee': qtyPlan,
            'quantiteConsommee': qtyCons,
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

  Map<String, dynamic>? _selectedService;

  void _toggleDetails([Map<String, dynamic>? service]) {
    setState(() {
      _selectedService = service;
      _showDetails = !_showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F1B80)));
    }
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_showDetails) {
      return _StockServicesDetailsTab(
        onBack: () => _toggleDetails(null),
        initialData: _selectedService,
      );
    }

    return Column(
      children: [
        // Barre d'icônes d'action
        MaterielActionBar(onAddTap: () => _toggleDetails(services.isNotEmpty ? services.first : null)),
        SizedBox(height: spacing.small),
        // En-tête du tableau
        _StockServicesTableHeader(),
        // Liste des services
        Expanded(
          child: services.isEmpty
              ? const Center(child: Text('Aucun service pour cet OT', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return GestureDetector(
                      onTap: () => _toggleDetails(service),
                      behavior: HitTestBehavior.opaque,
                      child: _StockServicesRow(
                        index: index,
                        article: service['article'] ?? '',
                        quantitePlanifiee: service['quantitePlanifiee'] ?? '0.00',
                        quantiteConsommee: service['quantiteConsommee'] ?? '0.00',
                      ),
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
/// Principe DRY: Réutilise EmployeFormField
class _StockServicesDetailsTab extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? initialData;

  const _StockServicesDetailsTab({required this.onBack, this.initialData});

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
    final data = widget.initialData;
    _articleController = TextEditingController(text: data?['article'] ?? 'SERVICE');
    _quantitePlanifieeController = TextEditingController(text: data?['quantitePlanifiee'] ?? '0.00');
    _quantiteConsommeeController = TextEditingController(text: data?['quantiteConsommee'] ?? '0.00');
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
                MaterielActionBar(onAddTap: () {}),
                SizedBox(height: spacing.large),

                // Ligne 1: Article et Quantité planifiée
                Row(
                  children: [
                    Expanded(
                      child: EmployeFormField(
                        label: 'Article',
                        controller: _articleController,
                        hasDropdown: true,
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: EmployeFormField(
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
                      child: EmployeFormField(
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
      color: const Color(0xFF0F1B80),
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
/// Principe DRY: Réutilise le pattern ActionIconButton
class MaterielActionBarOld extends StatelessWidget {
  final VoidCallback onAddTap;

  const MaterielActionBarOld({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Container(
      color: Colors.grey[200],
      padding: spacing.custom(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ActionIconButton(icon: Icons.add, onPressed: onAddTap),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.refresh, onPressed: () {}),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.check, onPressed: () {}),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.close, onPressed: () {}),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.insert_chart, onPressed: () {}),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.view_module, onPressed: () {}),
          SizedBox(width: spacing.small),
          ActionIconButton(icon: Icons.help_outline, onPressed: () {}),
        ],
      ),
    );
  }
}

/// Widget pour afficher l'en-tête du tableau Matériel
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage de l'en-tête
class MaterielTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final responsive = context.responsive;

    return Container(
      color: const Color(0xFF0F1B80),
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

