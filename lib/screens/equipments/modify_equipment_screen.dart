import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:dropdown_search/dropdown_search.dart'; // ✅ Import de dropdown_search
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModifyEquipmentScreen extends StatefulWidget {
  final Map<String, String>?
  equipmentData; // Données de l'équipement à modifier

  const ModifyEquipmentScreen({super.key, this.equipmentData});

  @override
  State<ModifyEquipmentScreen> createState() => _ModifyEquipmentScreenState();
}

class _ModifyEquipmentScreenState extends State<ModifyEquipmentScreen> {
  // Valeurs sélectionnées
  String? selectedCodeParent;
  String? selectedFeeder;
  String? selectedFamille;
  String? selectedZone;
  String? selectedEntity;
  String? selectedUnite;
  String? selectedCentreCharge;
  String? valueLongitude;
  String? valueLatitude;

  // Contrôleurs et form
  final _formKey = GlobalKey<FormState>();
  final FocusNode _descriptionFocusNode = FocusNode();
  final TextEditingController _descriptionController = TextEditingController();

  // Attributs
  List<String> selectedAttributeValues = List.filled(10, '1922309AHDNAJ');

  // Listes des sélecteurs (optimisées)
  List<Map<String, dynamic>> feeders = [];
  List<Map<String, dynamic>> familles = [];
  List<Map<String, dynamic>> zones = [];
  List<Map<String, dynamic>> entities = [];
  List<Map<String, dynamic>> unites = [];
  List<Map<String, dynamic>> centreCharges = [];

