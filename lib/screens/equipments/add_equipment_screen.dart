import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/widgets/notification_bar.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_form_fields.dart';
import 'package:appmobilegmao/utils/equipment_helpers.dart';
import 'package:appmobilegmao/utils/selector_loader.dart';
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

  String? selectedCodeParent,
      selectedFeeder,
      selectedFamille,
      selectedZone,
      selectedEntity,
      selectedUnite,
      selectedCentreCharge;
  late String generatedCode;

  List<EquipmentAttribute> availableAttributes = [];
  Map<String, List<EquipmentAttribute>> attributeValuesBySpec = {};
  Map<String, String> selectedAttributeValues = {};
  bool _loadingAttributes = false, _isUpdating = false, _isLoading = true;

  Map<String, List<Map<String, dynamic>>> selectors = {};

  static int _globalCounter = 0;
  static const String __logName = 'AddEquipmentScreen -';

  @override
  void initState() {
    super.initState();
    generatedCode = _generateUniqueEquipmentCode();

    if (kDebugMode) {
      print('🆕 $__logName Initialisation avec code: $generatedCode');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSelectors());
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();

    if (kDebugMode) {
      print('🗑️ $__logName Dispose');
    }

    super.dispose();
  }

  String _generateUniqueEquipmentCode() {
    final now = DateTime.now();
    final microTime = now.microsecondsSinceEpoch;
    _globalCounter = (_globalCounter + 1) % 999;
    final shortTimestamp = microTime.toString().substring(
      microTime.toString().length - 6,
    );
    final shortUuid = microTime.toRadixString(36).toUpperCase();
    final uuid =
        shortUuid.length >= 4
            ? shortUuid.substring(0, 4)
            : shortUuid.padRight(4, 'X');
    final counter = _globalCounter.toString().padLeft(3, '0');
    final code = 'EQ$shortTimestamp$uuid$counter';

    if (kDebugMode) {
      print('🔢 $__logName Code généré: $code');
    }

    return code;
  }

  Future<void> _loadSelectors() async {
    if (kDebugMode) {
      print('🔄 $__logName Début chargement sélecteurs...');
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
        print('✅ $__logName Sélecteurs chargés:');
        print('   - Familles: ${selectors['familles']?.length ?? 0}');
        print('   - Zones: ${selectors['zones']?.length ?? 0}');
        print('   - Entités: ${selectors['entities']?.length ?? 0}');
        print('   - Unités: ${selectors['unites']?.length ?? 0}');
        print('   - Centres: ${selectors['centreCharges']?.length ?? 0}');
        print('   - Feeders: ${selectors['feeders']?.length ?? 0}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement sélecteurs: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);

        if (kDebugMode) {
          print('✅ $__logName Chargement terminé');
        }
      }
    }
  }

  Future<void> _loadAttributesForFamily(String familleDescription) async {
    if (familleDescription.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ $__logName Description famille vide, abandon chargement attributs',
        );
      }
      return;
    }

    final familleCode = EquipmentHelpers.getCodeFromDescription(
      familleDescription,
      selectors['familles'] ?? [],
    );

    if (familleCode == null || familleCode.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ $__logName Impossible de trouver le system_category pour: $familleDescription',
        );
      }
      return;
    }

    if (kDebugMode) {
      print('🔍 $__logName Chargement attributs pour famille:');
      print('   - Description: $familleDescription');
      print('   - System Category: $familleCode');
    }

    setState(() {
      _loadingAttributes = true;
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

              if (kDebugMode) {
                print('   - Attribut ${attr.name}: "${attr.value}"');
              }
            }
          }
        });

        await _loadAttributeSpecifications();
      } else {
        if (kDebugMode) {
          print('📋 $__logName Aucun attribut disponible pour cette famille');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur chargement attributs: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAttributes = false);

        if (kDebugMode) {
          print('✅ $__logName Chargement attributs terminé');
        }
      }
    }
  }

  Future<void> _loadAttributeSpecifications() async {
    if (kDebugMode) {
      print('🔄 $__logName Chargement spécifications attributs...');
    }

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

          if (kDebugMode) {
            print('   ✅ Spec $specKey: ${values.length} valeurs');
          }

          if (mounted) setState(() => attributeValuesBySpec[specKey] = values);
        } catch (e) {
          if (kDebugMode) {
            print('   ❌ Erreur spec $specKey: $e');
          }
        }
      }
    }

    if (kDebugMode) {
      print(
        '✅ $__logName Spécifications chargées: ${attributeValuesBySpec.length}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      // ✅ MODIFIÉ: Augmenter la hauteur de l'AppBar
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(responsive.spacing(70)), // ✅ Hauteur augmentée
        child: AppBar(
          titleSpacing: 0,
          title: Padding(
            padding: spacing.custom(left: 4, right: 16), // ✅ AJOUTÉ: Espacement à gauche
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
            padding: spacing.custom(left: 16, right: 8), // ✅ MODIFIÉ: Espacement augmenté
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
                          generatedCode: generatedCode,
                          selectedFamille: selectedFamille,
                          selectedZone: selectedZone,
                          selectedEntity: selectedEntity,
                          selectedUnite: selectedUnite,
                          selectedCentreCharge: selectedCentreCharge,
                          selectedCodeParent: selectedCodeParent,
                          selectedFeeder: selectedFeeder,
                          descriptionController: _descriptionController,
                          descriptionFocusNode: _descriptionFocusNode,
                          familles: selectors['familles'] ?? [],
                          zones: selectors['zones'] ?? [],
                          entities: selectors['entities'] ?? [],
                          unites: selectors['unites'] ?? [],
                          centreCharges: selectors['centreCharges'] ?? [],
                          feeders: selectors['feeders'] ?? [],
                          onFamilleChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Famille changée: $v');
                            }
                            setState(() {
                              selectedFamille = v;
                              if (v != null) {
                                _loadAttributesForFamily(v);
                              }
                            });
                          },
                          onZoneChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Zone changée: $v');
                            }
                            setState(() => selectedZone = v);
                          },
                          onEntityChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Entité changée: $v');
                            }
                            setState(() => selectedEntity = v);
                          },
                          onUniteChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Unité changée: $v');
                            }
                            setState(() => selectedUnite = v);
                          },
                          onCentreChargeChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Centre changé: $v');
                            }
                            setState(() => selectedCentreCharge = v);
                          },
                          onCodeParentChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Code parent changé: $v');
                            }
                            setState(() => selectedCodeParent = v);
                          },
                          onFeederChanged: (v) {
                            if (kDebugMode) {
                              print('🔄 $__logName Feeder changé: $v');
                            }
                            setState(() => selectedFeeder = v);
                          },
                          showAttributesButton: true,
                          attributesCount: availableAttributes.length,
                          onAttributesPressed: () {
                            if (kDebugMode) {
                              print('🔘 $__logName Bouton attributs pressé');
                            }
                            _showAttributesModal();
                          },
                        ),
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

  void _showAttributesModal() {
    final responsive = context.responsive;
    final spacing = context.spacing;

    final bool isFamilleSelected =
        selectedFamille != null && selectedFamille!.isNotEmpty;

    if (!isFamilleSelected) {
      if (kDebugMode) {
        print('⚠️ $__logName Aucune famille sélectionnée, modal annulé');
      }

      NotificationService.showError(
        context,
        title: '⚠️ Attention',
        message: 'Veuillez sélectionner une famille d\'abord',
        showAction: false,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (availableAttributes.isEmpty) {
      if (kDebugMode) {
        print('⚠️ $__logName Aucun attribut disponible pour cette famille');
      }

      NotificationService.showError(
        context,
        title: 'ℹ️ Information',
        message: 'Aucun attribut disponible pour cette famille',
        showAction: false,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (kDebugMode) {
      print(
        '✅ $__logName Ouverture modal avec ${availableAttributes.length} attributs',
      );
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
                            onPressed: () {
                              if (kDebugMode) {
                                print(
                                  '⬅️ $__logName Fermeture modal attributs',
                                );
                              }
                              Navigator.pop(context);
                            },
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
                          Padding(
                            padding: spacing.custom(horizontal: 20),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 2,
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
                                SizedBox(width: spacing.medium),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 1,
                                    color: AppTheme.thirdColor,
                                    margin: EdgeInsets.only(
                                      top: spacing.medium,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing.medium),
                                const Expanded(
                                  flex: 3,
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
                                    onPressed: () {
                                      if (kDebugMode) {
                                        print(
                                          '❌ $__logName Annulation modal attributs',
                                        );
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                                SizedBox(width: spacing.medium),
                                Expanded(
                                  child: PrimaryButton(
                                    text: 'Appliquer',
                                    icon: Icons.check,
                                    onPressed: () {
                                      if (kDebugMode) {
                                        print(
                                          '✅ $__logName Attributs appliqués: ${selectedAttributeValues.length}',
                                        );
                                        selectedAttributeValues.forEach((
                                          key,
                                          value,
                                        ) {
                                          if (kDebugMode) {
                                            print('   - $key: "$value"');
                                          }
                                        });
                                      }

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
                          SizedBox(height: spacing.medium),
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

    if (optionsSet.isEmpty) {
      optionsSet.add('');
    }

    final options =
        optionsSet.where((opt) => opt.isNotEmpty).toList()
          ..sort()
          ..add('');

    final safeAttributeId =
        attribute.id ??
        '${attribute.name}_${attribute.specification}_${attribute.index}';
    final currentValue =
        selectedAttributeValues[safeAttributeId] ?? attribute.value;

    if (kDebugMode) {
      print('🔍 $__logName Attribut ${attribute.name}:');
      print('   - ID: $safeAttributeId');
      print('   - Valeur actuelle: "$currentValue"');
      print('   - Options: ${options.length} (${options.join(', ')})');
    }

    return Padding(
      padding: spacing.custom(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                if (kDebugMode) {
                  print(
                    '🔄 $__logName Changement attribut ${attribute.name}: "$currentValue" → "$value"',
                  );
                }

                setModalState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });

                setState(() {
                  selectedAttributeValues[safeAttributeId] = value ?? '';
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: options.length > 5,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                    ),
                    contentPadding: spacing.custom(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                menuProps: MenuProps(
                  backgroundColor: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(responsive.spacing(8)),
                ),
                itemBuilder: (context, item, isSelected) {
                  final isOriginalValue = item == attribute.value;
                  final displayText = item.isEmpty ? '(Vide)' : item;

                  return Container(
                    padding: spacing.custom(horizontal: 16, vertical: 12),
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
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.secondaryColor,
                            size: responsive.iconSize(16),
                          ),
                        if (isSelected) SizedBox(width: spacing.small),
                        if (isOriginalValue && !isSelected)
                          Icon(
                            Icons.star,
                            color: AppTheme.thirdColor,
                            size: responsive.iconSize(16),
                          ),
                        if (isOriginalValue && !isSelected)
                          SizedBox(width: spacing.small),
                        if (item.isEmpty && !isSelected)
                          Icon(
                            Icons.clear,
                            color: AppTheme.thirdColor,
                            size: responsive.iconSize(16),
                          ),
                        if (item.isEmpty && !isSelected)
                          SizedBox(width: spacing.small),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: displayText,
                                  style: TextStyle(
                                    fontSize: responsive.sp(14),
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
                                if (isOriginalValue && !isSelected)
                                  TextSpan(
                                    text: ' (défaut)',
                                    style: TextStyle(
                                      fontSize: responsive.sp(12),
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
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Sélectionner...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.spacing(8)),
                    borderSide: const BorderSide(color: AppTheme.thirdColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.spacing(8)),
                    borderSide: const BorderSide(
                      color: AppTheme.secondaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: spacing.custom(horizontal: 12, vertical: 8),
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              itemAsString: (String item) => item.isEmpty ? '(Vide)' : item,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive responsive, ResponsiveSpacing spacing) {
    final canSave = selectedFamille != null && selectedFamille!.isNotEmpty;

    return Padding(
      padding: spacing.custom(vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              text: 'Annuler',
              onPressed:
                  _isUpdating
                      ? null
                      : () {
                        if (kDebugMode) {
                          print('❌ $__logName Annulation');
                        }
                        Navigator.pop(context);
                      },
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
                          Text(
                            'Ajout en cours...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.sp(16),
                            ),
                          ),
                        ],
                      ),
                    )
                    : PrimaryButton(
                      text: canSave ? 'Ajouter' : 'Remplissez les champs',
                      icon: Icons.add,
                      onPressed: canSave ? _handleSave : null,
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (kDebugMode) {
      print('💾 $__logName Début sauvegarde...');
    }

    if (!_formKey.currentState!.validate() || _isUpdating) {
      if (kDebugMode) {
        print('⚠️ $__logName Validation échouée ou déjà en cours');
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

      final equipmentData = {
        'codeParent': SelectorLoader.extractCodeFromTypedSelectors(
          selectedCodeParent,
          'feeders',
          cachedSelectors,
        ),
        'code': generatedCode,
        'feeder': SelectorLoader.extractCodeFromTypedSelectors(
          selectedFeeder,
          'feeders',
          cachedSelectors,
        ),
        'infoFeeder': SelectorLoader.extractCodeFromTypedSelectors(
          selectedFeeder,
          'feeders',
          cachedSelectors,
        ),
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
        'centreCharge': SelectorLoader.extractCodeFromTypedSelectors(
          selectedCentreCharge,
          'centreCharges',
          cachedSelectors,
        ),
        'description': _descriptionController.text.trim(),
        'longitude': '12311231',
        'latitude': '12311231',
        'attributs': attributs,
        'createdBy': authProvider.currentUser?.username,
      };

      if (kDebugMode) {
        print('📊 $__logName DONNÉES À ENVOYER:');
        print('   - Code: ${equipmentData['code']}');
        print('   - Code Parent: ${equipmentData['codeParent']}');
        print('   - Feeder: ${equipmentData['feeder']}');
        print('   - Famille (system_category): ${equipmentData['famille']}');
        print('   - Zone: ${equipmentData['zone']}');
        print('   - Entity: ${equipmentData['entity']}');
        print('   - Unite: ${equipmentData['unite']}');
        print('   - Centre Charge: ${equipmentData['centreCharge']}');
        print('   - Description: ${equipmentData['description']}');
        print('   - Attributs: ${attributs.length} éléments');
        print('   - Créé par: ${equipmentData['createdBy']}');
      }

      await equipmentProvider.addEquipment(equipmentData);

      if (kDebugMode) {
        print('✅ $__logName Équipement ajouté avec succès');
      }

      if (mounted && Navigator.canPop(context)) {
        NotificationService.showSuccess(
          context,
          title: '🎉 Succès',
          message: 'Équipement ajouté avec succès !',
          showAction: false,
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur lors de la sauvegarde: $e');
      }

      if (mounted) {
        NotificationService.showError(
          context,
          title: '❌ Erreur',
          message: 'Impossible d\'ajouter l\'équipement: $e',
          showAction: true,
          actionText: 'Réessayer',
          onActionPressed: _handleSave,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);

        if (kDebugMode) {
          print('🏁 $__logName Fin sauvegarde (isUpdating: false)');
        }
      }
    }
  }
}
