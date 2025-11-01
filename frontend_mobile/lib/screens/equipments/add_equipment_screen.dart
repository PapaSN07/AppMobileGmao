import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/codification/equipment_codification_service.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_form_fields.dart';
import 'package:appmobilegmao/utils/equipment_helpers.dart';
import 'package:appmobilegmao/utils/selector_loader.dart';
import 'package:appmobilegmao/utils/codification/codification_attribute_extractor.dart';
import 'package:appmobilegmao/utils/required_fields_manager.dart';
import 'package:appmobilegmao/widgets/required_fields_badge.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _abbreviationController = TextEditingController();
  final _abbreviationFocusNode = FocusNode();

  String? selectedFeeder, // ✅ Description du feeder (ex: "BOUNTOU PIKINE")
      selectedFamille,
      selectedZone,
      selectedEntity,
      selectedUnite,
      selectedCentreCharge;

  late String generatedCode;

  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _isUpdating = false, _isLoading = true;

  Map<String, List<Map<String, dynamic>>> selectors = {};

  // ✅ AJOUT: Configuration des champs requis
  RequiredFieldsConfig _requiredFieldsConfig = RequiredFieldsConfig.empty();

  static int _globalCounter = 0;
  static const String __logName = 'AddEquipmentScreen -';

  @override
  void initState() {
    super.initState();
    generatedCode = _generateUniqueEquipmentCode();

    // ✅ AJOUT: Régénérer quand l'abréviation change
    _abbreviationController.addListener(() {
      if (_abbreviationController.text.length >= 3) {
        _generateCodeFromInputs();
      }
    });

    if (kDebugMode) {
      print('🆕 $__logName Initialisation avec code: $generatedCode');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSelectors());
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();

    _abbreviationFocusNode.dispose();
    _abbreviationController.dispose();

    if (kDebugMode) {
      print('🗑️ $__logName Dispose');
    }

    super.dispose();
  }

  // Génération automatique du code
  void _generateCodeFromInputs() {
    if (selectedFamille == null || selectedFeeder == null) {
      // ✅ selectedFeeder
      if (kDebugMode) {
        print('⚠️ $__logName Famille ou feeder manquant');
      }
      return;
    }

    final familleCode = EquipmentHelpers.getCodeFromDescription(
      selectedFamille!,
      selectors['familles'] ?? [],
    );

    if (familleCode == null) {
      if (kDebugMode) {
        print('⚠️ $__logName Code famille introuvable');
      }
      return;
    }

    // ✅ CORRIGÉ: Extraire le code depuis la description
    final feederCode = EquipmentHelpers.getCodeFromDescription(
      selectedFeeder!, // ✅ selectedFeeder contient la description
      selectors['feeders'] ?? [],
    );

    // ✅ AJOUT: Valider les champs requis avant génération
    final attributesForValidation =
        availableAttributes
            .where((attr) => attr.id != null)
            .map(
              (attr) => {
                'name': attr.name ?? '',
                'value': selectedAttributeValues[attr.id!] ?? '',
              },
            )
            .toList();

    final validation = RequiredFieldsManager.validateRequiredFields(
      config: _requiredFieldsConfig,
      feeder: feederCode, // ✅ Passer le code extrait
      attributes: attributesForValidation,
      clientName: null,
      poste1: null,
      poste2: null,
    );

    if (!validation.isValid) {
      if (kDebugMode) {
        print('⚠️ $__logName ${validation.errorMessage}');
      }
      return;
    }

    final abbreviation = _abbreviationController.text.trim();

    // ✅ AJOUT: Validation de l'abréviation
    if (abbreviation.isEmpty) {
      if (kDebugMode) {
        print('⚠️ $__logName Abréviation manquante');
      }
      return;
    }

    // ✅ AJOUT: Logs détaillés
    if (kDebugMode) {
      print('📋 $__logName Attributs disponibles:');
      for (final attr in availableAttributes) {
        print('   - ${attr.name} (id: ${attr.id})');
      }
      print('📋 $__logName Valeurs sélectionnées:');
      selectedAttributeValues.forEach((key, value) {
        if (kDebugMode) {
          print('   - $key: $value');
        }
      });
    }

    final nature = CodificationAttributeExtractor.extractNaturePoste(
      availableAttributes,
      selectedAttributeValues,
    );

    final codeH = CodificationAttributeExtractor.extractCodeH(
      availableAttributes,
      selectedAttributeValues,
    );

    final tension = CodificationAttributeExtractor.extractTension(
      availableAttributes,
      selectedAttributeValues,
    );

    final celluleType = CodificationAttributeExtractor.extractCelluleType(
      availableAttributes,
      selectedAttributeValues,
    );

    if (kDebugMode) {
      print('🔢 $__logName Génération code:');
      print('   - Famille: $familleCode');
      print('   - Feeder (code): $feederCode');
      print('   - Feeder (description): $selectedFeeder'); // ✅ Ajout
      print('   - Abréviation: $abbreviation');
      print('   - Nature: $nature');
      print('   - Code H: $codeH');
      print('   - Tension: $tension');
      print('   - Cellule: $celluleType');
    }

    final result = EquipmentCodificationService.generateEquipmentCode(
      familleCode: familleCode,
      abbreviation: abbreviation,
      feeder: feederCode,
      nature: nature,
      codeH: codeH,
      tension: tension,
      celluleType: celluleType,
    );

    if (result.success && mounted) {
      setState(() {
        generatedCode = result.code!;
      });

      if (kDebugMode) {
        print('✅ $__logName Code généré: ${result.code}');
      }
    } else if (kDebugMode) {
      print('⚠️ $__logName ${result.errorMessage}');
    }
  }

  Future<void> _loadSelectors() async {
    if (kDebugMode) {
      print('🔄 $__logName Chargement sélecteurs...');
    }

    setState(() => _isLoading = true);

    try {
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );

      selectors = await SelectorLoader.loadSelectors(
        equipmentProvider: equipmentProvider,
      );

      if (kDebugMode) {
        print('✅ $__logName Sélecteurs chargés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateUniqueEquipmentCode() {
    _globalCounter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final code =
        'EQ${timestamp.toString().substring(7)}${_globalCounter.toString().padLeft(3, '0')}';

    if (kDebugMode) {
      print('🔢 $__logName Code temporaire: $code');
    }

    return code;
  }

  Future<void> _loadAttributesForFamily(String familleDescription) async {
    if (familleDescription.isEmpty) return;

    final familleCode = EquipmentHelpers.getCodeFromDescription(
      familleDescription,
      selectors['familles'] ?? [],
    );

    if (familleCode == null) return;

    // ✅ AJOUT: Charger la configuration des champs requis
    setState(() {
      _requiredFieldsConfig = RequiredFieldsManager.getRequiredFields(
        familleCode,
      );
    });

    if (kDebugMode) {
      print('🔍 $__logName Chargement attributs: $familleCode');
      print('📋 $__logName Champs requis:');
      print('   - Feeder: ${_requiredFieldsConfig.requiresFeeder}');
      print('   - Nature: ${_requiredFieldsConfig.requiresNaturePoste}');
      print('   - Code H: ${_requiredFieldsConfig.requiresCodeH}');
      print('   - Tension: ${_requiredFieldsConfig.requiresTension}');
      print('   - Cellule: ${_requiredFieldsConfig.requiresCelluleType}');
    }

    setState(() {
      availableAttributes = [];
      selectedAttributeValues.clear();
    });

    try {
      final equipmentService = EquipmentService();
      final result = await equipmentService.getEquipmentAttributeValueByCode(
        codeFamille: familleCode,
      );
      final attributes =
          result['attributes'] as List<EquipmentAttribute>? ?? [];

      if (kDebugMode) {
        print('📋 $__logName ${attributes.length} attributs trouvés');
      }

      if (mounted && attributes.isNotEmpty) {
        setState(() {
          availableAttributes = attributes;
          selectedAttributeValues.clear();
          for (final attr in attributes) {
            if (attr.id != null && attr.value != null) {
              selectedAttributeValues[attr.id!] = attr.value!;
            }
          }
        });

        await _loadAttributeSpecifications();

        // ✅ AJOUT: Générer le code après chargement des attributs
        _generateCodeFromInputs();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur: $e');
      }
    } finally {
      if (mounted) {}
    }
  }

  Future<void> _loadAttributeSpecifications() async {
    final equipmentService = EquipmentService();
    final processedSpecs = <String, bool>{};

    for (final attr in availableAttributes) {
      if (attr.specification != null && attr.index != null) {
        final specKey = '${attr.specification}_${attr.index}';
        if (processedSpecs.containsKey(specKey)) continue;
        processedSpecs[specKey] = true;

        try {
          final result = await equipmentService.getAttributeValuesEquipment(
            specification: attr.specification!,
            attributeIndex: attr.index!,
          );
          final values =
              result['attributes'] as List<EquipmentAttribute>? ?? [];

          if (mounted) {
            setState(() => attributeValuesBySpec[specKey] = values);
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ❌ Erreur spec $specKey: $e');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(responsive.spacing(70)),
        child: AppBar(
          titleSpacing: 0,
          title: Padding(
            padding: spacing.custom(left: 4, right: 16),
            child: Text(
              'Ajouter un équipement',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: responsive.sp(18),
              ),
            ),
          ),
          backgroundColor: AppTheme.secondaryColor,
          elevation: 0,
          leading: Padding(
            padding: spacing.custom(left: 16, right: 8),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Container(
                padding: spacing.custom(all: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor20,
                  borderRadius: BorderRadius.circular(responsive.spacing(8)),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: responsive.iconSize(20),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Retour',
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: spacing.custom(all: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        EquipmentFormFields(
                          selectedFamille: selectedFamille,
                          selectedZone: selectedZone,
                          selectedEntity: selectedEntity,
                          selectedUnite: selectedUnite,
                          selectedCentreCharge: selectedCentreCharge,
                          selectedFeeder:
                              selectedFeeder, // ✅ selectedFeeder au lieu de selectedFeederDescription
                          descriptionController: _descriptionController,
                          descriptionFocusNode: _descriptionFocusNode,
                          abbreviationController: _abbreviationController,
                          abbreviationFocusNode: _abbreviationFocusNode,
                          familles: selectors['familles'] ?? [],
                          zones: selectors['zones'] ?? [],
                          entities: selectors['entities'] ?? [],
                          unites: selectors['unites'] ?? [],
                          centreCharges: selectors['centreCharges'] ?? [],
                          feeders: selectors['feeders'] ?? [],
                          onFamilleChanged: (v) {
                            setState(() {
                              selectedFamille = v;
                              if (v != null) {
                                _loadAttributesForFamily(v);
                              }
                            });
                          },
                          onZoneChanged:
                              (v) => setState(() => selectedZone = v),
                          onEntityChanged:
                              (v) => setState(() => selectedEntity = v),
                          onUniteChanged:
                              (v) => setState(() => selectedUnite = v),
                          onCentreChargeChanged:
                              (v) => setState(() => selectedCentreCharge = v),
                          onFeederChanged: (v) {
                            // ✅ onFeederChanged au lieu de onCodeParentChanged
                            setState(() {
                              selectedFeeder = v; // ✅ selectedFeeder
                            });
                            _generateCodeFromInputs();
                          },
                          showAttributesButton: true,
                          attributesCount: availableAttributes.length,
                          onAttributesPressed: _showAttributesModal,
                        ),

                        // ✅ AJOUT: Badge des champs requis
                        if (_requiredFieldsConfig.hasRequiredAttributes) ...[
                          SizedBox(height: spacing.large),
                          RequiredFieldsBadge(
                            config: _requiredFieldsConfig,
                            onViewDetails: () {
                              if (availableAttributes.isNotEmpty) {
                                _showAttributesModal();
                              } else {
                                NotificationService.showInfo(
                                  context,
                                  title: '📋 Champs requis',
                                  message: _getRequiredFieldsMessage(),
                                  showAction: false,
                                );
                              }
                            },
                          ),
                        ],

                        SizedBox(height: spacing.xlarge),
                        _buildActionButtons(responsive, spacing),
                        SizedBox(height: spacing.xlarge),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // ✅ AJOUT: Message des champs requis
  String _getRequiredFieldsMessage() {
    final fields = <String>[];
    if (_requiredFieldsConfig.requiresFeeder) fields.add('• Feeder');
    if (_requiredFieldsConfig.requiresNaturePoste) {
      fields.add('• Nature du poste (attribut Statut)');
    }
    if (_requiredFieldsConfig.requiresCodeH) {
      fields.add('• Code H (attribut Genie civil)');
    }
    if (_requiredFieldsConfig.requiresTension) {
      fields.add('• Tension (attribut Structure poste)');
    }
    if (_requiredFieldsConfig.requiresCelluleType) {
      fields.add('• Type de cellule');
    }
    if (_requiredFieldsConfig.requiresClientName) {
      fields.add('• Nom du client');
    }
    if (_requiredFieldsConfig.requiresPosteNames) {
      fields.add('• Poste 1 et Poste 2');
    }

    return 'Champs obligatoires pour cette famille :\n\n${fields.join('\n')}';
  }

  void _showAttributesModal() {
    final responsive = context.responsive;
    final spacing = context.spacing;

    if (selectedFamille == null || availableAttributes.isEmpty) {
      NotificationService.showError(
        context,
        title: '⚠️ Attention',
        message: 'Veuillez sélectionner une famille d\'abord',
        showAction: false,
      );
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
              height: responsive.hp(80),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(responsive.spacing(30)),
                  topRight: Radius.circular(responsive.spacing(30)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: spacing.custom(vertical: 12),
                    height: responsive.spacing(4),
                    width: responsive.spacing(40),
                    decoration: BoxDecoration(
                      color: AppTheme.thirdColor,
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: spacing.custom(horizontal: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: responsive.spacing(64),
                          height: responsive.spacing(34),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: responsive.iconSize(20),
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.medium),
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
                  SizedBox(height: spacing.medium),
                  Expanded(
                    child: ListView.builder(
                      padding: spacing.custom(horizontal: 20),
                      itemCount: availableAttributes.length,
                      itemBuilder: (context, index) {
                        return _buildAttributeRow(
                          availableAttributes[index],
                          setModalState,
                          responsive,
                          spacing,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: spacing.allPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Annuler',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(width: spacing.medium),
                        Expanded(
                          child: PrimaryButton(
                            text: 'Appliquer',
                            icon: Icons.check,
                            onPressed: () {
                              Navigator.pop(context);
                              // ✅ Régénérer le code après changement
                              _generateCodeFromInputs();
                              NotificationService.showSuccess(
                                context,
                                title: '✅ Attributs sélectionnés',
                                message: 'Code mis à jour automatiquement',
                                showAction: false,
                              );
                            },
                          ),
                        ),
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

  Widget _buildAttributeRow(
    EquipmentAttribute attribute,
    StateSetter setModalState,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    final specKey =
        '${attribute.specification ?? 'no_spec'}_${attribute.index ?? 'no_index'}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];

    final optionsSet = <String>{};
    for (final attr in availableValues) {
      if (attr.value != null && attr.value!.isNotEmpty) {
        optionsSet.add(attr.value!);
      }
    }

    if (attribute.value != null && attribute.value!.isNotEmpty) {
      optionsSet.add(attribute.value!);
    }

    final options = optionsSet.toList()..sort();
    if (options.isEmpty) options.add('');

    final safeAttributeId =
        attribute.id ??
        '${attribute.name}_${attribute.specification}_${attribute.index}';
    final currentValue =
        selectedAttributeValues[safeAttributeId] ?? attribute.value;

    return Padding(
      padding: spacing.custom(bottom: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              attribute.name ?? 'Attribut ${attribute.index ?? ''}',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: responsive.sp(16),
              ),
            ),
          ),
          SizedBox(width: spacing.medium),
          Expanded(
            flex: 3,
            child: DropdownSearch<String>(
              items: options,
              selectedItem: currentValue,
              onChanged: (value) {
                setModalState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });
                setState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Sélectionner...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.spacing(8)),
                  ),
                  contentPadding: spacing.custom(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive responsive, ResponsiveSpacing spacing) {
    // ✅ MODIFIÉ: Validation avant sauvegarde
    final canSave = selectedFamille != null && _canSaveEquipment();

    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: 'Annuler',
            onPressed: _isUpdating ? null : () => Navigator.pop(context),
          ),
        ),
        SizedBox(width: spacing.medium),
        Expanded(
          child: PrimaryButton(
            text: 'Ajouter',
            icon: Icons.add,
            onPressed: canSave && !_isUpdating ? _handleSave : null,
          ),
        ),
      ],
    );
  }

  // ✅ AJOUT: Vérification complète avant sauvegarde
  bool _canSaveEquipment() {
    if (selectedFamille == null) return false;

    final attributesForValidation =
        availableAttributes
            .where((attr) => attr.id != null)
            .map(
              (attr) => {
                'name': attr.name ?? '',
                'value': selectedAttributeValues[attr.id!] ?? '',
              },
            )
            .toList();

    final validation = RequiredFieldsManager.validateRequiredFields(
      config: _requiredFieldsConfig,
      feeder: EquipmentHelpers.getCodeFromDescription(
        selectedFeeder, // ✅ Extraire le code
        selectors['feeders'] ?? [],
      ),
      attributes: attributesForValidation,
      clientName: null,
      poste1: null,
      poste2: null,
    );

    return validation.isValid;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isUpdating) return;

    // ✅ AJOUT: Double validation avant sauvegarde
    if (!_canSaveEquipment()) {
      final attributesForValidation =
          availableAttributes
              .where((attr) => attr.id != null)
              .map(
                (attr) => {
                  'name': attr.name ?? '',
                  'value': selectedAttributeValues[attr.id!] ?? '',
                },
              )
              .toList();

      final validation = RequiredFieldsManager.validateRequiredFields(
        config: _requiredFieldsConfig,
        feeder: EquipmentHelpers.getCodeFromDescription(
          selectedFeeder, // ✅ Extraire le code
          selectors['feeders'] ?? [],
        ),
        attributes: attributesForValidation,
        clientName: null,
        poste1: null,
        poste2: null,
      );

      if (mounted) {
        NotificationService.showError(
          context,
          title: '⚠️ Champs manquants',
          message: validation.errorMessage,
          showAction: true,
          actionText: 'Remplir',
          onActionPressed: _showAttributesModal,
        );
      }
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );

      final attributs = EquipmentHelpers.prepareAttributesForSave(
        availableAttributes,
        selectedAttributeValues,
      );

      final cachedSelectors = equipmentProvider.cachedSelectors;

      // ✅ CORRIGÉ: Extraire correctement le code et la description
      final feederCode = SelectorLoader.extractCodeFromTypedSelectors(
        selectedFeeder, // ✅ Description du feeder
        'feeders',
        cachedSelectors,
      );

      final equipmentData = {
        'code': generatedCode,
        'famille': SelectorLoader.extractCodeFromTypedSelectors(
          selectedFamille,
          'familles',
          cachedSelectors,
        ),
        'feeder': feederCode, // ✅ Code du feeder
        'feederDescription': selectedFeeder, // ✅ Description complète
        'zone': SelectorLoader.extractCodeFromTypedSelectors(
          selectedZone,
          'zones',
          cachedSelectors,
        ),
        'entity': SelectorLoader.extractCodeFromTypedSelectors(
          selectedEntity,
          'entities',
          cachedSelectors,
        ),
        'unite': SelectorLoader.extractCodeFromTypedSelectors(
          selectedUnite,
          'unites',
          cachedSelectors,
        ),
        'centreCharge': SelectorLoader.extractCodeFromTypedSelectors(
          selectedCentreCharge,
          'centreCharges',
          cachedSelectors,
        ),
        'description': _descriptionController.text.trim(),
        'attributs': attributs,
        'createdBy': authProvider.currentUser?.username,
      };

      if (kDebugMode) {
        print('📤 $__logName Données envoyées:');
        print('   - feeder (code): ${equipmentData['feeder']}');
        print('   - feederDescription: ${equipmentData['feederDescription']}');
      }

      await equipmentProvider.addEquipment(equipmentData);

      if (mounted) {
        NotificationService.showSuccess(
          context,
          title: '✅ Succès',
          message: 'Équipement ajouté !',
          showAction: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          title: '❌ Erreur',
          message: 'Impossible d\'ajouter: $e',
          showAction: true,
          actionText: 'Réessayer',
          onActionPressed: _handleSave,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
