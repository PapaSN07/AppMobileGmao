import 'dart:async';

import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/tools.dart';
// ✅ NOUVEAUX imports pour les widgets factorisés
import 'package:appmobilegmao/widgets/search_bar.dart' as custom;
import 'package:appmobilegmao/widgets/equipments/equipment_list.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

import 'package:appmobilegmao/widgets/equipments/equipment_form_dialog.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final TextEditingController _searchController = TextEditingController();

  // État pour le type de recherche
  String _searchType = 'all';

  // Logging
  static const String __logName = 'EquipmentScreen -';

  void _openEquipmentForm([Map<String, dynamic>? item]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EquipmentFormDialog(equipmentToEdit: item),
    );
    if (result == true && mounted) {
      final provider = Provider.of<EquipmentProvider>(context, listen: false);
      provider.fetchEquipments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item != null ? 'Équipement modifié avec succès !' : 'Équipement créé avec succès !',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEquipmentsWithUserInfo();
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

  void _loadEquipmentsWithUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );
    final user = authProvider.currentUser;

    if (user != null) {
      try {
        if (kDebugMode) {
          print('🚀 $__logName Chargement initial des sélecteurs');
        }

        unawaited(_loadSelectorsInBackground(equipmentProvider));
        await equipmentProvider.fetchEquipments();

        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ $__logName Erreur chargement initial: $e');
        }
      }
    } else {
      await equipmentProvider.fetchEquipments();
    }
  }

  Future<void> _loadSelectorsInBackground(
    EquipmentProvider equipmentProvider,
  ) async {
    try {
      final selectors = await equipmentProvider.loadSelectors();
      if (selectors.isNotEmpty) {
        if (kDebugMode) {
          print(
            '✅ $__logName Sélecteurs chargés en arrière-plan (${selectors.keys.join(', ')})',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement sélecteurs en arrière-plan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Consumer2<EquipmentProvider, AuthProvider>(
        builder: (context, equipmentProvider, authProvider, child) {
          return _buildBody(equipmentProvider, authProvider);
        },
      ),
    );
  }

  Widget _buildBody(
    EquipmentProvider equipmentProvider,
    AuthProvider authProvider,
  ) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Stack(
      children: [
        Positioned(
          top: responsive.spacing(120),
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: spacing.custom(horizontal: 16),
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
                SizedBox(height: spacing.medium),
                Expanded(
                  child: EquipmentList(
                    isLoading: equipmentProvider.isLoading,
                    items: equipmentProvider.equipments,
                    onRefresh: () => _refreshWithFilters(equipmentProvider),
                    itemBuilder: (item) => buildEquipmentItem(
                      item,
                      onEdit: () => _openEquipmentForm(item),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(color: AppTheme.secondaryColor, height: 70),
        ),

        Positioned(
          top: responsive.spacing(20), // ✅ Position responsive
          left: 20,
          right: 20,
          child: Container(
            constraints: BoxConstraints(
              minHeight: responsive.spacing(84),
            ),
            padding: spacing.custom(
              horizontal: 10,
              vertical: 12,
            ), // ✅ Padding responsive
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                responsive.spacing(20),
              ), // ✅ Border radius responsive
              boxShadow: [
                BoxShadow(
                  color: AppTheme.boxShadowColor,
                  blurRadius: responsive.spacing(
                    10,
                  ), // ✅ Blur radius responsive
                  offset: Offset(
                    0,
                    responsive.spacing(5),
                  ), // ✅ Offset responsive
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Tools.buildStatCard(
                  context,
                  equipmentProvider.equipments.length.toString(),
                  equipmentProvider.equipments.length > 1
                      ? 'Équipements'
                      : 'Équipement'
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _performSearch(String value) {
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );

    if (value.isEmpty) {
      equipmentProvider.filterEquipments('');
      if (kDebugMode) {
        print(
          '🔍 $__logName Filtre effacé: ${equipmentProvider.equipments.length} résultats',
        );
      }
      return;
    }

    final totalBefore = equipmentProvider.equipments.length;

    // ✅ CORRIGÉ : Utiliser le type de recherche pour filtrer le bon champ
    switch (_searchType) {
      case 'code':
        equipmentProvider.filterEquipmentsByField(value, 'code');
        break;
      case 'description':
        equipmentProvider.filterEquipmentsByField(value, 'description');
        break;
      case 'zone':
        equipmentProvider.filterEquipmentsByField(value, 'zone');
        break;
      case 'famille':
        equipmentProvider.filterEquipmentsByField(value, 'famille');
        break;
      case 'all':
      default:
        equipmentProvider.filterEquipments(value); // Recherche générale
        break;
    }

    final resultsAfter = equipmentProvider.equipments.length;

    if (kDebugMode) {
      print(
        '🔍 $__logName Recherche "$value" ($_searchType): $resultsAfter/$totalBefore résultats',
      );
    }
  }

  Future<void> _refreshWithFilters(EquipmentProvider equipmentProvider) async {
    try {
      if (kDebugMode) {
        print('🔄 $__logName Début du refresh avec préservation des filtres');
      }

      final currentSearchText = _searchController.text;
      final currentSearchType = _searchType;
      final hasActiveFilter = currentSearchText.isNotEmpty;

      if (kDebugMode) {
        print('📊 $__logName État actuel:');
        print('   - Recherche: "$currentSearchText"');
        print('   - Type: $currentSearchType');
        print(
          '   - Résultats affichés: ${equipmentProvider.equipments.length}',
        );
        print('   - Filtre actif: $hasActiveFilter');
      }

      // ✅ MODIFIÉ: Ne passe plus entity (déduit via AuthProvider dans le provider)
      await equipmentProvider.fetchEquipments(forceRefresh: true);

      if (hasActiveFilter) {
        if (kDebugMode) {
          print(
            '🔍 $__logName Réapplication du filtre: "$currentSearchText" ($currentSearchType)',
          );
        }

        switch (currentSearchType) {
          case 'code':
            equipmentProvider.filterEquipmentsByField(
              currentSearchText,
              'code',
            );
            break;
          case 'description':
            equipmentProvider.filterEquipmentsByField(
              currentSearchText,
              'description',
            );
            break;
          case 'zone':
            equipmentProvider.filterEquipmentsByField(
              currentSearchText,
              'zone',
            );
            break;
          case 'famille':
            equipmentProvider.filterEquipmentsByField(
              currentSearchText,
              'famille',
            );
            break;
          case 'all':
          default:
            equipmentProvider.filterEquipments(currentSearchText);
            break;
        }

        if (kDebugMode) {
          print(
            '✅ $__logName Filtre réappliqué: ${equipmentProvider.equipments.length} résultats',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '✅ $__logName Refresh terminé: ${equipmentProvider.equipments.length} équipements totaux',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur lors du refresh: $e');
      }
      rethrow;
    }
  }
}
