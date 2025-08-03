import 'dart:async';

import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/screens/equipments/add_equipment_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
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

  void _loadEquipmentsWithUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      context.read<EquipmentProvider>().fetchEquipments(code: user.code);
    } else {
      context.read<EquipmentProvider>().fetchEquipments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // ✅ Fond bleu pour équipements
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
        // ✅ MODIFIÉ: Contenu principal qui commence sous la carte de statistiques
        Positioned(
          top: 120, // ✅ CHANGÉ: Position ajustée pour commencer sous la carte
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

        // ✅ AJOUTÉ: Carte de statistiques positionnée au-dessus du contenu principal
        Positioned(
          top:
              20, // ✅ Position depuis le haut de l'écran (sous l'AppBar étendue)
          left: 20,
          right: 20,
          child: Container(
            height: 90, // ✅ Hauteur fixe de la carte
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

  Widget _searchBar(EquipmentProvider equipmentProvider) {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
        ), // ✅ CHANGÉ: Texte blanc pour contraste
        decoration: InputDecoration(
          labelText: 'Rechercher par...',
          labelStyle: const TextStyle(
            color: AppTheme.thirdColor, // ✅ CHANGÉ: Label blanc transparent
            fontFamily: AppTheme.fontRoboto,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppTheme.thirdColor,
            ), // ✅ CHANGÉ: Bordure blanche
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppTheme.thirdColor,
            ), // ✅ CHANGÉ: Bordure blanche
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppTheme.thirdColor,
              width: 2.0,
            ), // ✅ CHANGÉ: Focus blanc
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.search,
              color: AppTheme.thirdColor,
            ), // ✅ CHANGÉ: Icône blanche
            onPressed: () {
              equipmentProvider.filterEquipments(_searchController.text);
            },
          ),
        ),
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(seconds: 1), () {
            equipmentProvider.filterEquipments(value);
          });
        },
        onFieldSubmitted: (value) {
          equipmentProvider.filterEquipments(value);
          FocusScope.of(context).unfocus();
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer quelque chose';
          }
          return null;
        },
        textInputAction: TextInputAction.done,
      ),
    );
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

  Widget _buildEmptyState(EquipmentProvider equipmentProvider) {
    final bool isSearching = _searchController.text.isNotEmpty;
    final String searchTerm = _searchController.text.trim();

    if (isSearching) {
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
