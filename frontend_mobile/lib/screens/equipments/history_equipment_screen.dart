import 'package:appmobilegmao/models/historique_equipment.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:appmobilegmao/widgets/search_bar.dart' as custom;
import 'package:appmobilegmao/widgets/equipments/equipment_list.dart';
import 'package:appmobilegmao/widgets/equipments/history_equipment_item.dart';
import 'package:appmobilegmao/widgets/equipments/status_filter_buttons.dart';
import 'package:appmobilegmao/utils/responsive.dart'; // ✅ AJOUTÉ
import 'package:appmobilegmao/theme/responsive_spacing.dart'; // ✅ AJOUTÉ
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryEquipmentScreen extends StatefulWidget {
  const HistoryEquipmentScreen({super.key});

  @override
  State<HistoryEquipmentScreen> createState() => _HistoryEquipmentScreenState();
}

class _HistoryEquipmentScreenState extends State<HistoryEquipmentScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchType = 'all';
  String _statusFilter = 'in_progress';

  List<HistoriqueEquipment> _allHistorique = [];
  List<HistoriqueEquipment> _filteredHistorique = [];
  bool _isLoading = false;

  static const String __logName = 'HistoryEquipmentScreen -';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistorique();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  Future<void> _loadHistorique({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );
    final user = authProvider.currentUser;

    if (user == null || user.username.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('🚀 $__logName Chargement historique pour ${user.username}');
      }

      final historique = await equipmentProvider
          .loadHistoriqueEquipmentPrestataire(
            username: user.username,
            forceRefresh: forceRefresh,
          );

      setState(() {
        _allHistorique = historique;
        _isLoading = false;
        _applyFilters();
      });

      if (kDebugMode) {
        print('✅ $__logName ${historique.length} items d\'historique chargés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement historique: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<HistoriqueEquipment> filtered = List.from(_allHistorique);

    filtered = filtered.where((item) => item.status == _statusFilter).toList();

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();

      filtered =
          filtered.where((item) {
            switch (_searchType) {
              case 'code':
                return item.code?.toLowerCase().contains(query) ?? false;
              case 'description':
                return item.description?.toLowerCase().contains(query) ?? false;
              case 'zone':
                return item.zone?.toLowerCase().contains(query) ?? false;
              case 'famille':
                return item.famille?.toLowerCase().contains(query) ?? false;
              case 'all':
              default:
                return (item.code?.toLowerCase().contains(query) ?? false) ||
                    (item.description?.toLowerCase().contains(query) ??
                        false) ||
                    (item.zone?.toLowerCase().contains(query) ?? false) ||
                    (item.famille?.toLowerCase().contains(query) ?? false);
            }
          }).toList();
    }

    setState(() {
      _filteredHistorique = filtered;
    });

    if (kDebugMode) {
      print(
        '🔍 $__logName Filtres appliqués: ${_filteredHistorique.length}/${_allHistorique.length} résultats',
      );
    }
  }

  void _onStatusChanged(String newStatus) {
    if (kDebugMode) {
      print('🔄 $__logName Changement de statut: $_statusFilter → $newStatus');
    }

    setState(() {
      _statusFilter = newStatus;
    });

    _applyFilters();
  }

  void _performSearch(String value) {
    if (kDebugMode) {
      print('🔍 $__logName Recherche: "$value" (type: $_searchType)');
    }

    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppTheme.primaryColor, body: _buildBody());
  }

  Widget _buildBody() {
    final responsive = context.responsive; // ✅ AJOUTÉ
    final spacing = context.spacing; // ✅ AJOUTÉ

    return Stack(
      children: [
        Positioned(
          top: responsive.spacing(120), // ✅ MODIFIÉ: Position responsive
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: spacing.horizontalPadding, // ✅ MODIFIÉ: Padding responsive
            child: Column(
              children: [
                custom.SearchBar(
                  controller: _searchController,
                  initialType: _searchType,
                  onSearch: (value) {
                    _performSearch(value);
                    setState(() {});
                  },
                  onTypeChange: (type) {
                    setState(() {
                      _searchType = type;
                    });
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),

                SizedBox(
                  height: spacing.large,
                ), // ✅ MODIFIÉ: Espacement responsive

                StatusFilterButtons(
                  selectedStatus: _statusFilter,
                  onStatusChanged: _onStatusChanged,
                ),

                SizedBox(
                  height: spacing.large,
                ), // ✅ MODIFIÉ: Espacement responsive

                Expanded(
                  child: EquipmentList(
                    isLoading: _isLoading,
                    items: _filteredHistorique,
                    onRefresh: () => _loadHistorique(forceRefresh: true),
                    itemBuilder:
                        (item) => buildHistoryEquipmentItem(
                          item as HistoriqueEquipment,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ Barre bleue en haut (responsive)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: AppTheme.secondaryColor,
            height: responsive.spacing(70), // ✅ MODIFIÉ: Hauteur responsive
          ),
        ),

        // ✅ Carte de statistiques (responsive)
        Positioned(
          top: responsive.spacing(20), // ✅ MODIFIÉ: Position responsive
          left: spacing.large, // ✅ MODIFIÉ: Position responsive
          right: spacing.large, // ✅ MODIFIÉ: Position responsive
          child: Container(
            height: responsive.spacing(90), // ✅ MODIFIÉ: Hauteur responsive
            padding: spacing.custom(
              horizontal: 10,
              vertical: 20,
            ), // ✅ MODIFIÉ: Padding responsive
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                responsive.spacing(20), // ✅ MODIFIÉ: Border radius responsive
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.boxShadowColor,
                  blurRadius: responsive.spacing(
                    10,
                  ), // ✅ MODIFIÉ: Blur responsive
                  offset: Offset(
                    0,
                    responsive.spacing(5), // ✅ MODIFIÉ: Offset responsive
                  ),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Tools.buildStatCard(
                  context,
                  _filteredHistorique.length.toString(),
                  _statusFilter == 'in_progress' ? 'En cours' : 'Archivé',
                ),
                _buildDivider(
                  responsive,
                  spacing,
                ), // ✅ MODIFIÉ: Paramètres ajoutés
                Tools.buildStatCard(
                  context,
                  _allHistorique.length.toString(),
                  'Total',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ CORRIGÉ: Divider avec responsivité
  Widget _buildDivider(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      height: responsive.spacing(40), // ✅ MODIFIÉ: Hauteur responsive
      width: 1.0,
      color: Colors.grey[300],
    );
  }
}