  // État de chargement
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // ✅ Utiliser WidgetsBinding pour différer l'exécution après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadValuesEquipmentsWithUserInfo();
    });
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    FocusScope.of(context).unfocus();
    super.deactivate();
  }

  void _loadValuesEquipmentsWithUserInfo() async {
    if (!mounted) return;

    // ✅ Sécuriser setState avec mounted check
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Vérifier le cache d'abord
      final selectorsBox = HiveService.getCachedSelectors();

      if (selectorsBox != null && selectorsBox.isNotEmpty) {
        _populateSelectorsFromCache(selectorsBox);
        _initializeFields(); // ✅ Initialiser les champs après avoir chargé les sélecteurs
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Si pas de cache, charger depuis l'API
      await _loadSelectorsFromAPI();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement sélecteurs: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _populateSelectorsFromCache(Map<String, dynamic> selectorsBox) {
    try {
      // ✅ Ne pas appeler setState ici - juste mettre à jour les variables
      entities = _extractSelectorData(selectorsBox['entities']);
      unites = _extractSelectorData(selectorsBox['unites']);
      centreCharges = _extractSelectorData(selectorsBox['centreCharges']);
      zones = _extractSelectorData(selectorsBox['zones']);
      familles = _extractSelectorData(selectorsBox['familles']);
      feeders = _extractSelectorData(selectorsBox['feeders']);

      if (kDebugMode) {
        print('✅ Sélecteurs chargés depuis le cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur extraction cache: $e');
      }
      // ✅ Différer l'appel API avec Future.microtask
      Future.microtask(() => _loadSelectorsFromAPI());
    }
  }

  List<Map<String, dynamic>> _extractSelectorData(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      return data
          .map((item) {
            // ✅ CORRECTION : Vérifier d'abord si c'est déjà une Map
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              // Si c'est un objet avec toJson() (cas très rare maintenant)
              try {
                return (item as dynamic).toJson() as Map<String, dynamic>;
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Erreur conversion objet: $e');
                }
                return <String, dynamic>{};
              }
            }
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<void> _loadSelectorsFromAPI() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      final user = authProvider.currentUser;

      if (user != null) {
        // Charger les équipements et sélecteurs
        await equipmentProvider.fetchEquipments(entity: user.entity);

        final selectors = await equipmentProvider.loadSelectors(
          entity: user.entity,
        );

        if (selectors.isNotEmpty && mounted) {
          _populateSelectorsFromAPI(selectors);
          _initializeFields(); // ✅ Initialiser les champs après avoir chargé les sélecteurs
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Utilisateur non connecté
        await context.read<EquipmentProvider>().fetchEquipments();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement API: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _populateSelectorsFromAPI(Map<String, dynamic> selectors) {
    // ✅ Ne pas appeler setState ici non plus
    entities = _extractSelectorData(selectors['entities']);
    unites = _extractSelectorData(selectors['unites']);
    centreCharges = _extractSelectorData(selectors['centreCharges']);
    zones = _extractSelectorData(selectors['zones']);
    familles = _extractSelectorData(selectors['familles']);
    feeders = _extractSelectorData(selectors['feeders']);
  }

  // ✅ Initialisation des champs avec les données existantes
  void _initializeFields() {
    if (widget.equipmentData != null) {
      final data = widget.equipmentData!;

      // Fonction helper pour mapper les valeurs reçues avec les valeurs disponibles
      String? mapValueToDropdown(
        String? receivedValue,
        List<Map<String, dynamic>> availableItems,
      ) {
        if (receivedValue == null || receivedValue.isEmpty) return null;

        // Chercher une correspondance exacte dans les descriptions
        for (var item in availableItems) {
          final desc = item['description']?.toString() ?? '';
          final code = item['code']?.toString() ?? '';

          if (desc == receivedValue || code == receivedValue) {
            return desc.isNotEmpty ? desc : code;
          }
        }

        // Chercher une correspondance partielle
        for (var item in availableItems) {
          final desc = item['description']?.toString() ?? '';
          final code = item['code']?.toString() ?? '';

          if (desc.toLowerCase().contains(receivedValue.toLowerCase()) ||
              receivedValue.toLowerCase().contains(desc.toLowerCase()) ||
              code.toLowerCase().contains(receivedValue.toLowerCase()) ||
              receivedValue.toLowerCase().contains(code.toLowerCase())) {
            return desc.isNotEmpty ? desc : code;
          }
        }

        return null;
      }

      // Initialiser les dropdowns avec les valeurs mappées
      selectedFeeder = mapValueToDropdown(data['Feeder'], feeders);
      selectedCodeParent = mapValueToDropdown(data['Code Parent'], feeders);
      selectedFamille = mapValueToDropdown(data['Famille'], familles);
      selectedZone = mapValueToDropdown(data['Zone'], zones);
      selectedEntity = mapValueToDropdown(data['Entité'], entities);
      selectedUnite = mapValueToDropdown(data['Unité'], unites);
      selectedCentreCharge = mapValueToDropdown(data['Centre'], centreCharges);

      // Initialiser le champ description
      _descriptionController.text = data['Description'] ?? '';

      // Initialiser les valeurs de longitude et latitude
      valueLongitude = data['Longitude']?.toString() ?? '12311231';
      valueLatitude = data['Latitude']?.toString() ?? '12311231';
    }
  }

  // ✅ Helper pour extraire les options avec format intelligent
  List<String> _getSelectorsOptions(
    List<Map<String, dynamic>> data, {
    String codeKey = 'description',
  }) {
    return data
        .map((item) {
          final code = item[codeKey]?.toString().trim() ?? '';

          final shortDesc = _formatDescription(code);
          return shortDesc;
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // ✅ Formatage intelligent des descriptions
  String _formatDescription(String description) {
    final cleanDesc =
        description
            .replaceAll(RegExp(r'\bCABLE\b', caseSensitive: false), 'C.')
            .replaceAll(RegExp(r'\bCELLULE\b', caseSensitive: false), 'CELL.')
            .replaceAll(
              RegExp(r'\bTRANSFORMATEUR\b', caseSensitive: false),
              'TRANSFO',
            )
            .replaceAll(
              RegExp(r'\bDISTRIBUTION\b', caseSensitive: false),
              'DISTRIB',
            )
            .replaceAll(
              RegExp(r'\bSOUTERRAIN\b', caseSensitive: false),
              'SOUT.',
            )
            .replaceAll(RegExp(r'\bLIAISON\b', caseSensitive: false), 'LIAIS.')
            .replaceAll(
              RegExp(r'\bPROTECTION\b', caseSensitive: false),
              'PROT.',
            )
            .replaceAll(
              RegExp(r'\bTRONCONS DE\b', caseSensitive: false),
              'TRONC.',
            )
            .trim();

    return cleanDesc.length > 40
        ? '${cleanDesc.substring(0, 40)}...'
        : cleanDesc;
  }

  String? _getSelectedCode(String? displayValue) {
    if (displayValue == null || displayValue.isEmpty) return null;
    if (displayValue.contains(' - ')) {
      return displayValue.split(' - ').first.trim();
    }
    return displayValue.trim();
  }

  // ✅ NOUVEAU : Widget ComboBox personnalisé avec recherche
  Widget _buildComboBoxField({
    required String label,
    required String msgError,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    String hintText = 'Rechercher ou sélectionner...',
  }) {
    final cleanItems = items.toSet().toList()..sort();
    if (cleanItems.isEmpty) {
      cleanItems.add('Aucun élément disponible');
    }

    return DropdownSearch<String>(
      items: cleanItems,
      selectedItem: selectedValue,
      onChanged: onChanged,

      // ✅ Configuration du popup avec recherche
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.secondaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.thirdColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.secondaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          style: const TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontSize: 14,
          ),
        ),
        menuProps: MenuProps(
          backgroundColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.secondaryColor10 : null,
              border: Border(
                bottom: BorderSide(color: AppTheme.thirdColor30, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: 18,
                  ),
                if (isSelected) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontSize: 14,
                      color:
                          isSelected ? AppTheme.secondaryColor : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          );
        },
        searchDelay: const Duration(milliseconds: 300),
      ),

      // ✅ Configuration de l'apparence du champ
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          hintStyle: TextStyle(
            color: AppTheme.thirdColor,
            fontFamily: AppTheme.fontMontserrat,
            fontSize: 14,
          ),
          border: const UnderlineInputBorder(),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.thirdColor),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.secondaryColor,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),

      // ✅ Validation
      validator: (value) {
        if (value == null ||
            value.isEmpty ||
            value == 'Aucun élément disponible') {
          return msgError;
        }
        return null;
      },

      // ✅ Configuration du texte affiché
      itemAsString: (String item) {
        return item.length > 30 ? '${item.substring(0, 30)}...' : item;
      },
    );
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
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // AppBar personnalisée
        _buildCustomAppBar(),

        // Contenu principal
        _buildMainContent(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: AppTheme.secondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryColor),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les données',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: AppTheme.secondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Réessayer',
            icon: Icons.refresh,
            onPressed: _loadValuesEquipmentsWithUserInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppTheme.secondaryColor),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Modifier l\'équipement', // ✅ Titre modifié pour la modification
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned(
      top: 156,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, right: 16, left: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInformationsSection(),
                  const SizedBox(height: 40),
                  _buildParentInfoSection(),
                  const SizedBox(height: 40),
                  _buildPositioningSection(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsSection() {
    return Column(
      children: [
        _buildFieldset('Informations'),
        const SizedBox(height: 10),
        _buildCodeAndFamilleRow(),
        const SizedBox(height: 20),
        _buildZoneAndEntityRow(),
        const SizedBox(height: 20),
        _buildUniteAndChargeRow(),
        const SizedBox(height: 20),
        _buildDescriptionRow(),
      ],
    );
  }

  Widget _buildParentInfoSection() {
    return Column(
      children: [
        _buildFieldset('Informations parents'),
        const SizedBox(height: 10),
        // ✅ Utilisation du ComboBox pour Code Parent
        _buildComboBoxField(
          label: 'Code Parent',
          msgError: 'Veuillez sélectionner un code parent',
          items:
              feeders
                  .map((item) {
                    final code = item['code']?.toString() ?? '';
                    return code;
                  })
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(),
          selectedValue: selectedCodeParent,
          onChanged: (value) {
            setState(() {
              selectedCodeParent = value;
            });
          },
          hintText: 'Rechercher ou sélectionner un code parent...',
        ),
        const SizedBox(height: 20),
        _buildFeederRow(),
      ],
    );
  }

  Widget _buildPositioningSection() {
    return Column(
      children: [
        _buildFieldset('Informations de positionnement'),
        const SizedBox(height: 10),
        _buildCoordinatesRow(),
        const SizedBox(height: 20),
        _buildMapSection(),
        const SizedBox(height: 20),
        _buildAttributesSection(),
      ],
    );
  }

  Widget _buildCodeAndFamilleRow() {
    return Row(
      children: [
        Expanded(
          child: _buildText(
            label: 'Code',
            value: selectedCodeParent ?? '#12345',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ✅ Utilisation du ComboBox pour Famille
          child: _buildComboBoxField(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: _getSelectorsOptions(familles),
            selectedValue: selectedFamille,
            onChanged: (value) {
              setState(() {
                selectedFamille = value;
              });
            },
            hintText: 'Rechercher une famille...',
          ),
        ),
      ],
    );
  }

  Widget _buildZoneAndEntityRow() {
    return Row(
      children: [
        Expanded(
          // ✅ Utilisation du ComboBox pour Zone
          child: _buildComboBoxField(
            label: 'Zone',
            msgError: 'Veuillez sélectionner une zone',
            items: _getSelectorsOptions(zones),
            selectedValue: selectedZone,
            onChanged: (value) {
              setState(() {
                selectedZone = value;
              });
            },
            hintText: 'Rechercher une zone...',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ✅ Utilisation du ComboBox pour Entité
          child: _buildComboBoxField(
            label: 'Entité',
            msgError: 'Veuillez sélectionner une entité',
            items: _getSelectorsOptions(entities),
            selectedValue: selectedEntity,
            onChanged: (value) {
              setState(() {
                selectedEntity = value;
              });
            },
            hintText: 'Rechercher une entité...',
          ),
        ),
      ],
    );
  }

  Widget _buildUniteAndChargeRow() {
    return Row(
      children: [
        Expanded(
          // ✅ Utilisation du ComboBox pour Unité
          child: _buildComboBoxField(
            label: 'Unité',
            msgError: 'Veuillez sélectionner une unité',
            items: _getSelectorsOptions(unites),
            selectedValue: selectedUnite,
            onChanged: (value) {
              setState(() {
                selectedUnite = value;
              });
            },
            hintText: 'Rechercher une unité...',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ✅ Utilisation du ComboBox pour Centre de Charge
          child: _buildComboBoxField(
            label: 'Centre de Charge',
            msgError: 'Veuillez sélectionner un centre de charge',
            items: _getSelectorsOptions(centreCharges),
            selectedValue: selectedCentreCharge,
            onChanged: (value) {
              setState(() {
                selectedCentreCharge = value;
              });
            },
            hintText: 'Rechercher un centre...',
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionRow() {
    return _buildTextField(
      label: 'Description',
      msgError: 'Veuillez entrer la description',
      focusNode: _descriptionFocusNode,
      controller: _descriptionController,
    );
  }

  Widget _buildFeederRow() {
    return Row(
      children: [
        Expanded(
          // ✅ Utilisation du ComboBox pour Feeder
          child: _buildComboBoxField(
            label: 'Feeder',
            msgError: 'Veuillez sélectionner un feeder',
            items:
                feeders
                    .map((item) {
                      final desc = item['description']?.toString() ?? '';
                      return desc;
                    })
                    .where((item) => item.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort(),
            selectedValue: selectedFeeder,
            onChanged: (value) {
              setState(() {
                selectedFeeder = value;
              });
            },
            hintText: 'Rechercher un feeder...',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildText(
            label: 'Info Feeder',
            value: _formatDescription(selectedFeeder ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesRow() {
    return Row(
      children: [
        Expanded(
          child: _buildText(
            label: 'Longitude',
            value: valueLongitude ?? '12311231',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildText(
            label: 'Latitude',
            value: valueLatitude ?? '12311231',
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/map.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: AppTheme.boxShadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor75, AppTheme.primaryColor75],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Position actuelle',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (kDebugMode) {
                      print('Toucher pour modifier la position');
                    }
                  },
                  child: const Text(
                    'Toucher pour modifier',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.secondaryColor,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showAttributesModal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Ajouter les attributs',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: AppTheme.thirdColor,
                      margin: const EdgeInsets.only(top: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widgets utilitaires
  Widget _buildTextField({
    required String label,
    required String msgError,
    FocusNode? focusNode,
    TextEditingController? controller,
  }) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.secondaryColor,
          fontFamily: AppTheme.fontMontserrat,
          fontWeight: FontWeight.w600,
        ),
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.thirdColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return msgError;
        }
        return null;
      },
    );
  }

  Widget _buildText({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '------',
          style: TextStyle(
            color:
                value.isNotEmpty
                    ? AppTheme.secondaryColor
                    : AppTheme.thirdColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: AppTheme.thirdColor,
        ),
      ],
    );
  }

  Widget _buildFieldset(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 1,
            width: double.infinity,
            color: AppTheme.thirdColor,
            margin: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }

  void _showAttributesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.thirdColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'Modifier Attribut', // ✅ Titre modifié
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attribut',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: AppTheme.thirdColor,
                        margin: const EdgeInsets.only(top: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Valeur',
                      style: TextStyle(
                        fontFamily: AppTheme.fontMontserrat,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 20,
                    ),
                    child: Column(
                      children: List.generate(
                        8,
                        (index) => _buildAttributeRow(index),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttributeRow(int index) {
    const values = [
      '1922309AHDNAJ',
      '2033410BIEKBK',
      '3144521CJFLCL',
      '4255632DKGMDM',
      '5366743ELHNEE',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Test ${index + 1}',
              style: const TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            // ✅ Utilisation du ComboBox pour les attributs aussi
            child: _buildComboBoxField(
              label: '',
              msgError: 'Veuillez sélectionner une valeur',
              items: values,
              selectedValue: selectedAttributeValues[index],
              onChanged: (value) {
                setState(() {
                  selectedAttributeValues[index] = value!;
                });
              },
              hintText: 'Sélectionner...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: 'Annuler',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PrimaryButton(
            text: 'Modifier', // ✅ Texte modifié pour la modification
            icon: Icons.edit, // ✅ Icône modifiée
            onPressed: _handleModify,
          ),
        ),
      ],
    );
  }

  // ✅ Méthode de sauvegarde adaptée pour la modification
  Future<void> _handleModify() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        NotificationService.showWarning(
          context,
          title: '⚠️ Formulaire incomplet',
          message: 'Veuillez remplir tous les champs obligatoires',
          duration: const Duration(seconds: 3),
          showProgressBar: false,
        );
      }
      return;
    }

    try {
      // Créer un map seulement avec les champs modifiés
      final updatedFields = <String, dynamic>{};

      // Ajouter seulement les champs qui ont changé
      if (selectedCodeParent != null && selectedCodeParent!.isNotEmpty) {
        updatedFields['codeParent'] = _getSelectedCode(selectedCodeParent);
      }

      if (selectedFeeder != null && selectedFeeder!.isNotEmpty) {
        updatedFields['feeder'] = _getSelectedCode(selectedFeeder);
        updatedFields['infoFeeder'] = selectedFeeder;
      }

      if (selectedFamille != null && selectedFamille!.isNotEmpty) {
        updatedFields['famille'] = _getSelectedCode(selectedFamille);
      }

      if (selectedZone != null && selectedZone!.isNotEmpty) {
        updatedFields['zone'] = _getSelectedCode(selectedZone);
      }

      if (selectedEntity != null && selectedEntity!.isNotEmpty) {
        updatedFields['entity'] = _getSelectedCode(selectedEntity);
      }

      if (selectedUnite != null && selectedUnite!.isNotEmpty) {
        updatedFields['unite'] = _getSelectedCode(selectedUnite);
      }

      if (selectedCentreCharge != null && selectedCentreCharge!.isNotEmpty) {
        updatedFields['centreCharge'] = _getSelectedCode(selectedCentreCharge);
      }

      if (_descriptionController.text.isNotEmpty) {
        updatedFields['description'] = _descriptionController.text.trim();
      }

      if (valueLongitude != null && valueLongitude!.isNotEmpty) {
        updatedFields['longitude'] = valueLongitude;
      }

      if (valueLatitude != null && valueLatitude!.isNotEmpty) {
        updatedFields['latitude'] = valueLatitude;
      }

      // Ajouter les attributs modifiés
      updatedFields['attributes'] = selectedAttributeValues;

      await context.read<EquipmentProvider>().updateEquipment(
        widget.equipmentData!['ID']!, // ID de l'équipement à modifier
        updatedFields,
      );

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement modifié avec succès !',
          showAction: false,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la modification: $e');
      }

      if (mounted) {
        NotificationService.showError(
          context,
          title: '❌ Erreur',
          message: 'Impossible de modifier l\'équipement: $e',
          showAction: true,
          actionText: 'Réessayer',
          onActionPressed: _handleModify,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}
