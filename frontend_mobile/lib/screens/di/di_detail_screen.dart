import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/di/new_diagnostic_screen.dart';

class DiDetailScreen extends StatefulWidget {
  final Map<String, dynamic> diData;

  const DiDetailScreen({super.key, required this.diData});

  @override
  State<DiDetailScreen> createState() => _DiDetailScreenState();
}

class _DiDetailScreenState extends State<DiDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(responsive.spacing(70)),
        child: AppBar(
          backgroundColor: AppTheme.secondaryColor,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(responsive.spacing(12)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: responsive.iconSize(18)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DÉTAIL DE LA DI',
                style: TextStyle(
                  fontFamily: AppTheme.fontMontserrat,
                  color: Colors.white,
                  fontSize: responsive.sp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Demande d\'Intervention',
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  color: Colors.white.withOpacity(0.8),
                  fontSize: responsive.sp(12),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: Container(
                margin: EdgeInsets.only(right: responsive.spacing(16)),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(12),
                  vertical: responsive.spacing(6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECCC), // Light orange/yellow
                  borderRadius: BorderRadius.circular(responsive.spacing(16)),
                ),
                child: Text(
                  '0 Créée',
                  style: TextStyle(
                    color: const Color(0xFFD97706), // Dark orange
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.sp(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: spacing.custom(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // N° de DI
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'N° de DI',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: responsive.sp(14),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildDropdownField(widget.diData['id'], responsive),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.medium),

                  // Description du problème
                  Text(
                    'Description du problème',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive.sp(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: spacing.small),
                  Container(
                    width: double.infinity,
                    padding: spacing.custom(all: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(responsive.spacing(8)),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Décharge partielle détectée sur le transformateur lors de l\'inspection ultrason périodique. Niveau de décharge anormalement élevé nécessitant une intervention rapide.',
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section Header
            Container(
              width: double.infinity,
              padding: spacing.custom(horizontal: 16, vertical: 12),
              color: const Color(0xFFE5E7EB), // Grey background
              child: Text(
                widget.diData['title'] ?? 'DECHARGE PARTIELLE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.sp(14),
                  color: Colors.black87,
                ),
              ),
            ),

            // Form Fields
            Padding(
              padding: spacing.custom(all: 16),
              child: Column(
                children: [
                  _buildFormRow('Demandeur', '6795', responsive, hasArrowUp: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Destinataire', 'UMP-DV', responsive, isYellow: true, hasArrowUp: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Date déclaration', '24/07/2026 13:41', responsive, isTextOnly: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Équipement', 'LM0308FAFROTRF1', responsive, hasArrowUp: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('', 'POSTE FANN FROBENIUS - TRANSFORM...', responsive, isTextOnly: true), // Subtitle equipment
                  SizedBox(height: spacing.small),
                  _buildFormRow('N° d\'OT', '', responsive, hasArrowUp: true, isDropdown: false),
                  SizedBox(height: spacing.small),
                  _buildFormRow('État OT', '', responsive),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Priorité', '', responsive, hasArrowUp: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Unité', 'UMP-DV', responsive, hasArrowUp: true),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Contrôleur', 'Contrôleur', responsive),
                  SizedBox(height: spacing.small),
                  _buildFormRow('Superviseur', '', responsive, hasArrowUp: true),
                  SizedBox(height: spacing.medium),

                  // Mails à notifier
                  Container(
                    width: double.infinity,
                    padding: spacing.custom(all: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue bg
                      borderRadius: BorderRadius.circular(responsive.spacing(8)),
                      border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mails à notifier',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          'cheikhouomar.dia@senelec.sn;papaamadou.niane@senelec.sn',
                          style: TextStyle(
                            fontSize: responsive.sp(13),
                            color: AppTheme.secondaryColor, // Blue text
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // TabBar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.secondaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.secondaryColor,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
                tabs: const [
                  Tab(text: 'PROBLÈME'),
                  Tab(text: 'PLUS'),
                  Tab(text: 'DIAGNOSTIC'),
                  Tab(text: 'COMBINÉ'),
                  Tab(text: 'REMARQUE DU LOT'),
                  Tab(text: 'HISTORIQUE'),
                  Tab(text: 'RÉPARTITIONS'),
                ],
              ),
            ),

            // Tab Content Area
            Container(
              color: Colors.transparent, // Background for the tab content area
              child: _buildTabContent(responsive, spacing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String text, Responsive responsive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(8)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(responsive.spacing(6)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(14),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: responsive.iconSize(20)),
        ],
      ),
    );
  }

  Widget _buildFormRow(String label, String value, Responsive responsive, {
    bool isYellow = false,
    bool hasArrowUp = false,
    bool isDropdown = true,
    bool isTextOnly = false,
  }) {
    final bgColor = isYellow ? const Color(0xFFFEF3C7) : Colors.grey[100]; // Light yellow or light grey
    final borderColor = isYellow ? const Color(0xFFFCD34D) : Colors.grey[300];
    final textColor = isYellow ? const Color(0xFFB45309) : Colors.black87;

    return Row(
      children: [
        if (label.isNotEmpty)
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: responsive.sp(13),
              ),
            ),
          )
        else
          Expanded(flex: 1, child: const SizedBox()), // Empty space if no label

        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: responsive.spacing(10)),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(responsive.spacing(6)),
              border: Border.all(color: borderColor!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: value.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      fontSize: responsive.sp(13),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isTextOnly)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasArrowUp)
                        Icon(Icons.north_east, color: Colors.grey[400], size: responsive.iconSize(16)),
                      if (hasArrowUp && isDropdown) SizedBox(width: responsive.spacing(4)),
                      if (isDropdown)
                        Icon(Icons.keyboard_arrow_down, color: isYellow ? const Color(0xFFD97706) : Colors.grey[400], size: responsive.iconSize(20)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocItem(String title, String date, Responsive responsive, {bool isSelected = false}) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent, // Light blue if selected
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: responsive.spacing(4)),
          Text(
            date,
            style: TextStyle(
              fontSize: responsive.sp(11),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Responsive responsive, ResponsiveSpacing spacing) {
    if (_tabController.index == 1) {
      // PLUS TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Column(
          children: [
            _buildSectionCard(
              'Planification',
              [
                _buildPlusRow('OT source', '2026284107', responsive),
                _buildPlusRow('Date début prévue', '24/07/2026', responsive, isYellow: true),
                _buildPlusRow('Date fin prévue', '24/07/2026', responsive, isYellow: true),
                _buildPlusRow('Date de création', '2026-01-10', responsive),
                _buildPlusRow('Date de début', '24/07/2026 13:37', responsive, isYellow: true),
                _buildPlusRow('Date de fin', '24/07/2026 13:37', responsive, isYellow: true),
                _buildPlusRow('Intervention', '0. Equipement', responsive),
                _buildPlusRow('Devis', '', responsive),
              ],
              responsive,
              spacing,
            ),
            _buildSectionCard(
              'Organisation',
              [
                _buildPlusRow('Centre de charges', 'DD303', responsive),
                _buildPlusRow('Courriel demandeur', 'papeamadou.mbaye@senelec.sn', responsive),
                _buildPlusRow('Zone', 'DAKAR — DAKAR', responsive),
                _buildPlusRow('Entité réalisation', 'SDDV', responsive, subtitle: 'SERVICE DE DISTRIBUTION DAKAR VILLE'),
                _buildPlusRow('Entité demande', 'SDDV', responsive, subtitle: 'SERVICE DE DISTRIBUTION DAKAR VILLE'),
              ],
              responsive,
              spacing,
            ),
            _buildSectionCard(
              'Équipement planifié',
              [
                _buildPlusRow('Code', 'LM0308FAFROTRF1', responsive),
                _buildPlusRow('Libellé', 'POSTE FANN FROBENIUS - TRANSFORMATEUR', responsive),
              ],
              responsive,
              spacing,
            ),
          ],
        ),
      );
    } else if (_tabController.index == 2) {
      // DIAGNOSTIC TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: spacing.custom(all: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewDiagnosticScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      child: Container(
                        padding: spacing.custom(all: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(responsive.spacing(8)),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: responsive.iconSize(20)),
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: Text(
                        'Tableau de diagnostic',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.sp(14),
                        ),
                      ),
                    ),
                    Text(
                      '0 lignes',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: responsive.sp(13),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Table Area
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      color: AppTheme.secondaryColor,
                      child: Row(
                        children: [
                          _buildScrollableTableHeaderCol('Symptôme', responsive),
                          _buildScrollableTableHeaderCol('Desc. symptôme', responsive),
                          _buildScrollableTableHeaderCol('Défaut', responsive),
                          _buildScrollableTableHeaderCol('Desc. défaut', responsive),
                          _buildScrollableTableHeaderCol('Cause', responsive),
                          _buildScrollableTableHeaderCol('Desc. cause', responsive),
                          _buildScrollableTableHeaderCol('Remède', responsive),
                          _buildScrollableTableHeaderCol('Desc. remède', responsive, isLast: true),
                        ],
                      ),
                    ),
                    // Table Body (Empty State)
                    Container(
                      width: responsive.spacing(150) * 8, // 8 columns * 150 width
                      padding: spacing.custom(all: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Liste vide. Appuyer sur + pour ajouter une nouvelle ligne.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: responsive.sp(13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tabController.index == 5) {
      // HISTORIQUE TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: spacing.custom(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue
                  borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.spacing(12))),
                ),
                child: Text(
                  'Historique des états',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.sp(14),
                  ),
                ),
              ),
              // Scrollable Table Area
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      color: AppTheme.secondaryColor,
                      child: Row(
                        children: [
                          _buildScrollableTableHeaderCol('Date de la modification', responsive, hasIcon: false),
                          _buildScrollableTableHeaderCol('Ancien état', responsive, hasIcon: false),
                          _buildScrollableTableHeaderCol('Nouvel état', responsive, hasIcon: false),
                          _buildScrollableTableHeaderCol('Utilisateur', responsive, hasIcon: true),
                          _buildScrollableTableHeaderCol('Commentaires', responsive, hasIcon: true, isLast: true),
                        ],
                      ),
                    ),
                    // Table Row 1
                    Container(
                      width: responsive.spacing(150) * 5, // 5 columns
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: responsive.spacing(150),
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
                            child: Row(
                              children: [
                                Text('1', style: TextStyle(color: Colors.grey[500], fontSize: responsive.sp(13))),
                                SizedBox(width: responsive.spacing(8)),
                                Expanded(
                                  child: Text('24/07/2026 13:41', style: TextStyle(color: Colors.black87, fontSize: responsive.sp(13))),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: responsive.spacing(150),
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
                            child: Text('', style: TextStyle(color: Colors.black87, fontSize: responsive.sp(13))),
                          ),
                          Container(
                            width: responsive.spacing(150),
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
                            child: Text('0. Créée', style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: responsive.sp(13))),
                          ),
                          Container(
                            width: responsive.spacing(150),
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
                            child: Text('papeamadou.mbaye', style: TextStyle(color: Colors.black87, fontSize: responsive.sp(13))),
                          ),
                          Container(
                            width: responsive.spacing(150),
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
                            child: Text('', style: TextStyle(color: Colors.black87, fontSize: responsive.sp(13))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tabController.index == 3) {
      // COMBINÉ TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: spacing.custom(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue
                  borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.spacing(12))),
                ),
                child: Text(
                  'Combiné — DI liées',
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.sp(14),
                  ),
                ),
              ),
              // Scrollable Table Area
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      color: AppTheme.secondaryColor,
                      child: Row(
                        children: [
                          _buildScrollableTableHeaderCol('N° de DI', responsive),
                          _buildScrollableTableHeaderCol('Demandeur', responsive),
                          _buildScrollableTableHeaderCol('Éqpt / grp planifié', responsive),
                          _buildScrollableTableHeaderCol('N° d\'OT', responsive),
                          _buildScrollableTableHeaderCol('Date de début prévue', responsive),
                          _buildScrollableTableHeaderCol('Date de fin', responsive),
                          _buildScrollableTableHeaderCol('Intervention', responsive, isLast: true),
                        ],
                      ),
                    ),
                    // Table Body (Empty State)
                    Container(
                      width: responsive.spacing(150) * 7, // 7 columns * 150 width
                      padding: spacing.custom(all: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Aucune donnée à afficher',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: responsive.sp(13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tabController.index == 4) {
      // REMARQUE DU LOT TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Container(
          height: responsive.spacing(250),
          child: TextField(
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Saisir une remarque de lot...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: responsive.sp(13),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding: spacing.custom(all: 16),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      );
    } else if (_tabController.index == 6) {
      // RÉPARTITIONS TAB
      return Padding(
        padding: spacing.custom(all: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              Container(
                padding: spacing.custom(all: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.spacing(12))),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, color: Colors.grey[600], size: responsive.iconSize(20)),
                    SizedBox(width: spacing.small),
                    Icon(Icons.chevron_right, color: Colors.grey[600], size: responsive.iconSize(20)),
                    SizedBox(width: spacing.medium),
                    GestureDetector(
                      onTap: () => _showErrorDialog(context, responsive),
                      child: Container(
                        padding: spacing.custom(all: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(responsive.spacing(4)),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: responsive.iconSize(16)),
                      ),
                    ),
                    SizedBox(width: spacing.small),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(4)),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(responsive.spacing(4)),
                      ),
                      child: Text('Sauv.', style: TextStyle(color: Colors.grey[700], fontSize: responsive.sp(12))),
                    ),
                    SizedBox(width: spacing.medium),
                    Icon(Icons.insert_drive_file_outlined, color: Colors.grey[600], size: responsive.iconSize(16)),
                    SizedBox(width: spacing.small),
                    Icon(Icons.warning_amber_rounded, color: Colors.grey[600], size: responsive.iconSize(16)),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: spacing.custom(all: 16),
                child: Column(
                  children: [
                    _buildRepartitionsRow('Index', responsive, hasDropdown: false, isTextOnly: true),
                    SizedBox(height: spacing.small),
                    _buildRepartitionsRow('Équipement', responsive),
                    SizedBox(height: spacing.small),
                    _buildRepartitionsRow('Intervention', responsive),
                    SizedBox(height: spacing.small),
                    _buildRepartitionsRow('État de lancement', responsive, hasArrowUp: false),
                    SizedBox(height: spacing.small),
                    _buildRepartitionsRow('État réception', responsive, hasArrowUp: false),
                    SizedBox(height: spacing.small),
                    _buildRepartitionsRow('N° d\'OT', responsive, extraText: 'État OT util.'),
                  ],
                ),
              ),
              // Sub-tabs
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16), vertical: responsive.spacing(12)),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.secondaryColor, width: 2)),
                      ),
                      child: Text(
                        'REMARQUES',
                        style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16), vertical: responsive.spacing(12)),
                      child: Text(
                        'COMMENTAIRES OT',
                        style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
                      ),
                    ),
                  ],
                ),
              ),
              // Remarks textarea
              Container(
                height: responsive.spacing(120),
                padding: spacing.custom(all: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saisir une remarque...', style: TextStyle(color: Colors.grey[400], fontSize: responsive.sp(13))),
                    const Spacer(),
                    Icon(Icons.attach_file, color: Colors.grey[400], size: responsive.iconSize(18)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default Tab (PROBLÈME)
    return Container(
      height: responsive.spacing(350), // Fixed height for split view
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side (Text Area)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: responsive.spacing(3), color: Colors.blue),
                            Expanded(
                              child: TextField(
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: 'Décrire le problème...',
                                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: responsive.sp(13)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(responsive.spacing(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Paperclip icon
                        Positioned(
                          left: -responsive.spacing(8),
                          top: responsive.spacing(120),
                          child: Container(
                            padding: EdgeInsets.all(responsive.spacing(4)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                              ],
                            ),
                            child: Icon(Icons.attach_file, color: Colors.grey[500], size: responsive.iconSize(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer with pencil
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    alignment: Alignment.bottomLeft,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: EdgeInsets.all(responsive.spacing(8)),
                        child: Icon(Icons.edit_outlined, color: Colors.grey[400], size: responsive.iconSize(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right side (Documents)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(8)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.insert_drive_file_outlined, size: responsive.iconSize(16), color: Colors.grey[600]))),
                        SizedBox(width: responsive.spacing(4)),
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.add, size: responsive.iconSize(16), color: Colors.grey[600]))),
                        SizedBox(width: responsive.spacing(4)),
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.delete_outline, size: responsive.iconSize(16), color: Colors.grey[600]))),
                        SizedBox(width: responsive.spacing(4)),
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.copy_outlined, size: responsive.iconSize(16), color: Colors.grey[600]))),
                        SizedBox(width: responsive.spacing(4)),
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.download_outlined, size: responsive.iconSize(16), color: Colors.grey[600]))),
                        SizedBox(width: responsive.spacing(4)),
                        InkWell(onTap: () {}, child: Padding(padding: EdgeInsets.all(responsive.spacing(4)), child: Icon(Icons.info_outline, size: responsive.iconSize(16), color: Colors.grey[600]))),
                      ],
                    ),
                  ),
                  // List of documents
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildDocItem('0029 RAPPORT ULTRASON du Je...', '23/07/2026', responsive, isSelected: true),
                        _buildDocItem('PD SCAN 0029 du Jeudi 23 Juille...', '23/07/2026', responsive),
                      ],
                    ),
                  ),
                  // Footer with pencil
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    alignment: Alignment.bottomLeft,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: EdgeInsets.all(responsive.spacing(8)),
                        child: Icon(Icons.edit_outlined, color: Colors.grey[400], size: responsive.iconSize(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: spacing.custom(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Light blue
              borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.spacing(12))),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: responsive.sp(14),
              ),
            ),
          ),
          // Body
          Padding(
            padding: spacing.custom(all: 16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusRow(String label, String value, Responsive responsive, {bool isYellow = false, String? subtitle}) {
    final bgColor = isYellow ? const Color(0xFFFEF3C7) : Colors.grey[100];
    final borderColor = isYellow ? const Color(0xFFFCD34D) : Colors.grey[300];
    final textColor = isYellow ? const Color(0xFFB45309) : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: responsive.spacing(10)),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: responsive.sp(12), // slightly smaller to match
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: value.isEmpty ? responsive.spacing(4) : responsive.spacing(10)),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(responsive.spacing(6)),
                border: Border.all(color: borderColor!),
              ),
              child: value.isEmpty && label == 'Devis'
                  ? SizedBox(height: responsive.spacing(12)) // Empty box for Devis
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: responsive.sp(13),
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: responsive.spacing(4)),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: responsive.sp(11),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCol(String text, Responsive responsive, {int flex = 1, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
        decoration: BoxDecoration(
          border: isLast ? null : Border(right: BorderSide(color: Colors.white.withOpacity(0.3))),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.white, size: responsive.iconSize(12)), // Placeholder icon
            SizedBox(width: responsive.spacing(4)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.sp(12),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepartitionsRow(String label, Responsive responsive, {bool hasArrowUp = true, bool hasDropdown = true, bool isTextOnly = false, String? extraText}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: responsive.sp(12))),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: responsive.spacing(32),
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8)),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(responsive.spacing(6)),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasArrowUp && !isTextOnly) Icon(Icons.north_east, color: Colors.grey[400], size: responsive.iconSize(14)),
                      if (hasArrowUp && hasDropdown && !isTextOnly) SizedBox(width: responsive.spacing(4)),
                      if (hasDropdown && !isTextOnly) Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: responsive.iconSize(16)),
                    ],
                  ),
                ),
              ),
              if (extraText != null) ...[
                SizedBox(width: responsive.spacing(4)),
                Text(extraText, style: TextStyle(color: Colors.grey[500], fontSize: responsive.sp(10))),
                SizedBox(width: responsive.spacing(4)),
              ] else ...[
                SizedBox(width: responsive.spacing(8)),
              ],
              Expanded(
                flex: 2,
                child: Container(
                  height: responsive.spacing(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(responsive.spacing(6)),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, Responsive responsive) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.spacing(12))),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.all(responsive.spacing(20)),
          title: Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(4)),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.priority_high, color: Colors.red, size: responsive.iconSize(16)),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Text(
                      'Erreur',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.sp(16),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[500], size: responsive.iconSize(18)),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontFamily: AppTheme.fontRoboto, color: Colors.black87, fontSize: responsive.sp(13)),
                  children: [
                    TextSpan(text: 'Code erreur : ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '30715588', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'Vous ne pouvez pas ajouter de répartition car la DI est spécifiée comme "Sans répartition".',
                style: TextStyle(color: Colors.black87, fontSize: responsive.sp(13)),
              ),
              SizedBox(height: responsive.spacing(24)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'COPIER LA PILE',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: responsive.iconSize(16)),
                        SizedBox(width: responsive.spacing(4)),
                        Text(
                          'OK',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollableTableHeaderCol(String text, Responsive responsive, {bool isLast = false, bool hasIcon = true}) {
    return Container(
      width: responsive.spacing(150),
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(12)),
      decoration: BoxDecoration(
        border: isLast ? null : Border(right: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          if (hasIcon) ...[
            Icon(Icons.not_interested, color: Colors.white, size: responsive.iconSize(14)),
            SizedBox(width: responsive.spacing(4)),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: responsive.sp(12)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
