import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:dropdown_search/dropdown_search.dart'; // ✅ Import de dropdown_search
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModifyEquipmentScreen extends StatefulWidget {
  final Map<String, String>?
  equipmentData; // Données de l'équipement à modifier
  final List<Map<String, dynamic>>? equipmentAttributes;

  const ModifyEquipmentScreen({
    super.key,
    this.equipmentData,
    this.equipmentAttributes,
  });

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

  // ✅ État pour les attributs
  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _loadingAttributes = false; // ✅ CORRIGÉ: Changé de final bool vers bool

  // ✅ État de chargement pour le bouton Modifier
  bool _isUpdating = false;

  // ✅ NOUVEAU: Variables pour stocker les valeurs initiales
  String? _initialCodeParent;
  String? _initialFeeder;
  String? _initialFamille;
  String? _initialZone;
  String? _initialEntity;
  String? _initialUnite;
  String? _initialCentreCharge;
  String? _initialDescription;
  Map<String, String> _initialAttributeValues = {};

  // ✅ NOUVEAU: Flag pour éviter les appels multiples
  bool _initialValuesSaved = false;

  // Logging
  static const String __logName = 'ModifyEquipmentScreen -';

  @override
  void initState() {
    super.initState();

    _descriptionController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadValuesEquipmentsWithUserInfo();
      if (widget.equipmentAttributes != null &&
          widget.equipmentAttributes!.isNotEmpty) {
        await _initializeAttributesFromParams();
      } else {
        await _loadEquipmentAttributes();
      }
    });
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Méthode appelée quand un champ change
  void _onFieldChanged() {
    setState(() {
      // Déclencher un rebuild pour vérifier si des changements ont eu lieu
    });
  }

  // Vérifier s'il y a des changements par rapport aux valeurs initiales
  bool _hasChanges() {
    // Vérifier les ComboBox
    if (selectedCodeParent != _initialCodeParent) return true;
    if (selectedFeeder != _initialFeeder) return true;
    if (selectedFamille != _initialFamille) return true;
    if (selectedZone != _initialZone) return true;
    if (selectedEntity != _initialEntity) return true;
    if (selectedUnite != _initialUnite) return true;
    if (selectedCentreCharge != _initialCentreCharge) return true;

    // Vérifier le champ de description
    if (_descriptionController.text.trim() != _initialDescription?.trim()) {
      return true;
    }

    // Vérifier les attributs
    if (_initialAttributeValues.length != selectedAttributeValues.length) {
      return true;
    }

    for (final entry in selectedAttributeValues.entries) {
      final initialValue = _initialAttributeValues[entry.key] ?? '';
      if (entry.value != initialValue) return true;
    }

    // Aucun changement détecté
    return false;
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
        print('❌ $__logName Erreur chargement sélecteurs: $e');
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
        print('✅ $__logName Sélecteurs chargés depuis le cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur extraction cache: $e');
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
        print('❌ $__logName Erreur chargement API: $e');
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

      // ✅ MODIFIÉ: Sauvegarder seulement si ce n'est pas déjà fait
      if (!_initialValuesSaved) {
        _saveInitialValues();
      }
    }
  }

  // ✅ CORRIGÉ: Sauvegarder les valeurs initiales avec protection contre les appels multiples
  void _saveInitialValues() {
    // ✅ IMPORTANT: Éviter les appels multiples
    if (_initialValuesSaved) {
      if (kDebugMode) {
        print('⚠️ $__logName Valeurs initiales déjà sauvegardées, skip');
      }
      return;
    }

    _initialCodeParent = selectedCodeParent;
    _initialFeeder = selectedFeeder;
    _initialFamille = selectedFamille;
    _initialZone = selectedZone;
    _initialEntity = selectedEntity;
    _initialUnite = selectedUnite;
    _initialCentreCharge = selectedCentreCharge;
    _initialDescription = _descriptionController.text.trim();

    // Sauvegarder les valeurs initiales des attributs
    _initialAttributeValues = Map<String, String>.from(selectedAttributeValues);

    // ✅ IMPORTANT: Marquer comme sauvegardé
    _initialValuesSaved = true;

    if (kDebugMode) {
      print('✅ $__logName Valeurs initiales sauvegardées');
      print('   - Code Parent: $_initialCodeParent');
      print('   - Feeder: $_initialFeeder');
      print('   - Famille: $_initialFamille');
      print('   - Zone: $_initialZone');
      print('   - Entity: $_initialEntity');
      print('   - Unite: $_initialUnite');
      print('   - Centre Charge: $_initialCentreCharge');
      print('   - Description: $_initialDescription');
      print('   - Attributs: ${_initialAttributeValues.length} valeurs');
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

  // ✅ Widget ComboBox personnalisé avec validation optionnelle et détection de changement
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
      onChanged: (value) {
        onChanged(value);
        // ✅ NOUVEAU: Détecter le changement
        _onFieldChanged();
      },

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
      validator:
          isRequired
              ? (value) {
                if (value == null ||
                    value.isEmpty ||
                    value == 'Aucun élément disponible') {
                  return msgError;
                }
                return null;
              }
              : null, // ✅ Pas de validation si non requis
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
        Tools.buildFieldset('Informations'),
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
        Tools.buildFieldset('Informations parents'),
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
        Tools.buildFieldset('Informations de positionnement'),
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
          child: Tools.buildText(
            label: 'Code',
            value:
                widget.equipmentData?['Code'] ??
                widget.equipmentData?['code'] ??
                '#12345',
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
    return Tools.buildTextField(
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
          child: Tools.buildText(
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
          child: Tools.buildText(
            label: 'Longitude',
            value: valueLongitude ?? '12311231',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tools.buildText(
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
                      print('$__logName Toucher pour modifier la position');
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
                    availableAttributes.isNotEmpty
                        ? Icons.edit
                        : Icons.info_outline,
                    color:
                        availableAttributes.isNotEmpty
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
                      color:
                          availableAttributes.isNotEmpty
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  flex: 2,
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
                                    textAlign: TextAlign.right,
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
                          const SizedBox(height: 20),
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

  /// ✅ Charger les spécifications avec la même logique que add_equipment_screen.dart
  Future<void> _loadAttributeSpecifications() async {
    // ✅ IMPORTANT: Ne pas créer de Map pour éviter les doublons - charger TOUJOURS
    for (final attr in availableAttributes) {
      if (attr.specification != null && attr.index != null) {
        final specKey = '${attr.specification}_${attr.index}';
        if (kDebugMode) {
          print(
            '🔍 $__logName Attribut ${attr.name} (spec: ${attr.specification}, index: ${attr.index}) .',
          );
        }

        try {
          // ✅ FORCER l'appel API directement comme dans add_equipment_screen.dart
          final equipmentService = EquipmentService();
          final result = await equipmentService.getAttributeValuesEquipment(
            specification: attr.specification!,
            attributeIndex: attr.index!,
          );

          if (kDebugMode) {
            print(
              '🔍 $__logName-------------Chargement valeurs attribut result: $result '
              '🔍 $__logName Chargement valeurs attribut ${attr.name} '
              '(spec: ${attr.specification}, index: ${attr.index})',
            );
          }

          final values =
              result['attributes'] as List<EquipmentAttribute>? ?? [];

          if (mounted) {
            setState(() {
              attributeValuesBySpec[specKey] = values;
            });
          }

          if (kDebugMode) {
            print(
              '✅ $__logName ${values.length} valeurs chargées pour attribut ${attr.name}',
            );
            // ✅ NOUVEAU: Afficher les valeurs récupérées
            for (final val in values) {
              print('   • Valeur disponible: "${val.value}"');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '❌ $__logName Erreur chargement valeurs attribut ${attr.name}: $e',
            );
          }

          // ✅ MODIFIÉ: En cas d'erreur, créer une liste avec des valeurs par défaut + valeur actuelle
          if (mounted) {
            setState(() {
              final defaultValues = <EquipmentAttribute>[];

              // ✅ Toujours inclure la valeur actuelle
              if (attr.value != null && attr.value!.isNotEmpty) {
                defaultValues.add(
                  EquipmentAttribute(
                    id: '${attr.id}_current',
                    specification: attr.specification,
                    index: attr.index,
                    name: attr.name,
                    value: attr.value,
                  ),
                );
              }

              attributeValuesBySpec[specKey] = defaultValues;
            });
          }
        }
      }
    }
  }

  /// ✅ Widget pour afficher une ligne d'attribut avec gestion des null
  Widget _buildAttributeRow(
    EquipmentAttribute attribute,
    StateSetter setModalState,
  ) {
    final specKey =
        '${attribute.specification ?? 'no_spec'}_${attribute.index ?? 'no_index'}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];

    // ✅ NOUVEAU: Créer la liste des options UNIQUES à partir des valeurs de l'API
    final optionsSet = <String>{};

    // ✅ PRIORITÉ 1: Ajouter TOUTES les valeurs récupérées depuis l'API
    for (final attr in availableValues) {
      if (attr.value != null && attr.value!.isNotEmpty) {
        optionsSet.add(attr.value!);
      }
    }

    // ✅ PRIORITÉ 2: Toujours inclure la valeur actuelle (même si pas dans l'API)
    if (attribute.value != null && attribute.value!.isNotEmpty) {
      optionsSet.add(attribute.value!);
    }

    // ✅ Toujours ajouter l'option vide pour permettre de vider le champ
    optionsSet.add('');

    // Convertir en liste triée (option vide à la fin)
    final options =
        optionsSet.where((opt) => opt.isNotEmpty).toList()
          ..sort()
          ..add(''); // Ajouter l'option vide à la fin

    // ✅ Générer un ID sûr pour l'attribut
    final safeAttributeId =
        attribute.id ??
        '${attribute.name}_${attribute.specification}_${attribute.index}';

    // ✅ IMPORTANT: Valeur actuellement sélectionnée (priorité aux modifications utilisateur)
    final currentValue =
        selectedAttributeValues[safeAttributeId] ?? attribute.value;

    if (kDebugMode) {
      print('🔍 $__logName Attribut ${attribute.name}:');
      print('   - ID: $safeAttributeId');
      print('   - Valeur originale: "${attribute.value}"');
      print('   - Valeur sélectionnée: "$currentValue"');
      print(
        '   - Options disponibles: ${options.length} (${options.join(', ')})',
      );
    }

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

          // ✅ Dropdown avec toutes les valeurs de l'API + valeur actuelle mise en évidence
          Expanded(
            flex: 3,
            child: DropdownSearch<String>(
              items: options,
              selectedItem: currentValue,
              onChanged: (value) {
                if (kDebugMode) {
                  print(
                    '🔄 $__logName Changement attribut ${attribute.name}: "$currentValue" -> "$value"',
                  );
                }

                setModalState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });

                // ✅ Mettre à jour aussi l'état principal
                setState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });

                _onFieldChanged();
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
                  // ✅ NOUVEAU: Déterminer si c'est la valeur originale de l'attribut
                  final isOriginalValue = item == attribute.value;
                  final displayText = item.isEmpty ? '(Vide)' : item;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondaryColor10 : null,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppTheme.thirdColor30,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // ✅ Icône de sélection
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.secondaryColor,
                            size: 16,
                          ),
                        if (isSelected) const SizedBox(width: 8),

                        // ✅ NOUVEAU: Indicateur pour la valeur originale
                        if (isOriginalValue && !isSelected)
                          const Icon(
                            Icons.star,
                            color: AppTheme.thirdColor,
                            size: 16,
                          ),
                        if (isOriginalValue && !isSelected)
                          const SizedBox(width: 8),

                        // ✅ Icône spéciale pour l'option vide
                        if (item.isEmpty && !isSelected)
                          const Icon(
                            Icons.clear,
                            color: AppTheme.thirdColor,
                            size: 16,
                          ),
                        if (item.isEmpty && !isSelected)
                          const SizedBox(width: 8),

                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: displayText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isSelected
                                            ? AppTheme.secondaryColor
                                            : (isOriginalValue
                                                ? AppTheme.thirdColor
                                                : Colors.black87),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : (isOriginalValue
                                                ? FontWeight.w500
                                                : FontWeight.normal),
                                    fontStyle:
                                        item.isEmpty
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                  ),
                                ),
                                // ✅ NOUVEAU: Étiquette pour la valeur actuelle
                                if (isOriginalValue && !isSelected)
                                  TextSpan(
                                    text: ' (actuel)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.thirdColor,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
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

              // ✅ Configuration de l'affichage du texte sélectionné
              itemAsString: (String item) {
                if (item.isEmpty) return '(Vide)';
                return item.length > 25 ? '${item.substring(0, 25)}...' : item;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Initialisation des attributs avec ID sécurisé
  Future<void> _initializeAttributesFromParams() async {
    if (widget.equipmentAttributes == null ||
        widget.equipmentAttributes!.isEmpty) {
      if (kDebugMode) {
        print('📋 $__logName Aucun attribut passé en paramètre');
      }
      return;
    }

    try {
      // Convertir les attributs passés en EquipmentAttribute
      final List<EquipmentAttribute> convertedAttributes = [];

      for (int i = 0; i < widget.equipmentAttributes!.length; i++) {
        final attrData = widget.equipmentAttributes![i];

        final attribute = EquipmentAttribute(
          id: attrData['id']?.toString(),
          name: attrData['name']?.toString(),
          value: attrData['value']?.toString() ?? '',
          type: attrData['type']?.toString() ?? 'string',
          specification: attrData['specification']?.toString(),
          index: attrData['index']?.toString(),
        );

        convertedAttributes.add(attribute);
      }

      if (mounted) {
        setState(() {
          availableAttributes = convertedAttributes;

          // ✅ IMPORTANT: Initialiser les valeurs sélectionnées avec des ID sécurisés
          selectedAttributeValues.clear();
          for (final attr in convertedAttributes) {
            final safeId =
                attr.id ?? '${attr.name}_${attr.specification}_${attr.index}';
            selectedAttributeValues[safeId] = attr.value ?? '';
          }

          _loadingAttributes = false;
        });

        // ✅ MODIFIÉ: Sauvegarder seulement si ce n'est pas déjà fait
        if (!_initialValuesSaved) {
          _saveInitialValues();
        }

        // ✅ IMPORTANT: TOUJOURS charger les spécifications pour récupérer toutes les valeurs possibles
        if (kDebugMode) {
          print(
            '🔄 $__logName Chargement des spécifications pour récupérer toutes les valeurs...(1)',
          );
        }
        await _loadAttributeSpecifications();
      }

      if (kDebugMode) {
        print(
          '✅ $__logName ${convertedAttributes.length} attributs initialisés depuis les paramètres:',
        );
        for (final attr in convertedAttributes) {
          final safeId =
              attr.id ?? '${attr.name}_${attr.specification}_${attr.index}';
          print('   - ${attr.name}: "${attr.value}" (ID: $safeId)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ $__logName Erreur initialisation attributs depuis paramètres: $e',
        );
      }
      // Fallback : charger depuis l'API
      await _loadEquipmentAttributes();
    }
  }

  /// ✅ Charger les attributs avec ID sécurisé
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
          print('❌ $__logName Code équipement manquant');
        }
        return;
      }

      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );

      // ✅ Charger les attributs depuis l'API
      try {
        final attributes = await equipmentProvider.loadEquipmentAttributes(
          equipmentCode,
        );

        if (mounted && attributes.isNotEmpty) {
          setState(() {
            availableAttributes = attributes;

            // ✅ Initialiser les valeurs sélectionnées avec des ID sécurisés
            selectedAttributeValues.clear();
            for (final attr in attributes) {
              final safeId =
                  attr.id ?? '${attr.name}_${attr.specification}_${attr.index}';
              if (attr.value != null) {
                selectedAttributeValues[safeId] = attr.value!;
              }
            }
          });

          // ✅ Sauvegarder les valeurs initiales
          if (!_initialValuesSaved) {
            _saveInitialValues();
          }

          // ✅ IMPORTANT: Toujours charger les spécifications pour obtenir toutes les valeurs possibles
          if (kDebugMode) {
            print(
              '🔄 $__logName Chargement des spécifications pour récupérer toutes les valeurs...(2)',
            );
          }
          await _loadAttributeSpecifications();
        } else {
          if (kDebugMode) {
            print('📋 $__logName Aucun attribut trouvé pour cet équipement');
          }

          if (mounted) {
            setState(() {
              availableAttributes = [];
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ $__logName Impossible de charger les attributs depuis l\'API: $e',
          );
        }

        if (mounted) {
          setState(() {
            availableAttributes = [];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement attributs équipement: $e');
      }

      if (mounted) {
        setState(() {
          availableAttributes = [];
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

  // ✅ Méthode universelle pour extraire le CODE depuis une description
  String? _getCodeFromDescription(
    String? description,
    List<Map<String, dynamic>> dataList,
  ) {
    if (description == null || description.isEmpty) return null;

    // Chercher dans la liste des données
    for (final item in dataList) {
      final itemDescription = item['description']?.toString() ?? '';
      final itemCode = item['code']?.toString() ?? '';

      // Si la description correspond, retourner le CODE
      if (itemDescription == description) {
        if (kDebugMode) {
          print('✓ $__logName Code trouvé: "$description" -> "$itemCode"');
        }
        return itemCode;
      }
    }

    if (kDebugMode) {
      print('⚠️ $__logName Code non trouvé pour: "$description"');
    }
    return description; // ✅ Fallback: retourner la description si pas de code trouvé
  }

  /// ✅ Gérer la modification avec la même logique que add_equipment_screen.dart
  Future<void> _handleUpdate() async {
    // Vérifier si une mise à jour est déjà en cours
    if (_isUpdating) {
      if (kDebugMode) {
        print('⚠️ $__logName Mise à jour déjà en cours, abandon');
      }
      return;
    }

    try {
      // Activer le loader
      setState(() {
        _isUpdating = true;
      });

      if (kDebugMode) {
        print('🔄 $__logName Début de la mise à jour');
      }

      // ✅ IMPORTANT: Préparer les attributs AVANT de créer les données
      final attributs = _prepareAttributesForUpdate();

      // ✅ CRUCIAL: Convertir CHAQUE description sélectionnée en CODE (comme add_equipment_screen.dart)
      final familleCode = _getCodeFromDescription(selectedFamille, familles);
      final zoneCode = _getCodeFromDescription(selectedZone, zones);
      final entityCode = _getCodeFromDescription(selectedEntity, entities);
      final uniteCode = _getCodeFromDescription(selectedUnite, unites);
      final centreChargeCode = _getCodeFromDescription(
        selectedCentreCharge,
        centreCharges,
      );
      final feederCode = _getCodeFromDescription(selectedFeeder, feeders);
      final codeParentCode = _getCodeFromDescription(
        selectedCodeParent,
        feeders,
      );

      // ✅ IMPORTANT: Utiliser les CODES au lieu des descriptions (comme add_equipment_screen.dart)
      final updatedData = {
        'codeParent': codeParentCode, // ✅ CODE du parent
        'code':
            widget.equipmentData!['Code'] ??
            widget.equipmentData!['code'] ??
            '',
        'feeder': feederCode, // ✅ CODE du feeder
        'infoFeeder': selectedFeeder, // ✅ Description du feeder pour info
        'famille': familleCode, // ✅ CODE de la famille
        'zone': zoneCode, // ✅ CODE de la zone
        'entity': entityCode, // ✅ CODE de l'entité
        'unite': uniteCode, // ✅ CODE de l'unité
        'centreCharge': centreChargeCode, // ✅ CODE du centre de charge
        'description':
            _descriptionController.text
                .trim(), // ✅ Description libre (pas de conversion)
        'longitude': valueLongitude ?? '12311231', // ✅ Valeur par défaut
        'latitude': valueLatitude ?? '12311231', // ✅ Valeur par défaut
        'attributs': attributs, // ✅ TOUS les attributs modifiés
      };

      final equipmentId =
          widget.equipmentData!['id'] ?? widget.equipmentData!['ID'] ?? '';

      if (equipmentId.isEmpty) {
        throw Exception('ID de l\'équipement manquant pour la modification');
      }

      if (kDebugMode) {
        print('📊 $__logName CONVERSION DESCRIPTION → CODE:');
        print('   - CodeParent: "$selectedCodeParent" → "$codeParentCode"');
        print('   - Feeder: "$selectedFeeder" → "$feederCode"');
        print('   - Famille: "$selectedFamille" → "$familleCode"');
        print('   - Zone: "$selectedZone" → "$zoneCode"');
        print('   - Entity: "$selectedEntity" → "$entityCode"');
        print('   - Unite: "$selectedUnite" → "$uniteCode"');
        print(
          '   - Centre Charge: "$selectedCentreCharge" → "$centreChargeCode"',
        );
        print(
          '   - Description: "${_descriptionController.text.trim()}" (AUCUNE CONVERSION)',
        );
        print('   - Attributs: ${attributs.length} éléments');
      }

      // ✅ Envoyer les données au provider avec les codes corrects
      await context.read<EquipmentProvider>().updateEquipment(
        equipmentId,
        updatedData,
      );

      // ✅ NOUVEAU: Attendre un petit délai pour s'assurer que le cache est mis à jour
      await Future.delayed(const Duration(milliseconds: 300));

      // ✅ NOUVEAU: Forcer un rechargement depuis le cache pour vérifier
      if (mounted) {
        final equipmentProvider = context.read<EquipmentProvider>();
        await equipmentProvider.fetchEquipments(forceRefresh: false);

        if (kDebugMode) {
          print(
            '✅ $__logName Liste des équipements rechargée depuis le cache mis à jour',
          );
        }
      }

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement modifié et sauvegardé avec succès !',
          showAction: false,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(
            context,
          ).pop(true); // Retourner true pour indiquer modification
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur lors de la modification: $e');
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
    } finally {
      // Désactiver le loader dans tous les cas
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  /// ✅ Préparer les attributs avec vérification des null
  List<Map<String, String>> _prepareAttributesForUpdate() {
    final attributs = <Map<String, String>>[];

    // ✅ IMPORTANT: Toujours inclure TOUS les attributs de l'équipement, même sans valeur
    if (availableAttributes.isNotEmpty) {
      for (final attribute in availableAttributes) {
        if (attribute.name != null) {
          // ✅ CORRIGÉ: Vérifier si l'ID existe avant de l'utiliser
          final attributeId =
              attribute.id ??
              '${attribute.name}_${DateTime.now().millisecondsSinceEpoch}';

          // ✅ Récupérer la valeur sélectionnée ou utiliser la valeur par défaut
          final selectedValue = selectedAttributeValues[attributeId];
          final finalValue = selectedValue ?? attribute.value ?? '';

          // ✅ Déterminer le type intelligent de l'attribut
          final attributeType = _determineAttributeType(attribute);

          // ✅ IMPORTANT: Inclure TOUS les attributs avec la même structure que add_equipment_screen.dart
          attributs.add({
            'id': attributeId,
            'name': attribute.name!,
            'specification': attribute.specification ?? '',
            'index': attribute.index ?? '',
            'value': finalValue,
            'type': attributeType,
          });

          if (kDebugMode) {
            print(
              '✓ $__logName Attribut préparé: ${attribute.name} = "$finalValue" ($attributeType)',
            );
          }
        }
      }
    }

    if (kDebugMode) {
      print(
        '📋 $__logName ${attributs.length} attributs préparés pour l\'envoi',
      );
    }

    return attributs;
  }

  /// ✅ AMÉLIORÉ: Déterminer le type d'un attribut automatiquement
  String _determineAttributeType(EquipmentAttribute attribute) {
    final name = attribute.name?.toLowerCase() ?? '';
    final value = attribute.value ?? '';

    // ✅ Déterminer le type selon le nom de l'attribut
    if (name.contains('famille') ||
        name.contains('zone') ||
        name.contains('entité') ||
        name.contains('entity') ||
        name.contains('feeder') ||
        name.contains('unite') ||
        name.contains('centre') ||
        name.contains('marque')) {
      return 'select'; // Type sélection pour les dropdowns
    }

    if (name.contains('longitude') ||
        name.contains('latitude') ||
        name.contains('coordonn') ||
        name.contains('position') ||
        name.contains('calibre') ||
        name.contains('tension')) {
      return 'number'; // Type numérique pour les coordonnées et valeurs techniques
    }

    if (name.contains('description') ||
        name.contains('commentaire') ||
        name.contains('note') ||
        name.contains('remarque') ||
        name.contains('observation')) {
      return 'text'; // Type texte pour les descriptions
    }

    // ✅ Déterminer le type selon la valeur
    if (value.isNotEmpty) {
      // Tenter de parser comme nombre
      if (double.tryParse(value) != null) {
        return 'number';
      }

      // Si c'est une valeur courte et standardisée, probablement une sélection
      if (value.length < 50 &&
          !value.contains(' ') &&
          value.toUpperCase() == value) {
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
    // ✅ NOUVEAU: Vérifier s'il y a des changements
    final hasChanges = _hasChanges();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Annuler',
              // ✅ MODIFIÉ: Désactiver le bouton Annuler pendant la mise à jour
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                _isUpdating
                    ? // ✅ EXISTANT: Afficher un bouton avec loader pendant la mise à jour
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor70,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8), // ✅ RÉDUIT: de 12 à 8
                          Flexible(
                            // ✅ AJOUTÉ: Flexible pour le texte
                            child: Text(
                              'Modification...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontMontserrat,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : // ✅ CORRIGÉ: Bouton avec gestion du débordement
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            hasChanges
                                ? AppTheme.secondaryColor
                                : AppTheme
                                    .thirdColor50, // ✅ Couleur grisée si pas de changements
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap:
                              hasChanges
                                  ? _handleUpdate
                                  : null, // ✅ Désactivé si pas de changements
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ), // ✅ RÉDUIT: de 16 à 12
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize:
                                  MainAxisSize
                                      .min, // ✅ AJOUTÉ: Prendre l'espace minimum nécessaire
                              children: [
                                Icon(
                                  Icons.save,
                                  color:
                                      hasChanges
                                          ? Colors.white
                                          : AppTheme.thirdColor,
                                  size: 18, // ✅ RÉDUIT: de 20 à 18
                                ),
                                const SizedBox(width: 6), // ✅ RÉDUIT: de 8 à 6
                                Flexible(
                                  // ✅ AJOUTÉ: Flexible pour que le texte s'adapte
                                  child: Text(
                                    hasChanges
                                        ? 'Modifier'
                                        : 'Aucun changement',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines:
                                        1, // ✅ AJOUTÉ: Forcer sur une seule ligne
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          hasChanges
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                      fontSize: 14, // ✅ RÉDUIT: de 16 à 14
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
