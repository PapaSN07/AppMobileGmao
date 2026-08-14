import 'package:flutter/material.dart';

/// =====================================================================
/// MODULE DI (Demandes d'Intervention) - SAUVEGARDE DU CODE D'ORIGINE
/// Pour réactiver l'écran complet d'origine, supprimez les commentaires /* ... */
/// =====================================================================

class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demandes d'Intervention (DI)"),
        backgroundColor: const Color(0xFF0F1B80),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined, size: 72, color: Color(0xFF0F1B80)),
              SizedBox(height: 20),
              Text(
                "Module en Maintenance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F1B80)),
              ),
              SizedBox(height: 10),
              Text(
                "Cette fonctionnalité est actuellement en cours de développement par l'équipe dédiée.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =====================================================================
CODE D'ORIGINE COMPLET DE DI_SCREEN (CONSERVÉ EN BACKUP) :
========================================================================
import 'package:appmobilegmao/models/work_request.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/screens/di/di_detail_screen.dart';
import 'package:appmobilegmao/screens/di/di_create_screen.dart';
import 'package:appmobilegmao/widgets/list_item.dart';

class DiScreen extends StatefulWidget {
  const DiScreen({super.key});

  @override
  State<DiScreen> createState() => _DiScreenState();
}

class _DiScreenState extends State<DiScreen> {
  late List<WorkRequest> _allRequests;
  late List<WorkRequest> _filteredRequests;
  String _searchQuery = '';
  String _selectedStatusFilter = 'TOUT';

  @override
  void initState() {
    super.initState();
    _allRequests = WorkRequest.getMockData();
    _filteredRequests = List.from(_allRequests);
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((req) {
        final matchesSearch = req.dinqCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            req.dinqEquipment.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            req.dinqEquipmentDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            req.dinqDescription.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _selectedStatusFilter == 'TOUT' ||
            (_selectedStatusFilter == 'CREEE' && req.dinqUserStatus.contains('Créée')) ||
            (_selectedStatusFilter == 'OT_CREE' && req.dinqUserStatus.contains('OT créé'));

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<WorkRequest>(
      context,
      MaterialPageRoute(builder: (context) => const DICreateScreen()),
    );

    if (result != null) {
      setState(() {
        _allRequests.insert(0, result);
        _applyFilters();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande d\'intervention ${result.dinqCode} créée avec succès (Simulation).'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  void _navigateToDetail(WorkRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIDetailScreen(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Demandes d\'Intervention (DI)',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B1D4C),
            fontSize: responsive.sp(18),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: spacing.custom(horizontal: 16, bottom: 12, top: 4),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher par code, équipement, panne...',
                    hintStyle: TextStyle(fontSize: responsive.sp(14)),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: spacing.custom(vertical: 8, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: spacing.medium),

                Row(
                  children: [
                    _FilterChip(
                      label: 'Tout',
                      isSelected: _selectedStatusFilter == 'TOUT',
                      onTap: () {
                        _selectedStatusFilter = 'TOUT';
                        _applyFilters();
                      },
                    ),
                    SizedBox(width: spacing.small),
                    _FilterChip(
                      label: 'Créées',
                      isSelected: _selectedStatusFilter == 'CREEE',
                      onTap: () {
                        _selectedStatusFilter = 'CREEE';
                        _applyFilters();
                      },
                    ),
                    SizedBox(width: spacing.small),
                    _FilterChip(
                      label: 'OT Créés',
                      isSelected: _selectedStatusFilter == 'OT_CREE',
                      onTap: () {
                        _selectedStatusFilter = 'OT_CREE';
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📊 Count & List
          Padding(
            padding: spacing.custom(horizontal: 16, top: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredRequests.length} Demande(s) d\'intervention trouvée(s)',
                style: TextStyle(
                  fontFamily: AppTheme.fontRoboto,
                  color: AppTheme.thirdColor,
                  fontSize: responsive.sp(14),
                ),
              ),
            ),
          ),

          Expanded(
            child: _filteredRequests.isEmpty
                ? Center(
                    child: Text(
                      'Aucune DI trouvée.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        color: Colors.grey,
                        fontSize: responsive.sp(16),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: spacing.custom(horizontal: 16, bottom: 80),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (context, index) {
                      final req = _filteredRequests[index];
                      return Padding(
                        padding: spacing.custom(bottom: 12),
                        child: ListItemCustom.intervention(
                          id: req.pkWorkRequest.toString(),
                          code: req.dinqCode,
                          famille: req.dinqPriority ?? 'NORMAL',
                          zone: req.dinqZone ?? '-',
                          entity: req.dinqActionEntity ?? '-',
                          unite: req.dinqRequestEntity ?? '-',
                          centre: req.dinqCostcentre ?? '-',
                          description: req.dinqDescription,
                          status: req.dinqUserStatus,
                          onDetailsTap: () => _navigateToDetail(req),
                          trailing: const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'di_screen_fab',
        onPressed: _navigateToCreate,
        backgroundColor: AppTheme.secondaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: responsive.sp(13),
          ),
        ),
      ),
    );
  }
}
*/