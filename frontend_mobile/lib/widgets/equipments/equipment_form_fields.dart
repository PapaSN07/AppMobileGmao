import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_dropdown.dart';
import 'package:appmobilegmao/utils/equipment_helpers.dart';

class EquipmentFormFields extends StatelessWidget {
  final String? generatedCode;
  final String? selectedFamille;
  final String? selectedZone;
  final String? selectedEntity;
  final String? selectedUnite;
  final String? selectedCentreCharge;
  final String? selectedCodeParent;
  final String? selectedFeeder;
  final TextEditingController descriptionController;
  final FocusNode descriptionFocusNode;
  final List<Map<String, dynamic>> familles;
  final List<Map<String, dynamic>> zones;
  final List<Map<String, dynamic>> entities;
  final List<Map<String, dynamic>> unites;
  final List<Map<String, dynamic>> centreCharges;
  final List<Map<String, dynamic>> feeders;
  final Function(String?)? onFamilleChanged;
  final Function(String?)? onZoneChanged;
  final Function(String?)? onEntityChanged;
  final Function(String?)? onUniteChanged;
  final Function(String?)? onCentreChargeChanged;
  final Function(String?)? onCodeParentChanged;
  final Function(String?)? onFeederChanged;
  final bool isCodeEditable;
  final bool showAttributesButton;
  final VoidCallback? onAttributesPressed;
  final int attributesCount;

  const EquipmentFormFields({
    super.key,
    this.generatedCode,
    required this.selectedFamille,
    required this.selectedZone,
    required this.selectedEntity,
    required this.selectedUnite,
    required this.selectedCentreCharge,
    required this.selectedCodeParent,
    required this.selectedFeeder,
    required this.descriptionController,
    required this.descriptionFocusNode,
    required this.familles,
    required this.zones,
    required this.entities,
    required this.unites,
    required this.centreCharges,
    required this.feeders,
    this.onFamilleChanged,
    this.onZoneChanged,
    this.onEntityChanged,
    this.onUniteChanged,
    this.onCentreChargeChanged,
    this.onCodeParentChanged,
    this.onFeederChanged,
    this.isCodeEditable = false,
    this.showAttributesButton = false,
    this.onAttributesPressed,
    this.attributesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Informations
        Tools.buildFieldset('Informations'),
        const SizedBox(height: 10),
        _buildCodeAndFamilleRow(),
        const SizedBox(height: 20),
        _buildZoneAndEntityRow(),
        const SizedBox(height: 20),
        _buildUniteAndChargeRow(),
        const SizedBox(height: 20),
        Tools.buildTextField(
          label: 'Description',
          msgError: 'Veuillez entrer la description',
          focusNode: descriptionFocusNode,
          controller: descriptionController,
          isRequired: false,
        ),
        const SizedBox(height: 40),

        // Section Informations parents
        Tools.buildFieldset('Informations parents'),
        const SizedBox(height: 10),
        EquipmentDropdown(
          label: 'Code Parent',
          items: EquipmentHelpers.getSelectorsOptions(feeders, codeKey: 'code'),
          selectedValue: selectedCodeParent,
          onChanged: onCodeParentChanged,
          hintText: 'Rechercher ou sélectionner un code parent...',
          isRequired: false,
        ),
        const SizedBox(height: 20),
        _buildFeederRow(),

        // Bouton attributs si disponible
        if (showAttributesButton) ...[
          const SizedBox(height: 40),
          _buildAttributesButton(),
        ],
      ],
    );
  }

  Widget _buildCodeAndFamilleRow() {
    return Row(
      children: [
        Expanded(
          child:
              isCodeEditable
                  ? Tools.buildTextField(
                    label: 'Code',
                    msgError: 'Veuillez entrer le code',
                    controller: TextEditingController(text: generatedCode),
                    isRequired: true,
                  )
                  : Tools.buildText(label: 'Code', value: generatedCode ?? ''),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: EquipmentDropdown(
            label: 'Famille',
            msgError: 'Veuillez sélectionner une famille',
            items: EquipmentHelpers.getSelectorsOptions(familles),
            selectedValue: selectedFamille,
            onChanged: onFamilleChanged,
            hintText: 'Rechercher une famille...',
            isRequired: true,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneAndEntityRow() {
    return Row(
      children: [
        Expanded(
          child: EquipmentDropdown(
            label: 'Zone',
            items: EquipmentHelpers.getSelectorsOptions(zones),
            selectedValue: selectedZone,
            onChanged: onZoneChanged,
            hintText: 'Rechercher une zone...',
            isRequired: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: EquipmentDropdown(
            label: 'Entité',
            msgError: 'Veuillez sélectionner une entité',
            items: EquipmentHelpers.getSelectorsOptions(entities),
            selectedValue: selectedEntity,
            onChanged: onEntityChanged,
            hintText: 'Rechercher une entité...',
            isRequired: true,
          ),
        ),
      ],
    );
  }

  Widget _buildUniteAndChargeRow() {
    return Row(
      children: [
        Expanded(
          child: EquipmentDropdown(
            label: 'Unité',
            items: EquipmentHelpers.getSelectorsOptions(unites),
            selectedValue: selectedUnite,
            onChanged: onUniteChanged,
            hintText: 'Rechercher une unité...',
            isRequired: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: EquipmentDropdown(
            label: 'Centre de Charge',
            items: EquipmentHelpers.getSelectorsOptions(centreCharges),
            selectedValue: selectedCentreCharge,
            onChanged: onCentreChargeChanged,
            hintText: 'Rechercher un centre...',
            isRequired: false,
          ),
        ),
      ],
    );
  }

  Widget _buildFeederRow() {
    return Row(
      children: [
        Expanded(
          child: EquipmentDropdown(
            label: 'Feeder',
            items: EquipmentHelpers.getSelectorsOptions(feeders),
            selectedValue: selectedFeeder,
            onChanged: onFeederChanged,
            hintText: 'Rechercher un feeder...',
            isRequired: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tools.buildText(
            label: 'Info Feeder',
            value: EquipmentHelpers.formatDescription(selectedFeeder ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesButton() {
    return GestureDetector(
      onTap: attributesCount > 0 ? onAttributesPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              attributesCount > 0 ? Icons.edit : Icons.info_outline,
              color:
                  attributesCount > 0
                      ? AppTheme.secondaryColor
                      : AppTheme.thirdColor,
            ),
            const SizedBox(width: 8),
            Text(
              attributesCount > 0
                  ? 'Modifier les attributs ($attributesCount)'
                  : 'Aucun attribut disponible',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.bold,
                color:
                    attributesCount > 0
                        ? AppTheme.secondaryColor
                        : AppTheme.thirdColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.thirdColor,
                margin: const EdgeInsets.only(top: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
