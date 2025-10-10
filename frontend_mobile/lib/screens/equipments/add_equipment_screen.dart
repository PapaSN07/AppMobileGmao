import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
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
  late String generatedCode;

  // Attributs dynamiques
  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _loadingAttributes = false;

  // Variable d'état pour le bouton
  bool _isUpdating = false;

  // Listes des sélecteurs (optimisées)
  List<Map<String, dynamic>> feeders = [];
  List<Map<String, dynamic>> familles = [];
  List<Map<String, dynamic>> zones = [];
  List<Map<String, dynamic>> entities = [];
  List<Map<String, dynamic>> unites = [];
  List<Map<String, dynamic>> centreCharges = [];

  // ✅ Compteur statique au niveau de la classe
  static int _globalCounter = 0;

  // État de chargement
  bool _isLoading = true;
  bool _hasError = false;

  // Logging
  static const String __logName = 'AddEquipmentScreen -';

  @override
  void initState() {
    super.initState();

    // ✅ Nettoyer les données précédentes
    _clearPreviousData();

    // ✅ Générer le code unique dès l'initialisation
    generatedCode = _generateUniqueEquipmentCode();

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

  // ✅ CORRIGÉ: Générateur de code unique de 15 caractères maximum
  String _generateUniqueEquipmentCode() {
    // 1. Base temporelle précise
    final now = DateTime.now();
    final microTime = now.microsecondsSinceEpoch;

    // 2. Compteur global incrémenté
    _globalCounter = (_globalCounter + 1) % 999;

    // 3. Hash unique basé sur l'instance
    final instanceHash = hashCode.abs() % 999;

    // 4. Timestamp court (6 derniers chiffres des microsecondes)
    final shortTimestamp = microTime.toString().substring(
      microTime.toString().length - 6,
    );

    // 5. UUID très court (4 caractères)
    final shortUuid = microTime.toRadixString(36).toUpperCase();
    final uuid =
        shortUuid.length >= 4
            ? shortUuid.substring(0, 4)
            : shortUuid.padRight(4, 'X');

    // 6. Format final : EQ + 6digits + 4chars + 3digits = 15 caractères
    final counter = _globalCounter.toString().padLeft(3, '0');
    final uniqueCode = 'EQ$shortTimestamp$uuid$counter';

    if (kDebugMode) {
      print(
        '🔢 $__logName Code unique généré: $uniqueCode (${uniqueCode.length} chars)',
      );
      print('   - MicroTime: $microTime');
      print('   - Timestamp: $shortTimestamp (6 chars)');
      print('   - UUID: $uuid (4 chars)');
      print('   - Compteur global: $counter (3 chars)');
      print('   - Instance hash: $instanceHash');
    }

    return uniqueCode;
  }

  // ✅ NOUVEAU: Méthode pour nettoyer les données précédentes
  void _clearPreviousData() {
    // Nettoyer les attributs
    availableAttributes.clear();
    attributeValuesBySpec.clear();
    selectedAttributeValues.clear();

    // Nettoyer les sélections
    selectedCodeParent = null;
    selectedFeeder = null;
    selectedFamille = null;
    selectedZone = null;
    selectedEntity = null;
    selectedUnite = null;
    selectedCentreCharge = null;

    // Nettoyer les contrôleurs
    _descriptionController.clear();

    if (kDebugMode) {
      print('🧹 $__logName Données précédentes nettoyées');
    }
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
      // ✅ Extraction directe et simple
      entities = _extractSelectorData(selectorsBox['entities']);
      unites = _extractSelectorData(selectorsBox['unites']);
      centreCharges = _extractSelectorData(selectorsBox['centreCharges']);
      zones = _extractSelectorData(selectorsBox['zones']);
      familles = _extractSelectorData(selectorsBox['familles']);
      feeders = _extractSelectorData(selectorsBox['feeders']);

      if (kDebugMode) {
        print('✅ $__logName Sélecteurs chargés depuis le cache');
        print(
          '📊 $__logName Entités: ${entities.length}, Zones: ${zones.length}, Familles: ${familles.length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur extraction cache: $e');
      }
      Future.microtask(() => _loadSelectorsFromAPI());
    }
  }

  // Méthode d'extraction robuste
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

  // Helper pour extraire les options avec format intelligent
  List<String> _getSelectorsOptions(
    List<Map<String, dynamic>> data, {
    String codeKey = 'description',
    bool tronquer = true,
  }) {
    return data
        .map((item) {
          final code = item[codeKey]?.toString().trim() ?? '';

          if (!tronquer) return code;

          final shortDesc = _formatDescription(code);
          return shortDesc;
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // Formatage intelligent des descriptions
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

  // Méthode pour récupérer le CODE de la famille sélectionnée
  String? _getSelectedFamilleCode(String? selectedValue) {
    if (selectedValue == null || selectedValue.isEmpty) return null;

    // Chercher dans la liste des familles
    for (final famille in familles) {
      final description = famille['description']?.toString() ?? '';
      final code = famille['code']?.toString() ?? '';

      if (description == selectedValue) {
        return code; // Retourner le CODE
      }
    }

    return null;
  }

  // Charger les attributs en fonction de la famille sélectionnée avec accès correct à l'API
  Future<void> _loadAttributesForFamily(String familleCode) async {
    if (familleCode.isEmpty) {
      if (kDebugMode) {
        print('❌ $__logName Code famille vide');
      }
      return;
    }

    setState(() {
      _loadingAttributes = true;
      availableAttributes = [];
      selectedAttributeValues.clear();
    });

    try {
      if (kDebugMode) {
        print('🔄 $__logName Chargement attributs pour famille: $familleCode');
      }

      Provider.of<EquipmentProvider>(context, listen: false);

      // ✅ CORRIGÉ: Utiliser EquipmentService directement via une nouvelle instance
      final equipmentService = EquipmentService();
      final result = await equipmentService.getEquipmentAttributeValueByCode(
        codeFamille: familleCode,
      );

      final attributes =
          result['attributes'] as List<EquipmentAttribute>? ?? [];

      if (mounted && attributes.isNotEmpty) {
        setState(() {
          availableAttributes = attributes;

          // Initialiser les valeurs sélectionnées avec les valeurs par défaut
          selectedAttributeValues.clear();
          for (final attr in attributes) {
            if (attr.id != null && attr.value != null) {
              selectedAttributeValues[attr.id!] = attr.value!;
            }
          }
        });

        // Charger les valeurs possibles pour chaque attribut
        await _loadAttributeSpecifications();

        if (kDebugMode) {
          print(
            '✅ $__logName ${attributes.length} attributs chargés pour famille $familleCode',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            '📋 $__logName Aucun attribut trouvé pour famille $familleCode',
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
        print('❌ $__logName Erreur chargement attributs famille: $e');
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

  // Charger les spécifications d'attributs avec accès correct à l'API
  Future<void> _loadAttributeSpecifications() async {
    Provider.of<EquipmentProvider>(context, listen: false);

    final Map<String, bool> processedSpecs = {};

    for (final attr in availableAttributes) {
      if (attr.specification != null && attr.index != null) {
        final specKey = '${attr.specification}_${attr.index}';

        if (processedSpecs.containsKey(specKey)) {
          continue;
        }

        processedSpecs[specKey] = true;

        try {
          // ✅ CORRIGÉ: Utiliser EquipmentService directement
          final equipmentService = EquipmentService();
          final result = await equipmentService.getAttributeValuesEquipment(
            specification: attr.specification!,
            attributeIndex: attr.index!,
          );

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
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '❌ $__logName Erreur chargement valeurs attribut ${attr.name}: $e',
            );
          }

          // En cas d'erreur, créer une liste avec au moins la valeur actuelle
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

  // Gestion intelligente du type d'attribut
  String _determineAttributeType(EquipmentAttribute attribute) {
    final name = attribute.name?.toLowerCase() ?? '';
    final value = attribute.value ?? '';

    if (name.contains('famille') ||
        name.contains('zone') ||
        name.contains('entité') ||
        name.contains('entity') ||
        name.contains('feeder') ||
        name.contains('unite') ||
        name.contains('centre') ||
        name.contains('marque')) {
      return 'select';
    }

    if (name.contains('longitude') ||
        name.contains('latitude') ||
        name.contains('coordonn') ||
        name.contains('position') ||
        name.contains('calibre') ||
        name.contains('tension')) {
      return 'number';
    }

    if (name.contains('description') ||
        name.contains('commentaire') ||
        name.contains('note') ||
        name.contains('remarque') ||
        name.contains('observation')) {
      return 'text';
    }

    if (value.isNotEmpty) {
      if (double.tryParse(value) != null) {
        return 'number';
      }

      if (value.length < 50 &&
          !value.contains(' ') &&
          value.toUpperCase() == value) {
        return 'select';
      }

      if (value.length > 100) {
        return 'text';
      }
    }

    return 'string';
  }

  // ComboBox avec gestion du changement de famille
  Widget _buildComboBoxField({
    required String label,
    required String msgError,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    String hintText = 'Rechercher ou sélectionner...',
    bool isRequired = true,
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

        // ✅ NOUVEAU: Déclencher le chargement des attributs si c'est la famille
        if (label == 'Famille' && value != null) {
          final familleCode = _getSelectedFamilleCode(value);
          if (familleCode != null) {
            _loadAttributesForFamily(familleCode);
          }
        }
      },

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
      validator: (value) {
        if (!isRequired) return null;
        if (value == null ||
            value.isEmpty ||
            value == 'Aucun élément disponible') {
          return msgError;
        }
        return null;
      },
      itemAsString: (String item) {
        return item.length > 30 ? '${item.substring(0, 30)}...' : item;
      },
    );
  }

  // Les méthodes build restent identiques...
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
                  'Ajouter un équipement',
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

  Widget _buildDescriptionRow() {
    return Tools.buildTextField(
      label: 'Description',
      msgError: 'Veuillez entrer la description',
      focusNode: _descriptionFocusNode,
      controller: _descriptionController,
      isRequired: false,
    );
  }

  Widget _buildParentInfoSection() {
    return Column(
      children: [
        Tools.buildFieldset('Informations parents'),
        const SizedBox(height: 10),
        // ✅ Code Parent NON obligatoire
        _buildComboBoxField(
          label: 'Code Parent',
          msgError: '', // Champ non obligatoire, pas de message d'erreur
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
          isRequired: false,
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
            isRequired: false,
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

  // ✅ MODIFIÉ: Section attributs avec état conditionnel
  Widget _buildAttributesSection() {
    // ✅ Vérifier si une famille est sélectionnée
    final bool isFamilleSelected =
        selectedFamille != null && selectedFamille!.isNotEmpty;
    final bool hasAttributes = availableAttributes.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            // ✅ Seulement actif si famille sélectionnée ET attributs disponibles
            onTap:
                (isFamilleSelected && hasAttributes)
                    ? _showAttributesModal
                    : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isFamilleSelected
                        ? (hasAttributes ? Icons.add : Icons.info_outline)
                        : Icons.block,
                    color:
                        (isFamilleSelected && hasAttributes)
                            ? AppTheme.secondaryColor
                            : AppTheme.thirdColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFamilleSelected
                        ? (hasAttributes
                            ? 'Ajouter les attributs'
                            : (_loadingAttributes
                                ? 'Chargement des attributs...'
                                : 'Aucun attribut pour cette famille'))
                        : 'Sélectionnez d\'abord une famille',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color:
                          (isFamilleSelected && hasAttributes)
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

  // ✅ NOUVEAU: Modal des attributs (adapté de modify_equipment_screen.dart)
  void _showAttributesModal() {
    if (availableAttributes.isEmpty) {
      return;
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
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.thirdColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
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
                            'Ajouter les Attributs',
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

                  // Loading ou contenu
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
                          // Header des colonnes
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

                          // Liste des attributs
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

                          // Boutons d'action
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
                                          title: '✅ Attributs sélectionnés',
                                          message:
                                              'Les attributs seront inclus lors de la sauvegarde',
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

  // ✅ NOUVEAU: Widget pour ligne d'attribut (depuis modify_equipment_screen.dart)
  Widget _buildAttributeRow(
    EquipmentAttribute attribute,
    StateSetter setModalState,
  ) {
    final specKey = '${attribute.specification}_${attribute.index}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];

    // Créer la liste des options UNIQUES
    final optionsSet = <String>{};

    // Ajouter les valeurs disponibles depuis l'API
    for (final attr in availableValues) {
      if (attr.value != null && attr.value!.isNotEmpty) {
        optionsSet.add(attr.value!);
      }
    }

    // Toujours ajouter la valeur actuelle de l'attribut
    if (attribute.value != null && attribute.value!.isNotEmpty) {
      optionsSet.add(attribute.value!);
    }

    // Si aucune option, ajouter des valeurs par défaut
    if (optionsSet.isEmpty) {
      switch (attribute.name?.toLowerCase()) {
        case 'nature':
          optionsSet.addAll(['Cu', 'Alu', 'Acier']);
          break;
        case 'section':
          optionsSet.addAll(['1x3x240', '1x3x150', '1x3x95']);
          break;
        default:
          optionsSet.add('Aucune valeur disponible');
      }
    }

    final options = optionsSet.toList()..sort();
    final currentValue =
        selectedAttributeValues[attribute.id ?? ''] ?? attribute.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nom de l'attribut
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

          // Dropdown des valeurs
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

              itemAsString:
                  (String item) =>
                      item.length > 25 ? '${item.substring(0, 25)}...' : item,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeAndFamilleRow() {
    return Row(
      children: [
        Expanded(child: Tools.buildText(label: 'Code', value: generatedCode)),
        const SizedBox(width: 10),
        Expanded(
          // ✅ Utilisation du ComboBox pour Famille
          child: _buildComboBoxField(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: _getSelectorsOptions(familles, tronquer: false),
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
            isRequired: false,
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
            items: _getSelectorsOptions(unites, tronquer: false),
            selectedValue: selectedUnite,
            onChanged: (value) {
              setState(() {
                selectedUnite = value;
              });
            },
            hintText: 'Rechercher une unité...',
            isRequired: false,
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
            isRequired: false,
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU: Vérifier s'il y a des changements (pour add_equipment_screen c'est différent)
  bool _hasChanges() {
    // Pour un ajout d'équipement, on considère qu'il y a des changements si :
    // 1. Au moins une famille est sélectionnée (obligatoire)
    // 2. Au moins une description est saisie

    final hasFamille = selectedFamille != null && selectedFamille!.isNotEmpty;
    // final hasDescription = _descriptionController.text.trim().isNotEmpty;

    // Pour l'ajout, on considère qu'il y a des changements dès qu'on a les champs obligatoires
    // return hasFamille && hasDescription;
    return hasFamille;
  }

  // ✅ CORRIGÉ: Boutons d'action adaptés pour l'ajout d'équipement
  Widget _buildActionButtons() {
    // ✅ Vérifier s'il y a suffisamment de données pour permettre l'ajout
    final canSave = _hasChanges();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Annuler',
              // ✅ Désactiver le bouton Annuler pendant l'ajout
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                _isUpdating
                    ? // ✅ Bouton avec loader pendant l'ajout
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
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Ajout en cours...',
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
                    : // ✅ Bouton d'ajout avec état conditionnel
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            canSave
                                ? AppTheme.secondaryColor
                                : AppTheme.thirdColor50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: canSave ? _handleSave : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  color:
                                      canSave
                                          ? Colors.white
                                          : AppTheme.thirdColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    canSave
                                        ? 'Ajouter'
                                        : 'Remplissez les champs',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          canSave
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                      fontSize: 14,
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

  // ✅ CORRIGÉ: Préparer les attributs pour l'envoi selon les spécifications backend
  List<Map<String, String>> _prepareAttributesForSave() {
    final attributs = <Map<String, String>>[];

    // ✅ IMPORTANT: Toujours inclure TOUS les attributs de la famille, même sans valeur
    if (availableAttributes.isNotEmpty) {
      for (final attribute in availableAttributes) {
        if (attribute.name != null) {
          // ✅ Récupérer la valeur sélectionnée ou utiliser la valeur par défaut ou chaîne vide
          final selectedValue = selectedAttributeValues[attribute.id!];
          final finalValue = selectedValue ?? attribute.value ?? '';

          // ✅ Déterminer le type intelligent de l'attribut
          final attributeType = _determineAttributeType(attribute);

          // ✅ NOUVEAU: Inclure TOUS les attributs, même ceux sans valeur
          attributs.add({
            'id': attribute.id!,
            'name': attribute.name!,
            'specification': attribute.specification!,
            'index': attribute.index!,
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

  // ✅ CORRIGÉ: Méthode universelle pour extraire le CODE depuis une description
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

  // ✅ CORRIGÉ: Gestion de la sauvegarde avec codes corrects
  Future<void> _handleSave() async {
    // ✅ Vérifier si un ajout est déjà en cours
    if (_isUpdating) {
      if (kDebugMode) {
        print('⚠️ $__logName Ajout déjà en cours, abandon');
      }
      return;
    }

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
      // ✅ Activer le loader
      setState(() {
        _isUpdating = true;
      });

      if (kDebugMode) {
        print('🔄 $__logName Début de l\'ajout');
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // ✅ IMPORTANT: Préparer les attributs AVANT de créer les données
      final attributs = _prepareAttributesForSave();

      // ✅ CRUCIAL: Convertir CHAQUE description sélectionnée en CODE
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

      // ✅ IMPORTANT: Utiliser les codes courts pour éviter les erreurs de longueur
      final equipmentData = {
        'codeParent': codeParentCode,
        'code': generatedCode,
        'feeder': feederCode,
        'infoFeeder': feederCode,
        'famille': familleCode,
        'zone': zoneCode,
        'entity': entityCode,
        'unite': uniteCode,
        'centreCharge': centreChargeCode,
        'description': _descriptionController.text.trim(),
        'longitude': valueLongitude ?? '12311231',
        'latitude': valueLatitude ?? '12311231',
        'attributs': attributs,
        'createdBy': authProvider.currentUser?.username, // Champ requis par le backend
      };

      if (kDebugMode) {
        print('📊 $__logName Données à envoyer:');
        print('   - Code Parent: ${equipmentData['codeParent']}');
        print('   - Code: ${equipmentData['code']}');
        print('   - Feeder: ${equipmentData['feeder']}');
        print('   - Famille: ${equipmentData['famille']}');
        print('   - Zone: ${equipmentData['zone']}');
        print(
          '   - Entity (CODE COURT): ${equipmentData['entity']} (original: $selectedEntity)',
        );
        print('   - Unite: ${equipmentData['unite']}');
        print('   - Centre Charge: ${equipmentData['centreCharge']}');
        print('   - Description: ${equipmentData['description']}');
        print('   - Longitude: ${equipmentData['longitude']}');
        print('   - Latitude: ${equipmentData['latitude']}');
        print('   - Created By: ${equipmentData['createdBy']}');
        print('   - Attributs: ${attributs.length} éléments');
        for (final attr in attributs) {
          print('     • ${attr['name']}: "${attr['value']}" (${attr['type']})');
        }
      }

      // ✅ Envoyer au provider qui se chargera de la conversion des codes
      await context.read<EquipmentProvider>().addEquipment(equipmentData);

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement ajouté avec succès !',
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
        print('❌ $__logName Erreur lors de l\'ajout: $e');
      }

      if (mounted) {
        NotificationService.showError(
          context,
          title: '❌ Erreur',
          message: 'Impossible d\'ajouter l\'équipement: $e',
          showAction: true,
          actionText: 'Réessayer',
          onActionPressed: _handleSave,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      // ✅ Désactiver le loader dans tous les cas
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
