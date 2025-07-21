import 'dart:async';

import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/screens/add_equipment_screen.dart';
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
  final TextEditingController _searchController =
      TextEditingController(); // Contrôleur pour le champ de recherche
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Charger les équipements au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().fetchEquipments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Libérer le contrôleur
    _debounce?.cancel(); // Annuler le Timer si actif
    super.dispose();
  }

  @override
  void deactivate() {
    // Fermer le clavier avant la désactivation
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Consumer<EquipmentProvider>(
        builder: (context, equipmentProvider, child) {
          return _buildBody(equipmentProvider);
        },
      ),
    );
  }

  Widget _buildBody(EquipmentProvider equipmentProvider) {
    return Stack(
      children: [
        // AppBar personnalisée
        Positioned(
          top: -70,
          left: 0,
          right: 0,
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.secondaryColor),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        // Action pour le menu
                      },
                    ),
                    const Text(
                      'Équipement',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEquipmentScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Contenu du body
        Positioned(
          top: 156,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 40, left: 0, right: 0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        right: 16,
                        left: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _searchBar(equipmentProvider),
                          const SizedBox(height: 20),
                          _boxOne(equipmentProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Carte des statistiques
        Positioned(
          top: 136,
          left: 26,
          right: 26,
          child: Container(
            width: double.infinity,
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
                  'Équipements',
                ),
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

  Widget _searchBar(EquipmentProvider equipmentProvider) {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Rechercher par...',
          labelStyle: TextStyle(
            color: AppTheme.thirdColor,
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          border: const UnderlineInputBorder(),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: AppTheme.secondaryColor),
            onPressed: () {
              // Appliquer le filtre
              equipmentProvider.filterEquipments(_searchController.text);
            },
          ),
        ),
        onChanged: (value) {
          // Déclencher la recherche après 1 seconde d'inactivité
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(seconds: 1), () {
            equipmentProvider.filterEquipments(value);
          });
        },
        onFieldSubmitted: (value) {
          // Déclencher la recherche lorsque l'utilisateur appuie sur "Terminé"
          equipmentProvider.filterEquipments(value);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer quelque chose';
          }
          return null;
        },
      ),
    );
  }

  Widget _boxOne(EquipmentProvider equipmentProvider) {
    final bool hasResults = equipmentProvider.equipments.isNotEmpty;

    return equipmentProvider.isLoading
        ? const LoadingIndicator()
        : Expanded(
          child: RefreshIndicator(
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
          ),
        );
  }

  Widget _buildEmptyState(EquipmentProvider equipmentProvider) {
    final bool isSearching = _searchController.text.isNotEmpty;
    final String searchTerm = _searchController.text.trim();
    
    if (isSearching) {
      // Messages personnalisés selon la longueur de la recherche
      String message;
      if (searchTerm.length < 3) {
        message =
            'Tapez au moins 3 caractères pour une recherche plus précise.';
      } else {
        message =
            'Aucun équipement ne correspond à "$searchTerm".\nEssayez avec d\'autres mots-clés comme:\n• Code équipement (ex: EQ001)\n• Zone (ex: Dakar)\n• Famille (ex: Moteur)';
      }

      return EmptyState(
        title: '🔍 Aucun résultat trouvé',
        message: message,
        icon: Icons.search_off,
        onRetry: () {
          _searchController.clear();
          equipmentProvider.filterEquipments('');
          FocusScope.of(context).unfocus();
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
      code: equipment['code'] ?? '',
      famille: equipment['famille'] ?? '',
      zone: equipment['zone'] ?? '',
      entity: equipment['entity'] ?? '',
      unite: equipment['unite'] ?? '',
      centre: equipment['centreCharge'] ?? '',
      description: equipment['description'] ?? '',
    );
  }
}
