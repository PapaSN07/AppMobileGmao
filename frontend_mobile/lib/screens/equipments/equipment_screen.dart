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
      backgroundColor: const Color(0xFFF8FAFC),
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

    final int totalCount = equipmentProvider.equipments.length;

    return SafeArea(
      child: Column(
        children: [
          // 📊 En-Tête Supérieur Moderne : Carte de Compteur Équipements
          Container(
            margin: spacing.custom(horizontal: 16, vertical: 12),
            padding: spacing.custom(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B1D4C), Color(0xFF0F1B80)],
              ),
              borderRadius: BorderRadius.circular(responsive.spacing(16)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1B80).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalCount ${totalCount > 1 ? "Équipements" : "Équipement"}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMontserrat,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: responsive.sp(18),
                          ),
                        ),
                        Text(
                          'Catalogue de maintenance',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRoboto,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: responsive.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Barre de Recherche Élevée
          Padding(
            padding: spacing.custom(horizontal: 16),
            child: custom.SearchBar(
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
          ),

          SizedBox(height: spacing.small),

          // 📋 Liste des Équipements
          Expanded(
            child: Padding(
              padding: spacing.custom(horizontal: 16),
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
          ),
        ],
      ),
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
