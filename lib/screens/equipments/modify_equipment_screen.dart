import 'package:appmobilegmao/models/equipment_attribute.dart';
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

  // ✅ NOUVEAU: État pour les attributs
  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _loadingAttributes = false; // ✅ CORRIGÉ: Changé de final bool vers bool

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadValuesEquipmentsWithUserInfo();
      _loadEquipmentAttributes(); // ✅ Charger les attributs de l'équipement
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

    final List<dynamic> list =
        data is Iterable ? data.toList() : (data is List ? data : const []);

    return list
        .map((item) {
          // ✅ Vérifie si l'élément est déjà une Map<String, dynamic>
          if (item is Map<String, dynamic>) {
            return item;
          }

          // ✅ Si c'est une Map<dynamic, dynamic>, force la conversion
          if (item is Map) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          }

          // ✅ Si c'est un objet typé, tente d'appeler toJson()
          try {
            final jsonMap = (item as dynamic).toJson();
            if (jsonMap is Map) {
              return jsonMap.map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }
          } catch (_) {}

          // Retourne une Map vide si tout échoue
          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
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

  /// ✅ MODIFIÉ: Récupérer le CODE au lieu de la description pour l'API
  String? _getSelectedCode(String? selectedValue) {
    if (selectedValue == null || selectedValue.isEmpty) return null;

    // ✅ NOUVEAU: Fonction helper pour trouver le code depuis la description
    String? findCodeFromDescription(List<Map<String, dynamic>> items, String description) {
      for (final item in items) {
        final itemDescription = item['description']?.toString() ?? '';
        final itemCode = item['code']?.toString() ?? '';
        
        // Si la description correspond, retourner le CODE
        if (itemDescription == description) {
          return itemCode; // ✅ Retourner le code au lieu de la description
        }
        
        // Aussi vérifier si c'est déjà un code
        if (itemCode == description) {
          return itemCode;
        }
      }
      return null;
    }

    // ✅ Vérifier dans chaque liste et retourner le CODE correspondant
    String? code;
    
    // Famille
    code = findCodeFromDescription(familles, selectedValue);
    if (code != null) return code;
    
    // Zone
    code = findCodeFromDescription(zones, selectedValue);
    if (code != null) return code;
    
    // Entity
    code = findCodeFromDescription(entities, selectedValue);
    if (code != null) return code;
    
    // Unite
    code = findCodeFromDescription(unites, selectedValue);
    if (code != null) return code;
    
    // Centre Charge
    code = findCodeFromDescription(centreCharges, selectedValue);
    if (code != null) return code;
    
    // Feeder
    code = findCodeFromDescription(feeders, selectedValue);
    if (code != null) return code;

    // Si aucun code trouvé, retourner la valeur telle quelle (peut-être que c'est déjà un code)
    return selectedValue;
  }

  // ✅ MODIFIÉ : Widget ComboBox personnalisé avec validation optionnelle
  Widget _buildComboBoxField({
    required String label,
    required String msgError,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    String hintText = 'Rechercher ou sélectionner...',
    bool isRequired = false, // ✅ NOUVEAU: Paramètre pour rendre optionnel
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

      // ✅ MODIFIÉ: Validation conditionnelle selon isRequired
      validator: isRequired ? (value) {
        if (value == null ||
            value.isEmpty ||
            value == 'Aucun élément disponible') {
          return msgError;
        }
        return null;
      } : null, // ✅ Pas de validation si non requis

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
            value: widget.equipmentData?['Code'] ?? widget.equipmentData?['code'] ?? '#12345',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // ✅ MODIFIÉ: Famille optionnelle
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
          // ✅ MODIFIÉ: Zone optionnelle
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
          // ✅ MODIFIÉ: Entité optionnelle
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
          // ✅ MODIFIÉ: Unité optionnelle
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
          // ✅ MODIFIÉ: Centre de Charge optionnel
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
          // ✅ MODIFIÉ: Feeder optionnel
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
            onTap: availableAttributes.isNotEmpty ? _showAttributesModal : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    availableAttributes.isNotEmpty ? Icons.edit : Icons.info_outline,
                    color: availableAttributes.isNotEmpty 
                        ? AppTheme.secondaryColor 
                        : AppTheme.thirdColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    availableAttributes.isNotEmpty 
                        ? 'Modifier les attributs'
                        : 'Aucun attribut disponible',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: availableAttributes.isNotEmpty 
                          ? AppTheme.secondaryColor 
                          : AppTheme.thirdColor,
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
    bool isRequired = false, // ✅ NOUVEAU: Paramètre pour rendre optionnel
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
      // ✅ MODIFIÉ: Validation conditionnelle selon isRequired
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return msgError;
        }
        return null;
      } : null, // ✅ Pas de validation si non requis
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
  // Fin

  void _showAttributesModal() {
    // ✅ Vérifier s'il y a des attributs disponibles
    if (availableAttributes.isEmpty) {
      return; // Ne pas ouvrir la modal si aucun attribut
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // ✅ Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.thirdColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ✅ Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
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
                        const Expanded(
                          child: Text(
                            'Modifier les Attributs',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Loading ou contenu
                  if (_loadingAttributes)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.secondaryColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chargement des attributs...',
                              style: TextStyle(
                                fontFamily: AppTheme.fontMontserrat,
                                color: AppTheme.secondaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          // ✅ Header des colonnes
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Attribut',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 1,
                                    color: AppTheme.thirdColor,
                                    margin: const EdgeInsets.only(top: 8),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Valeur',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ✅ Liste des attributs
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: availableAttributes.length,
                              itemBuilder: (context, index) {
                                final attribute = availableAttributes[index];
                                return _buildAttributeRow(
                                  attribute,
                                  setModalState,
                                );
                              },
                            ),
                          ),

                          // ✅ Boutons d'action
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    text: 'Annuler',
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: PrimaryButton(
                                    text: 'Appliquer',
                                    icon: Icons.check,
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      if (mounted) {
                                        NotificationService.showSuccess(
                                          context,
                                          title: '✅ Attributs modifiés',
                                          message:
                                              'Les modifications seront appliquées lors de la sauvegarde',
                                          showAction: false,
                                          duration: const Duration(seconds: 2),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20)
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  /// ✅ Charger les attributs de l'équipement sans créer d'attributs par défaut
  Future<void> _loadEquipmentAttributes() async {
    if (widget.equipmentData == null) return;

    setState(() {
      _loadingAttributes = true;
    });

    try {
      final equipmentCode =
          widget.equipmentData!['Code'] ?? widget.equipmentData!['code'] ?? '';
      if (equipmentCode.isEmpty) {
        if (kDebugMode) {
          print('❌ Code équipement manquant');
        }
        return;
      }

      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );

      // ✅ Essayer de charger depuis l'API
      try {
        final attributes = await equipmentProvider.loadEquipmentAttributes(
          equipmentCode,
        );

        if (mounted && attributes.isNotEmpty) {
          setState(() {
            availableAttributes = attributes;

            // Initialiser les valeurs sélectionnées
            for (final attr in attributes) {
              if (attr.id != null && attr.value != null) {
                selectedAttributeValues[attr.id!] = attr.value!;
              }
            }
          });

          // Charger les valeurs possibles pour chaque attribut
          await _loadAttributeSpecifications();
        } else {
          // ✅ MODIFIÉ: Si aucun attribut trouvé, ne pas en créer
          if (kDebugMode) {
            print('📋 Aucun attribut trouvé pour cet équipement');
          }
          
          if (mounted) {
            setState(() {
              availableAttributes = []; // ✅ Laisser vide au lieu de créer des attributs par défaut
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Impossible de charger les attributs depuis l\'API: $e');
        }
        
        // ✅ MODIFIÉ: En cas d'erreur, laisser la liste vide
        if (mounted) {
          setState(() {
            availableAttributes = []; // ✅ Pas d'attributs par défaut
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur chargement attributs équipement: $e');
      }

      // ✅ MODIFIÉ: En cas d'erreur, laisser la liste vide
      if (mounted) {
        setState(() {
          availableAttributes = []; // ✅ Pas d'attributs par défaut
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAttributes = false;
        });
      }
    }
  }

  /// ✅ Charger les spécifications avec gestion d'erreur améliorée
  Future<void> _loadAttributeSpecifications() async {
    final equipmentProvider = Provider.of<EquipmentProvider>(
      context,
      listen: false,
    );

    // ✅ Créer un Map pour éviter les doublons de spécifications
    final Map<String, bool> processedSpecs = {};

    for (final attr in availableAttributes) {
      if (attr.specification != null && attr.index != null) {
        final specKey = '${attr.specification}_${attr.index}';

        // ✅ Éviter de charger plusieurs fois la même spécification
        if (processedSpecs.containsKey(specKey)) {
          continue;
        }

        processedSpecs[specKey] = true;

        try {
          // ✅ Utiliser la méthode pour charger les valeurs possibles
          final values = await equipmentProvider.loadPossibleValuesForAttribute(
            attr.specification!,
            attr.index!,
          );

          if (mounted) {
            setState(() {
              attributeValuesBySpec[specKey] = values;
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Erreur chargement valeurs attribut ${attr.name}: $e');
          }
          // ✅ En cas d'erreur, créer une liste avec au moins la valeur actuelle
          if (mounted) {
            setState(() {
              attributeValuesBySpec[specKey] = [
                EquipmentAttribute(
                  id: '${attr.id}_current',
                  specification: attr.specification,
                  index: attr.index,
                  name: attr.name,
                  value: attr.value ?? 'Valeur actuelle',
                ),
              ];
            });
          }
        }
      }
    }
  }

  /// ✅ Widget pour afficher une ligne d'attribut avec gestion des erreurs
  Widget _buildAttributeRow(
    EquipmentAttribute attribute,
    StateSetter setModalState,
  ) {
    final specKey = '${attribute.specification}_${attribute.index}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];

    // ✅ Créer la liste des options UNIQUES à partir des valeurs possibles
    final optionsSet = <String>{};

    // Ajouter les valeurs disponibles depuis l'API des valeurs possibles
    for (final attr in availableValues) {
      if (attr.value != null && attr.value!.isNotEmpty) {
        optionsSet.add(attr.value!);
      }
    }

    // ✅ Toujours ajouter la valeur actuelle de l'attribut
    if (attribute.value != null && attribute.value!.isNotEmpty) {
      optionsSet.add(attribute.value!);
    }

    // ✅ Si aucune option, ajouter des valeurs par défaut selon le type d'attribut
    if (optionsSet.isEmpty) {
      switch (attribute.name?.toLowerCase()) {
        case 'famille':
          optionsSet.addAll([
            'CELLULE_DEPART',
            'TRANSFO_HTA/BT',
            'CABLE_HTA',
            'CABLE_BT',
          ]);
          break;
        case 'zone':
          optionsSet.addAll(['DAKAR', 'THIES', 'SAINT-LOUIS', 'KAOLACK']);
          break;
        case 'entité':
        case 'entity':
          optionsSet.addAll(['SDDV', 'SDT', 'SDSL', 'SDK']);
          break;
        default:
          optionsSet.add('Aucune valeur disponible');
      }
    }

    // Convertir en liste triée
    final options = optionsSet.toList()..sort();

    // Valeur actuelle sélectionnée
    final currentValue =
        selectedAttributeValues[attribute.id ?? ''] ?? attribute.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ Nom de l'attribut
          Expanded(
            flex: 2,
            child: Text(
              attribute.name ?? 'Attribut ${attribute.index ?? ''}',
              style: const TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ✅ Dropdown des valeurs
          Expanded(
            flex: 3,
            child: DropdownSearch<String>(
              items: options,
              selectedItem: currentValue,
              onChanged: (value) {
                setModalState(() {
                  if (value != null && attribute.id != null) {
                    selectedAttributeValues[attribute.id!] = value;
                  }
                });
              },

              // Configuration du popup
              popupProps: PopupProps.menu(
                showSearchBox: options.length > 5,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                menuProps: MenuProps(
                  backgroundColor: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondaryColor10 : null,
                    ),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.secondaryColor,
                            size: 16,
                          ),
                        if (isSelected) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isSelected
                                      ? AppTheme.secondaryColor
                                      : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Configuration du champ
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Sélectionner...',
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
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),

              // Validation et affichage
              itemAsString:
                  (String item) =>
                      item.length > 25 ? '${item.substring(0, 25)}...' : item,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Gérer la modification avec l'ID correct de l'équipement
  Future<void> _handleUpdate() async {
    try {
      if (kDebugMode) {
        print('🔄 ModifyEquipmentScreen - Début de la mise à jour');
      }

      // ✅ NOUVEAU: Préparer les attributs modifiés au format requis
      final attributs = _prepareAttributesForUpdate();

      // ✅ NOUVEAU: Préparer les données selon le schéma requis avec gestion des valeurs nulles
      final updatedData = {
        'code_parent': selectedCodeParent ?? '',
        'feeder': _getSelectedCode(selectedFeeder) ?? '',
        'feeder_description': selectedFeeder ?? '',
        'code': widget.equipmentData!['Code'] ?? widget.equipmentData!['code'] ?? '',
        'famille': _getSelectedCode(selectedFamille) ?? '',
        'zone': _getSelectedCode(selectedZone) ?? '',
        'entity': _getSelectedCode(selectedEntity) ?? '',
        'unite': _getSelectedCode(selectedUnite) ?? '',
        'centre_charge': _getSelectedCode(selectedCentreCharge) ?? '',
        'description': _descriptionController.text.trim(),
        'longitude': valueLongitude ?? '12311231',
        'latitude': valueLatitude ?? '12311231',
        'attributs': attributs, // ✅ Inclure les attributs modifiés
      };

      // ✅ MODIFIÉ: Utiliser l'ID correct passé depuis equipment_screen
      final equipmentId = widget.equipmentData!['id'] ?? widget.equipmentData!['ID'] ?? '';

      if (kDebugMode) {
        print('📊 ModifyEquipmentScreen - Données à envoyer:');
        print('   - ID équipement: $equipmentId');
        print('   - Code: ${updatedData['code']}');
        print('   - Famille: ${updatedData['famille']}');
        print('   - Zone: ${updatedData['zone']}');
        print('   - Entity: ${updatedData['entity']}');
        print('   - Unite: ${updatedData['unite']}');
        print('   - Centre Charge: ${updatedData['centre_charge']}');
        print('   - Description: ${updatedData['description']}');
        print('   - Attributs: ${attributs.length} éléments');
        for (final attr in attributs) {
          print('     • ${attr['name']}: ${attr['value']} (${attr['type']})');
        }
      }

      // ✅ VALIDATION: Vérifier que l'ID est présent
      if (equipmentId.isEmpty) {
        throw Exception('ID de l\'équipement manquant pour la modification');
      }

      // ✅ VALIDATION: Vérifier que l'ID n'est pas juste le code
      if (equipmentId == updatedData['code']) {
        if (kDebugMode) {
          print('⚠️ ATTENTION: L\'ID semble être le code équipement au lieu de l\'ID unique');
        }
      }

      // ✅ MODIFIÉ: Envoyer tout en une seule fois via l'API avec l'ID correct
      await context.read<EquipmentProvider>().updateEquipment(
        equipmentId, // ✅ Utiliser l'ID réel
        updatedData,
      );

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement et attributs modifiés avec succès !',
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
          onActionPressed: _handleUpdate,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  /// ✅ Préparer les attributs pour la mise à jour (ne pas envoyer d'attributs vides)
  List<Map<String, String>> _prepareAttributesForUpdate() {
    final attributs = <Map<String, String>>[];

    // ✅ MODIFIÉ: Seulement si des attributs existent et ont été modifiés
    if (availableAttributes.isNotEmpty) {
      for (final attribute in availableAttributes) {
        if (attribute.id != null && attribute.name != null) {
          // Récupérer la valeur sélectionnée ou la valeur par défaut
          final selectedValue = selectedAttributeValues[attribute.id!];
          final finalValue = selectedValue ?? attribute.value ?? '';

          // ✅ Ajouter l'attribut s'il a une valeur
          if (finalValue.isNotEmpty) {
            attributs.add({
              'name': attribute.name!,
              'value': finalValue,
              'type': _determineAttributeType(attribute),
            });

            if (kDebugMode) {
              print('✓ Attribut préparé: ${attribute.name} = $finalValue (${_determineAttributeType(attribute)})');
            }
          }
        }
      }
    }

    if (kDebugMode) {
      print('📋 ModifyEquipmentScreen - ${attributs.length} attributs préparés pour l\'envoi');
    }

    return attributs;
  }

  /// ✅ AMÉLIORÉ: Déterminer le type d'un attribut automatiquement
  String _determineAttributeType(EquipmentAttribute attribute) {
    final name = attribute.name?.toLowerCase() ?? '';
    final value = attribute.value ?? '';

    // ✅ Déterminer le type selon le nom de l'attribut
    if (name.contains('famille') || name.contains('zone') || name.contains('entité') || 
        name.contains('entity') || name.contains('feeder') || name.contains('unite') ||
        name.contains('centre') || name.contains('marque')) {
      return 'select'; // Type sélection pour les dropdowns
    }
    
    if (name.contains('longitude') || name.contains('latitude') || 
        name.contains('coordonn') || name.contains('position') ||
        name.contains('calibre') || name.contains('tension')) {
      return 'number'; // Type numérique pour les coordonnées et valeurs techniques
    }
    
    if (name.contains('description') || name.contains('commentaire') || 
        name.contains('note') || name.contains('remarque') || name.contains('observation')) {
      return 'text'; // Type texte pour les descriptions
    }
    
    // ✅ Déterminer le type selon la valeur
    if (value.isNotEmpty) {
      // Tenter de parser comme nombre
      if (double.tryParse(value) != null) {
        return 'number';
      }
      
      // Si c'est une valeur courte et standardisée, probablement une sélection
      if (value.length < 50 && !value.contains(' ') && value.toUpperCase() == value) {
        return 'select';
      }
      
      // Si c'est une longue chaîne, probablement du texte
      if (value.length > 100) {
        return 'text';
      }
    }

    // Par défaut, type string
    return 'string';
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Annuler',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PrimaryButton(
              text: 'Modifier',
              icon: Icons.save,
              onPressed: _handleUpdate,
            ),
          ),
        ],
      ),
    );
  }
}
