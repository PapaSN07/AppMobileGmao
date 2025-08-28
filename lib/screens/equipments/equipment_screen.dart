import 'dart:async';

import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/screens/equipments/add_equipment_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // ✅ NOUVEAU: État pour le type de recherche
  String _searchType = 'all'; // 'all', 'code', 'description', 'zone', 'famille'
  bool _showSearchOptions = false;

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
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  // ✅ Optimisation du chargement initial
  void _loadEquipmentsWithUserInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );
    final user = authProvider.currentUser;

    if (user != null) {
      // ✅ 1. Charger d'abord les sélecteurs (priorité cache)
      try {
        if (kDebugMode) {
          print('🚀 EquipmentScreen - Chargement initial des sélecteurs');
        }

        // Chargement en arrière-plan des sélecteurs (cache prioritaire)
        unawaited(_loadSelectorsInBackground(equipmentProvider, user.entity));

        // ✅ 2. Charger les équipements normalement
        await equipmentProvider.fetchEquipments(entity: user.entity);
      } catch (e) {
        if (kDebugMode) {
          print('❌ EquipmentScreen - Erreur chargement initial: $e');
        }
      }
    } else {
      // Utilisateur non connecté - charger uniquement les équipements
      await context.read<EquipmentProvider>().fetchEquipments();
    }
  }

  // ✅ NOUVEAU: Chargement en arrière-plan des sélecteurs
  Future<void> _loadSelectorsInBackground(
    EquipmentProvider equipmentProvider,
    String entity,
  ) async {
    try {
      final selectors = await equipmentProvider.loadSelectors(entity: entity);
      if (selectors.isNotEmpty) {
        if (kDebugMode) {
          print(
            '✅ EquipmentScreen - Sélecteurs chargés en arrière-plan (${selectors.keys.join(', ')})',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ EquipmentScreen - Erreur chargement sélecteurs en arrière-plan: $e',
        );
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
    return Stack(
      children: [
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _searchBar(equipmentProvider),
                const SizedBox(height: 20),
                Expanded(child: _buildEquipmentList(equipmentProvider)),
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
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.boxShadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  equipmentProvider.equipments.length.toString(),
                  equipmentProvider.equipments.isEmpty
                      ? 'Équipements'
                      : 'Équipement',
                ),
                _buildVerticalDivider(),
                _buildStatCard('222', 'OT'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.normal,
            color: AppTheme.secondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color.fromRGBO(144, 144, 144, 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ✅ NOUVEAU: Méthode pour effectuer une recherche filtrée par type
  void _performSearch(String value) {
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );

    if (value.isEmpty) {
      equipmentProvider.filterEquipments('');
      return;
    }

    // Filtrer selon le type de recherche sélectionné
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
        equipmentProvider.filterEquipments(value);
        break;
    }
  }

  // ✅ NOUVEAU: Widget pour afficher les options de recherche
  Widget _buildSearchTypeSelector() {
    final searchTypes = [
      {'key': 'all', 'label': 'Tous les champs', 'icon': Icons.search},
      {'key': 'code', 'label': 'Code équipement', 'icon': Icons.qr_code},
      {'key': 'description', 'label': 'Description', 'icon': Icons.description},
      {'key': 'zone', 'label': 'Zone', 'icon': Icons.location_on},
      {'key': 'famille', 'label': 'Famille', 'icon': Icons.category},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showSearchOptions ? 60 : 0,
      child:
          _showSearchOptions
              ? Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.thirdColor30),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children:
                        searchTypes.map((type) {
                          final isSelected = _searchType == type['key'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchType = type['key'] as String;
                              });

                              // Refaire la recherche avec le nouveau type
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppTheme.secondaryColor
                                        : AppTheme.primaryColor20,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppTheme.secondaryColor
                                          : AppTheme.thirdColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type['icon'] as IconData,
                                    size: 16,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : AppTheme.thirdColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    type['label'] as String,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontSize: 12,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  // ✅ MODIFIÉ: Amélioration de la barre de recherche avec options
  Widget _searchBar(EquipmentProvider equipmentProvider) {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(
              color: AppTheme.thirdColor,
              fontFamily: AppTheme.fontMontserrat,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: _getSearchPlaceholder(),
              labelStyle: const TextStyle(
                color: AppTheme.thirdColor,
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              hintText: _getSearchHint(),
              hintStyle: TextStyle(
                color: AppTheme.thirdColor60,
                fontFamily: AppTheme.fontRoboto,
                fontSize: 12,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor, width: 2.0),
              ),
              prefixIcon: IconButton(
                icon: Icon(
                  _showSearchOptions ? Icons.filter_list : Icons.tune,
                  color:
                      _showSearchOptions
                          ? AppTheme.secondaryColor
                          : AppTheme.thirdColor,
                ),
                onPressed: () {
                  setState(() {
                    _showSearchOptions = !_showSearchOptions;
                  });
                },
                tooltip: 'Options de recherche',
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ NOUVEAU: Indicateur du type de recherche actuel
                  if (_searchType != 'all')
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getSearchTypeLabel(_searchType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // ✅ Bouton de recherche existant
                  IconButton(
                    icon: const Icon(Icons.search, color: AppTheme.thirdColor),
                    onPressed: () {
                      _performSearch(_searchController.text);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  // ✅ NOUVEAU: Bouton pour effacer la recherche
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.thirdColor),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                        FocusScope.of(context).unfocus();
                      },
                    ),
                ],
              ),
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _performSearch(value);
              });
            },
            onFieldSubmitted: (value) {
              _performSearch(value);
              FocusScope.of(context).unfocus();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer quelque chose';
              }
              return null;
            },
            textInputAction: TextInputAction.search,
          ),
        ),

        // ✅ NOUVEAU: Options de recherche
        _buildSearchTypeSelector(),
      ],
    );
  }

  // ✅ NOUVEAU: Obtenir le placeholder selon le type de recherche
  String _getSearchPlaceholder() {
    switch (_searchType) {
      case 'code':
        return 'Rechercher par code...';
      case 'description':
        return 'Rechercher par description...';
      case 'zone':
        return 'Rechercher par zone...';
      case 'famille':
        return 'Rechercher par famille...';
      case 'all':
      default:
        return 'Rechercher par...';
    }
  }

  // ✅ NOUVEAU: Obtenir le hint selon le type de recherche
  String _getSearchHint() {
    switch (_searchType) {
      case 'code':
        return 'Ex: EQ001, TRANSFO_001, LM0303...';
      case 'description':
        return 'Ex: Transformateur, Moteur, Cellule...';
      case 'zone':
        return 'Ex: Dakar, Thiès, Saint-Louis...';
      case 'famille':
        return 'Ex: TRANSFO_HTA/BT, CELLULE_DEPART...';
      case 'all':
      default:
        return 'Code, description, zone, famille...';
    }
  }

  // ✅ NOUVEAU: Obtenir le label court du type de recherche
  String _getSearchTypeLabel(String type) {
    switch (type) {
      case 'code':
        return 'CODE';
      case 'description':
        return 'DESC';
      case 'zone':
        return 'ZONE';
      case 'famille':
        return 'FAM';
      default:
        return 'ALL';
    }
  }

  Widget _buildEquipmentList(EquipmentProvider equipmentProvider) {
    final bool hasResults = equipmentProvider.equipments.isNotEmpty;

    return equipmentProvider.isLoading
        ? const LoadingIndicator()
        : RefreshIndicator(
          onRefresh: () => equipmentProvider.fetchEquipments(),
          child:
              hasResults
                  ? ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: equipmentProvider.equipments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _itemBuilder(
                          equipmentProvider.equipments[index],
                        ),
                      );
                    },
                  )
                  : _buildEmptyState(equipmentProvider),
        );
  }

  // ✅ MODIFIÉ: Amélioration de l'état vide avec suggestions selon le type de recherche
  Widget _buildEmptyState(EquipmentProvider equipmentProvider) {
    final bool isSearching = _searchController.text.isNotEmpty;
    final String searchTerm = _searchController.text.trim();

    if (isSearching) {
      String message;
      String suggestions;

      if (searchTerm.length < 3) {
        message =
            'Tapez au moins 3 caractères pour une recherche plus précise.';
        suggestions = '';
      } else {
        message = 'Aucun équipement ne correspond à "$searchTerm"';

        // ✅ NOUVEAU: Suggestions spécifiques selon le type de recherche
        switch (_searchType) {
          case 'code':
            suggestions =
                'Suggestions pour les codes:\n• EQ001, TRANSFO_001\n• LM0303I2CADTRF1\n• Vérifiez l\'orthographe du code';
            break;
          case 'description':
            suggestions =
                'Suggestions pour les descriptions:\n• Transformateur, Moteur\n• Cellule, Câble\n• Essayez des termes plus généraux';
            break;
          case 'zone':
            suggestions =
                'Suggestions pour les zones:\n• DAKAR, THIES\n• SAINT-LOUIS, KAOLACK\n• Utilisez le nom complet de la zone';
            break;
          case 'famille':
            suggestions =
                'Suggestions pour les familles:\n• TRANSFO_HTA/BT\n• CELLULE_DEPART\n• CABLE_HTA, CABLE_BT';
            break;
          default:
            suggestions =
                'Essayez avec d\'autres mots-clés comme:\n• Code équipement (ex: EQ001)\n• Zone (ex: Dakar)\n• Famille (ex: Moteur)';
        }
      }

      return EmptyState(
        title: '🔍 Aucun résultat trouvé',
        message: suggestions.isNotEmpty ? '$message.\n\n$suggestions' : message,
        icon: Icons.search_off,
        onRetry: () {
          _searchController.clear();
          _performSearch('');
          FocusScope.of(context).unfocus();
          setState(() {
            _showSearchOptions = false;
            _searchType = 'all';
          });
        },
        retryButtonText: 'Effacer la recherche',
      );
    } else {
      return EmptyState(
        title: '📦 Aucun équipement',
        message:
            'Aucun équipement n\'a été trouvé.\nCommencez par ajouter votre premier équipement.',
        icon: Icons.inventory_2_outlined,
        onRetry: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEquipmentScreen()),
          );
        },
        retryButtonText: 'Ajouter un équipement',
      );
    }
  }

  Widget _itemBuilder(dynamic equipment) {
    return ListItemCustom.equipment(
      id: equipment['id']?.toString() ?? '',
      codeParent: equipment['codeParent'] ?? '',
      feeder: equipment['feeder'] ?? '',
      feederDescription: equipment['feederDescription'] ?? '',
      code: equipment['code'] ?? '',
      famille: equipment['famille'] ?? '',
      zone: equipment['zone'] ?? '',
      entity: equipment['entity'] ?? '',
      unite: equipment['unite'] ?? '',
      centre: equipment['centreCharge'] ?? '',
      description: equipment['description'] ?? '',
      longitude: equipment['longitude']?.toString() ?? '',
      latitude: equipment['latitude']?.toString() ?? '',
    );
  }
}
