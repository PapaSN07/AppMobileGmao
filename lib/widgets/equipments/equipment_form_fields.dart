import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/tools.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_dropdown.dart';
import 'package:appmobilegmao/utils/equipment_helpers.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

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
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      children: [
        // Section Informations
        Tools.buildFieldset(context, 'Informations'), // ✅ Context ajouté
        SizedBox(height: spacing.small), // ✅ Espacement responsive
        _buildCodeAndFamilleRow(
          context,
          responsive,
          spacing,
        ), // ✅ Paramètres ajoutés
        SizedBox(height: spacing.medium), // ✅ Espacement responsive
        _buildZoneAndEntityRow(
          context,
          responsive,
          spacing,
        ), // ✅ Paramètres ajoutés
        SizedBox(height: spacing.medium), // ✅ Espacement responsive
        _buildUniteAndChargeRow(
          context,
          responsive,
          spacing,
        ), // ✅ Paramètres ajoutés
        SizedBox(height: spacing.medium), // ✅ Espacement responsive
        Tools.buildTextField(
          context: context, // ✅ Context ajouté
          label: 'Description',
          msgError: 'Veuillez entrer la description',
          focusNode: descriptionFocusNode,
          controller: descriptionController,
          isRequired: false,
        ),
        SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
        // Section Informations parents
        Tools.buildFieldset(
          context,
          'Informations parents',
        ), // ✅ Context ajouté
        SizedBox(height: spacing.small), // ✅ Espacement responsive
        EquipmentDropdown(
          label: 'Code Parent',
          items: EquipmentHelpers.getSelectorsOptions(feeders, codeKey: 'code'),
          selectedValue: selectedCodeParent,
          onChanged: onCodeParentChanged,
          hintText: 'Rechercher ou sélectionner un code parent...',
          isRequired: false,
        ),
        SizedBox(height: spacing.medium), // ✅ Espacement responsive
        _buildFeederRow(context, responsive, spacing), // ✅ Paramètres ajoutés
        // Bouton attributs si disponible
        if (showAttributesButton) ...[
          SizedBox(height: spacing.xlarge), // ✅ Espacement responsive
          _buildAttributesButton(
            context,
            responsive,
            spacing,
          ), // ✅ Paramètres ajoutés
        ],
      ],
    );
  }

  Widget _buildCodeAndFamilleRow(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child:
              isCodeEditable
                  ? Tools.buildTextField(
                    context: context, // ✅ Context ajouté
                    label: 'Code',
                    msgError: 'Veuillez entrer le code',
                    controller: TextEditingController(text: generatedCode),
                    isRequired: true,
                  )
                  : Tools.buildText(
                    context,
                    label: 'Code',
                    value: generatedCode ?? '',
                  ), // ✅ Context ajouté
        ),
        SizedBox(width: spacing.small), // ✅ Espacement responsive
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

  Widget _buildZoneAndEntityRow(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
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
        SizedBox(width: spacing.small), // ✅ Espacement responsive
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

  Widget _buildUniteAndChargeRow(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
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
        SizedBox(width: spacing.small), // ✅ Espacement responsive
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

  Widget _buildFeederRow(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
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
        SizedBox(width: spacing.small), // ✅ Espacement responsive
        Expanded(
          child: Tools.buildText(
            context, // ✅ Context ajouté
            label: 'Info Feeder',
            value: EquipmentHelpers.formatDescription(selectedFeeder ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesButton(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return GestureDetector(
      onTap: attributesCount > 0 ? onAttributesPressed : null,
      child: Container(
        padding: spacing.custom(vertical: 12), // ✅ Padding responsive
        child: Row(
          children: [
            Icon(
              attributesCount > 0 ? Icons.edit : Icons.info_outline,
              color:
                  attributesCount > 0
                      ? AppTheme.secondaryColor
                      : AppTheme.thirdColor,
              size: responsive.iconSize(16), // ✅ Icône responsive
            ),
            SizedBox(width: spacing.small), // ✅ Espacement responsive
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
                fontSize: responsive.sp(16), // ✅ Texte responsive
              ),
            ),
            SizedBox(width: spacing.tiny), // ✅ Espacement responsive
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.thirdColor,
                margin: EdgeInsets.only(
                  top: spacing.medium,
                ), // ✅ Margin responsive
              ),
            ),
          ],
        ),
      ),
    );
  }
}
