import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/required_fields_manager.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_dropdown.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_text_field.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:appmobilegmao/widgets/required_fields_badge.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:appmobilegmao/widgets/equipments/attributes_modal.dart';
import 'package:appmobilegmao/utils/selector_loader.dart';
import 'package:appmobilegmao/utils/equipment_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class ModifyEquipmentScreen extends StatefulWidget {
  final Map<String, String>? equipmentData;
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
  // ✅ SUPPRIMÉ: selectedCodeParent
  String? selectedFeeder,
      selectedFamille,
      selectedZone,
      selectedEntity,
      selectedUnite,
      selectedCentreCharge;
  String? valueLongitude, valueLatitude;

  final _formKey = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();
  final _descriptionController = TextEditingController();

  Map<String, List<Map<String, dynamic>>> selectors = {};

  bool _isLoading = true, _hasError = false, _isUpdating = false;

  // ✅ AJOUTÉ: Nouveau flag pour le chargement complet
  bool _isFullyLoaded = false;
  int _totalAttributesToLoad = 0;
  int _attributesLoaded = 0;

  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _loadingAttributes = false;

  // ✅ SUPPRIMÉ: _initialCodeParent
  String? _initialFeeder,
      _initialFamille,
      _initialZone,
      _initialEntity,
      _initialUnite,
      _initialCentreCharge,
      _initialDescription;
  Map<String, String> _initialAttributeValues = {};
  bool _initialValuesSaved = false;

  RequiredFieldsConfig _requiredFieldsConfig = RequiredFieldsConfig.empty();

  static const String __logName = 'ModifyEquipmentScreen -';

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSelectors();
      if (widget.equipmentAttributes != null &&
          widget.equipmentAttributes!.isNotEmpty) {
        await _initializeAttributesFromParams();
      } else {
        await _loadEquipmentAttributes();
      }
      // ✅ AJOUTÉ: Marquer comme complètement chargé
      if (mounted) {
        setState(() => _isFullyLoaded = true);
      }
    });
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool _hasChanges() {
    if (selectedFeeder != _initialFeeder ||
        selectedFamille != _initialFamille ||
        selectedZone != _initialZone ||
        selectedEntity != _initialEntity ||
        selectedUnite != _initialUnite ||
        selectedCentreCharge != _initialCentreCharge ||
        _descriptionController.text.trim() != _initialDescription?.trim() ||
        _initialAttributeValues.length != selectedAttributeValues.length) {
      return true;
    }

    for (final entry in selectedAttributeValues.entries) {
      if ((entry.value) != (_initialAttributeValues[entry.key] ?? '')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadSelectors() async {
    setState(() => _isLoading = true);

    try {
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      selectors = await SelectorLoader.loadSelectors(
        equipmentProvider: equipmentProvider,
      );
      _initializeFields();
    } catch (e) {
      if (kDebugMode) print('❌ $__logName Erreur chargement sélecteurs: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    if (widget.equipmentData == null) return;
    final data = widget.equipmentData!;

    String? mapValueToDropdown(
      String? receivedValue,
      List<Map<String, dynamic>> availableItems,
    ) {
      if (receivedValue == null || receivedValue.isEmpty) return null;

      for (var item in availableItems) {
        final desc = item['description']?.toString() ?? '';
        final code = item['code']?.toString() ?? '';

        if (desc == receivedValue || code == receivedValue) {
          return desc.isNotEmpty ? desc : code;
        }
      }

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

    selectedFeeder = mapValueToDropdown(
      data['Feeder Description'],
      selectors['feeders'] ?? [],
    );
    selectedFamille = mapValueToDropdown(
      data['Famille'],
      selectors['familles'] ?? [],
    );
    selectedZone = mapValueToDropdown(data['Zone'], selectors['zones'] ?? []);
    selectedEntity = mapValueToDropdown(
      data['Entité'],
      selectors['entities'] ?? [],
    );
    selectedUnite = mapValueToDropdown(
      data['Unité'],
      selectors['unites'] ?? [],
    );
    selectedCentreCharge = mapValueToDropdown(
      data['Centre'],
      selectors['centreCharges'] ?? [],
    );
    _descriptionController.text = data['Description'] ?? '';
    valueLongitude = data['Longitude']?.toString() ?? '12311231';
    valueLatitude = data['Latitude']?.toString() ?? '12311231';

    if (!_initialValuesSaved) _saveInitialValues();
  }

  void _saveInitialValues() {
    if (_initialValuesSaved) return;

    _initialFeeder = selectedFeeder;
    _initialFamille = selectedFamille;
    _initialZone = selectedZone;
    _initialEntity = selectedEntity;
    _initialUnite = selectedUnite;
    _initialCentreCharge = selectedCentreCharge;
    _initialDescription = _descriptionController.text.trim();
    _initialAttributeValues = Map<String, String>.from(selectedAttributeValues);
    _initialValuesSaved = true;

    if (kDebugMode) print('✅ $__logName Valeurs initiales sauvegardées');
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
              'Modifier l\'équipement',
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
              onPressed: () {
                if (kDebugMode) {
                  print('⬅️ $__logName Retour');
                }
                Navigator.pop(context);
              },
              tooltip: 'Retour',
            ),
          ),
        ),
      ),
      body: Consumer<EquipmentProvider>(
        builder: (context, equipmentProvider, child) {
          // ✅ MODIFIÉ: Afficher le loader tant que pas complètement chargé
          if (_isLoading || !_isFullyLoaded) {
            return _buildLoadingState(responsive, spacing);
          }
          if (_hasError) return _buildErrorState(responsive, spacing);

          return SingleChildScrollView(
            child: Padding(
              padding: spacing.custom(all: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInformationsSection(responsive, spacing),
                    SizedBox(height: spacing.xlarge),
                    _buildParentInfoSection(responsive, spacing),
                    SizedBox(height: spacing.xlarge),
                    _buildPositioningSection(responsive, spacing),
                    SizedBox(height: spacing.medium),
                    _buildActionButtons(responsive, spacing),
                    SizedBox(height: spacing.xlarge),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ MODIFIÉ: Loader avec progression
  Widget _buildLoadingState(Responsive responsive, ResponsiveSpacing spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Loader circulaire
          SizedBox(
            width: responsive.spacing(60),
            height: responsive.spacing(60),
            child: CircularProgressIndicator(
              strokeWidth: responsive.spacing(4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.secondaryColor,
              ),
              // ✅ AJOUTÉ: Afficher la progression si disponible
              value:
                  _totalAttributesToLoad > 0
                      ? _attributesLoaded / _totalAttributesToLoad
                      : null,
            ),
          ),
          SizedBox(height: spacing.large),

          // ✅ Message de chargement
          Text(
            _getLoadingMessage(),
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
          ),

          // ✅ AJOUTÉ: Afficher la progression en texte
          if (_totalAttributesToLoad > 0) ...[
            SizedBox(height: spacing.small),
            Text(
              '$_attributesLoaded / $_totalAttributesToLoad attributs chargés',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                color: AppTheme.thirdColor,
                fontSize: responsive.sp(14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ AJOUTÉ: Message dynamique selon l'étape
  String _getLoadingMessage() {
    if (!_isFullyLoaded && _totalAttributesToLoad > 0) {
      return 'Chargement des valeurs...';
    }
    if (_loadingAttributes) {
      return 'Chargement des attributs...';
    }
    return 'Chargement des données...';
  }

  Widget _buildErrorState(Responsive responsive, ResponsiveSpacing spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryColor),
          SizedBox(height: spacing.medium),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(18),
            ),
          ),
          SizedBox(height: spacing.small),
          Text(
            'Impossible de charger les données',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(14),
            ),
          ),
          SizedBox(height: spacing.xlarge),
          PrimaryButton(
            text: 'Réessayer',
            icon: Icons.refresh,
            onPressed: _loadSelectors,
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsSection(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      children: [
        Tools.buildFieldset(context, 'Informations'),
        SizedBox(height: spacing.small),
        Row(
          children: [
            Expanded(
              child: Tools.buildText(
                context,
                label: 'Code',
                value:
                    widget.equipmentData?['Code'] ??
                    widget.equipmentData?['code'] ??
                    '#12345',
              ),
            ),
            SizedBox(width: spacing.small),
            Expanded(
              child: _buildDropdown(
                label: 'Famille',
                items: EquipmentHelpers.getSelectorsOptions(
                  selectors['familles'] ?? [],
                ),
                selectedValue: selectedFamille,
                onChanged: (v) {
                  setState(() => selectedFamille = v);
                  // ✅ AJOUT: Recharger la config si famille change
                  if (v != null) {
                    final familleCode = EquipmentHelpers.getCodeFromDescription(
                      v,
                      selectors['familles'] ?? [],
                    );
                    if (familleCode != null) {
                      setState(() {
                        _requiredFieldsConfig =
                            RequiredFieldsManager.getRequiredFields(
                              familleCode,
                            );
                      });
                    }
                  }
                },
                hintText: 'Rechercher une famille...',
                responsive: responsive,
                spacing: spacing,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.medium),
        _buildZoneEntityRow(responsive, spacing),
        SizedBox(height: spacing.medium),
        _buildUniteChargeRow(responsive, spacing),
        SizedBox(height: spacing.xlarge),

        // ✅ Description avec compteur
        EquipmentTextField(
          label: 'Description',
          hintText: 'Description de l\'équipement...',
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          isRequired: false,
          maxLength: 255,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          minLines: 2,
          showCounter: true,
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
      ],
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

    return 'Champs obligatoires pour cette famille :\n\n${fields.join('\n')}';
  }

  Widget _buildZoneEntityRow(Responsive responsive, ResponsiveSpacing spacing) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'Zone',
            items: EquipmentHelpers.getSelectorsOptions(
              selectors['zones'] ?? [],
            ),
            selectedValue: selectedZone,
            onChanged: (v) => setState(() => selectedZone = v),
            hintText: 'Rechercher une zone...',
            responsive: responsive,
            spacing: spacing,
          ),
        ),
        SizedBox(width: spacing.small),
        Expanded(
          child: _buildDropdown(
            label: 'Entité',
            items: EquipmentHelpers.getSelectorsOptions(
              selectors['entities'] ?? [],
            ),
            selectedValue: selectedEntity,
            onChanged: (v) => setState(() => selectedEntity = v),
            hintText: 'Rechercher une entité...',
            responsive: responsive,
            spacing: spacing,
          ),
        ),
      ],
    );
  }

  Widget _buildUniteChargeRow(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'Unité',
            items: EquipmentHelpers.getSelectorsOptions(
              selectors['unites'] ?? [],
            ),
            selectedValue: selectedUnite,
            onChanged: (v) => setState(() => selectedUnite = v),
            hintText: 'Rechercher une unité...',
            responsive: responsive,
            spacing: spacing,
          ),
        ),
        SizedBox(width: spacing.small),
        Expanded(
          child: _buildDropdown(
            label: 'Centre de Charge',
            items: EquipmentHelpers.getSelectorsOptions(
              selectors['centreCharges'] ?? [],
            ),
            selectedValue: selectedCentreCharge,
            onChanged: (v) => setState(() => selectedCentreCharge = v),
            hintText: 'Rechercher un centre...',
            responsive: responsive,
            spacing: spacing,
          ),
        ),
      ],
    );
  }

  Widget _buildParentInfoSection(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      children: [
        Tools.buildFieldset(context, 'Informations parents'),
        SizedBox(height: spacing.small),

        // ✅ MODIFIÉ: Feeder prend toute la largeur (suppression de Info Feeder)
        _buildDropdown(
          label: 'Feeder',
          items: EquipmentHelpers.getSelectorsOptions(
            selectors['feeders'] ?? [],
          ),
          selectedValue: selectedFeeder,
          onChanged: (v) => setState(() => selectedFeeder = v),
          hintText: 'Rechercher un feeder...',
          responsive: responsive,
          spacing: spacing,
        ),
      ],
    );
  }

  Widget _buildPositioningSection(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      children: [
        Tools.buildFieldset(context, 'Informations de positionnement'),
        SizedBox(height: spacing.small),
        Row(
          children: [
            Expanded(
              child: Tools.buildText(
                context,
                label: 'Longitude',
                value: valueLongitude ?? '12311231',
              ),
            ),
            SizedBox(width: spacing.small),
            Expanded(
              child: Tools.buildText(
                context,
                label: 'Latitude',
                value: valueLatitude ?? '12311231',
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.medium),
        _buildMapSection(responsive, spacing),
        SizedBox(height: spacing.medium),
        _buildAttributesButton(responsive, spacing),
      ],
    );
  }

  Widget _buildMapSection(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      width: double.infinity,
      height: responsive.spacing(200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.spacing(8)),
        image: const DecorationImage(
          image: AssetImage('assets/images/map.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: AppTheme.boxShadowColor,
            blurRadius: responsive.spacing(15),
            offset: Offset(0, responsive.spacing(4)),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
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
                Text(
                  'Position actuelle',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: responsive.sp(18),
                  ),
                ),
                SizedBox(height: spacing.small),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Toucher pour modifier',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      color: AppTheme.secondaryColor,
                      fontSize: responsive.sp(14),
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

  Widget _buildAttributesButton(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return GestureDetector(
      onTap: availableAttributes.isNotEmpty ? _showAttributesModal : null,
      child: Container(
        padding: spacing.custom(vertical: 12),
        child: Row(
          children: [
            Icon(
              availableAttributes.isNotEmpty ? Icons.edit : Icons.info_outline,
              color:
                  availableAttributes.isNotEmpty
                      ? AppTheme.secondaryColor
                      : AppTheme.thirdColor,
            ),
            SizedBox(width: spacing.small),
            Text(
              availableAttributes.isNotEmpty
                  ? 'Modifier les attributs (${availableAttributes.length})'
                  : 'Aucun attribut disponible',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.bold,
                color:
                    availableAttributes.isNotEmpty
                        ? AppTheme.secondaryColor
                        : AppTheme.thirdColor,
                fontSize: responsive.sp(16),
              ),
            ),
            SizedBox(width: spacing.tiny),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.thirdColor,
                margin: spacing.custom(top: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required Function(String?) onChanged,
    required String hintText,
    required Responsive responsive,
    required ResponsiveSpacing spacing,
  }) {
    return EquipmentDropdown(
      label: label,
      items: items,
      selectedValue: selectedValue,
      onChanged: (value) {
        onChanged(value);
        _onFieldChanged();
      },
      hintText: hintText,
    );
  }

  void _showAttributesModal() {
    if (availableAttributes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder:
                (_, setModalState) => AttributesModal(
                  availableAttributes: availableAttributes,
                  attributeValuesBySpec: attributeValuesBySpec,
                  selectedAttributeValues: selectedAttributeValues,
                  isLoading: _loadingAttributes,
                  onApply: () {
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
    );
  }

  Future<void> _loadAttributeSpecifications() async {
    // Compter les attributs à charger
    _totalAttributesToLoad =
        availableAttributes
            .where((attr) => attr.specification != null && attr.index != null)
            .length;
    _attributesLoaded = 0;

    if (mounted) setState(() {});

    for (final attr in availableAttributes) {
      if (attr.specification != null && attr.index != null) {
        final specKey = '${attr.specification}_${attr.index}';
        try {
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
              _attributesLoaded++;
            });
          }

          if (kDebugMode) {
            print(
              '📦 $__logName Valeurs chargées pour ${attr.name}: ${values.length} options',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ $__logName Erreur chargement valeurs pour ${attr.name}: $e',
            );
          }
          // Incrémenter quand même pour ne pas bloquer
          if (mounted) {
            setState(() => _attributesLoaded++);
          }
        }
      }
    }

    if (kDebugMode) {
      print('✅ $__logName Toutes les valeurs d\'attributs chargées');
    }
  }

  Future<void> _initializeAttributesFromParams() async {
    if (widget.equipmentAttributes == null ||
        widget.equipmentAttributes!.isEmpty) {
      return;
    }

    try {
      final convertedAttributes =
          widget.equipmentAttributes!
              .map(
                (attrData) => EquipmentAttribute(
                  id: attrData['id']?.toString(),
                  name: attrData['name']?.toString(),
                  value: attrData['value']?.toString() ?? '',
                  type: attrData['type']?.toString() ?? 'string',
                  specification: attrData['specification']?.toString(),
                  index: attrData['index']?.toString(),
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          availableAttributes = convertedAttributes;
          selectedAttributeValues.clear();
          for (final attr in convertedAttributes) {
            final safeId =
                attr.id ?? '${attr.name}_${attr.specification}_${attr.index}';
            selectedAttributeValues[safeId] = attr.value ?? '';
          }
          _loadingAttributes = false;
        });

        if (!_initialValuesSaved) _saveInitialValues();

        // ✅ MODIFIÉ: Attendre que toutes les valeurs soient chargées
        await _loadAttributeSpecifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur initialisation attributs: $e');
      }
      await _loadEquipmentAttributes();
    }
  }

  Future<void> _loadEquipmentAttributes() async {
    if (widget.equipmentData == null) return;

    setState(() => _loadingAttributes = true);

    try {
      final equipmentCode =
          widget.equipmentData!['Code'] ?? widget.equipmentData!['code'] ?? '';
      if (equipmentCode.isEmpty) return;

      final familleCode = EquipmentHelpers.getCodeFromDescription(
        selectedFamille,
        selectors['familles'] ?? [],
      );

      if (familleCode != null) {
        setState(() {
          _requiredFieldsConfig = RequiredFieldsManager.getRequiredFields(
            familleCode,
          );
        });

        if (kDebugMode) {
          print('📋 $__logName Champs requis chargés pour $familleCode');
        }
      }

      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      final attributes = await equipmentProvider.loadEquipmentAttributes(
        equipmentCode,
      );

      if (mounted && attributes.isNotEmpty) {
        setState(() {
          availableAttributes = attributes;
          selectedAttributeValues.clear();
          for (final attr in attributes) {
            final safeId =
                attr.id ?? '${attr.name}_${attr.specification}_${attr.index}';
            if (attr.value != null) {
              selectedAttributeValues[safeId] = attr.value!;
            }
          }
        });

        if (!_initialValuesSaved) _saveInitialValues();

        // ✅ MODIFIÉ: Attendre que toutes les valeurs soient chargées
        await _loadAttributeSpecifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement attributs: $e');
      }
    } finally {
      if (mounted) setState(() => _loadingAttributes = false);
    }
  }

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;

    // ✅ AJOUT: Validation des champs requis avant mise à jour
    if (!_canUpdateEquipment()) {
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
          selectedFeeder,
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
      final attributs = EquipmentHelpers.prepareAttributesForSave(
        availableAttributes,
        selectedAttributeValues,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );

      final cachedSelectors = equipmentProvider.cachedSelectors;

      final feederCode = SelectorLoader.extractCodeFromTypedSelectors(
        selectedFeeder,
        'feeders',
        cachedSelectors,
      );

      final updatedData = {
        'code':
            widget.equipmentData!['Code'] ??
            widget.equipmentData!['code'] ??
            '',
        // ✅ SUPPRIMÉ: 'code_parent': ...
        'famille': SelectorLoader.extractCodeFromTypedSelectors(
          selectedFamille,
          'familles',
          cachedSelectors,
        ),
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
        'centre_charge': SelectorLoader.extractCodeFromTypedSelectors(
          selectedCentreCharge,
          'centreCharges',
          cachedSelectors,
        ),
        'description': _descriptionController.text.trim(),
        'longitude': valueLongitude ?? '12311231',
        'latitude': valueLatitude ?? '12311231',
        'feeder': feederCode,
        'feeder_description': selectedFeeder,
        'created_by': authProvider.currentUser?.username ?? '',
        'attributs': attributs,
      };

      if (kDebugMode) {
        print('📤 $__logName Données de mise à jour:');
        print('   - feeder (code): ${updatedData['feeder']}');
        print('   - feeder_description: ${updatedData['feeder_description']}');
      }

      final equipmentId =
          widget.equipmentData!['id'] ?? widget.equipmentData!['ID'] ?? '';
      if (equipmentId.isEmpty) throw Exception('ID de l\'équipement manquant');

      await equipmentProvider.updateEquipment(equipmentId, updatedData);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await equipmentProvider.fetchEquipments(forceRefresh: false);
      }

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement modifié avec succès !',
          showAction: false,
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
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
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ✅ AJOUT: Méthode de validation
  bool _canUpdateEquipment() {
    if (selectedFamille == null) {
      return true; // Pas de famille = pas de validation
    }

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
        selectedFeeder,
        selectors['feeders'] ?? [],
      ),
      attributes: attributesForValidation,
      clientName: null,
      poste1: null,
      poste2: null,
    );

    return validation.isValid;
  }

  Widget _buildActionButtons(Responsive responsive, ResponsiveSpacing spacing) {
    final hasChanges = _hasChanges();
    final canUpdate = hasChanges && _canUpdateEquipment(); // ✅ AJOUT

    return Padding(
      padding: spacing.custom(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Annuler',
              onPressed: _isUpdating ? null : () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: spacing.medium),
          Expanded(
            child:
                _isUpdating
                    ? Container(
                      height: responsive.spacing(48),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor70,
                        borderRadius: BorderRadius.circular(
                          responsive.spacing(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: responsive.spacing(20),
                            height: responsive.spacing(20),
                            child: CircularProgressIndicator(
                              strokeWidth: responsive.spacing(2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.small),
                          Flexible(
                            child: Text(
                              'Modification...',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontMontserrat,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: responsive.sp(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      height: responsive.spacing(48),
                      decoration: BoxDecoration(
                        color:
                            canUpdate // ✅ MODIFIÉ
                                ? AppTheme.secondaryColor
                                : AppTheme.thirdColor50,
                        borderRadius: BorderRadius.circular(
                          responsive.spacing(8),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(8),
                          ),
                          onTap: canUpdate ? _handleUpdate : null, // ✅ MODIFIÉ
                          child: Container(
                            padding: spacing.custom(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.save,
                                  color:
                                      canUpdate // ✅ MODIFIÉ
                                          ? Colors.white
                                          : AppTheme.thirdColor,
                                  size: responsive.iconSize(18),
                                ),
                                SizedBox(width: spacing.small),
                                Flexible(
                                  child: Text(
                                    !hasChanges
                                        ? 'Aucun changement'
                                        : (!canUpdate
                                            ? 'Champs manquants'
                                            : 'Modifier'),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontMontserrat,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          canUpdate
                                              ? Colors.white
                                              : AppTheme.thirdColor,
                                      fontSize: responsive.sp(14),
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
