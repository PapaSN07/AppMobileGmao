import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CodificationFields extends StatelessWidget {
  final TextEditingController abbreviationController;
  final FocusNode abbreviationFocusNode;
  final Map<String, bool> requiredFields;
  final String? selectedNature;
  final String? selectedCodeH;
  final String? selectedTension;
  final String? selectedPoste1;
  final String? selectedPoste2;
  final String? selectedTypeCode;
  final String? selectedCelluleType; // ✅ AJOUT : O/F pour cellules
  final String? selectedClientName; // ✅ AJOUT : Nom client pour UP2
  final Function(String?) onNatureChanged;
  final Function(String?) onCodeHChanged;
  final Function(String?) onTensionChanged;
  final Function(String?) onPoste1Changed;
  final Function(String?) onPoste2Changed;
  final Function(String?) onTypeCodeChanged;
  final Function(String?) onCelluleTypeChanged; // ✅ AJOUT
  final Function(String?) onClientNameChanged; // ✅ AJOUT

  const CodificationFields({
    super.key,
    required this.abbreviationController,
    required this.abbreviationFocusNode,
    required this.requiredFields,
    this.selectedNature,
    this.selectedCodeH,
    this.selectedTension,
    this.selectedPoste1,
    this.selectedPoste2,
    this.selectedTypeCode,
    this.selectedCelluleType,
    this.selectedClientName,
    required this.onNatureChanged,
    required this.onCodeHChanged,
    required this.onTensionChanged,
    required this.onPoste1Changed,
    required this.onPoste2Changed,
    required this.onTypeCodeChanged,
    required this.onCelluleTypeChanged,
    required this.onClientNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Champ ABRÉVIATION (obligatoire)
        _buildAbbreviationField(responsive, spacing),

        if (requiredFields['nature'] == true) ...[
          SizedBox(height: spacing.large),
          _buildNatureField(responsive, spacing),
        ],

        if (requiredFields['codeH'] == true) ...[
          SizedBox(height: spacing.large),
          _buildCodeHField(responsive, spacing),
        ],

        if (requiredFields['tension'] == true) ...[
          SizedBox(height: spacing.large),
          _buildTensionField(responsive, spacing),
        ],

        if (requiredFields['celluleType'] == true) ...[
          SizedBox(height: spacing.large),
          _buildCelluleTypeField(responsive, spacing),
        ],

        if (requiredFields['poste1'] == true) ...[
          SizedBox(height: spacing.large),
          _buildPoste1Field(responsive, spacing),
        ],

        if (requiredFields['poste2'] == true) ...[
          SizedBox(height: spacing.large),
          _buildPoste2Field(responsive, spacing),
        ],

        if (requiredFields['typeCode'] == true) ...[
          SizedBox(height: spacing.large),
          _buildTypeCodeField(responsive, spacing),
        ],

        if (requiredFields['clientName'] == true) ...[
          SizedBox(height: spacing.large),
          _buildClientNameField(responsive, spacing),
        ],
      ],
    );
  }

  Widget _buildAbbreviationField(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Abréviation ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        TextFormField(
          controller: abbreviationController,
          focusNode: abbreviationFocusNode,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          decoration: InputDecoration(
            hintText: 'Ex: BOUN2, CARTE, etc.',
            hintStyle: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              color: AppTheme.thirdColor,
              fontSize: responsive.sp(14),
            ),
            filled: true,
            fillColor: Colors.white,
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
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'abréviation est obligatoire';
            }
            if (value.length < 3) {
              return 'Minimum 3 caractères';
            }
            return null;
          },
        ),
        SizedBox(height: spacing.tiny),
        Text(
          'Abréviation de l\'équipement (3-5 caractères)',
          style: TextStyle(
            fontFamily: AppTheme.fontRoboto,
            color: AppTheme.thirdColor,
            fontSize: responsive.sp(12),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildNatureField(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Nature du poste ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        DropdownSearch<String>(
          items: const ['Privé', 'Public', 'Mixte'],
          selectedItem: selectedNature,
          onChanged: onNatureChanged,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Sélectionner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeHField(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Code H ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        DropdownSearch<String>(
          items: const ['H59', 'H61'],
          selectedItem: selectedCodeH,
          onChanged: onCodeHChanged,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Sélectionner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTensionField(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Tension ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        DropdownSearch<String>(
          items: const ['30KV', '6,6KV'],
          selectedItem: selectedTension,
          onChanged: onTensionChanged,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Sélectionner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Champ type de cellule (O/F)
  Widget _buildCelluleTypeField(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Type de cellule ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        DropdownSearch<String>(
          items: const ['Ouverte (O)', 'Fermée (F)'],
          selectedItem: selectedCelluleType,
          onChanged: onCelluleTypeChanged,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Sélectionner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoste1Field(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Premier poste ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        TextFormField(
          initialValue: selectedPoste1,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          onChanged: onPoste1Changed,
          decoration: InputDecoration(
            hintText: 'Ex: BOUN2',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le premier poste est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPoste2Field(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Second poste ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        TextFormField(
          initialValue: selectedPoste2,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          onChanged: onPoste2Changed,
          decoration: InputDecoration(
            hintText: 'Ex: CARTE',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le second poste est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeCodeField(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Type ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        DropdownSearch<String>(
          items: const ['T (Tronçon)', 'S (Support)'],
          selectedItem: selectedTypeCode,
          onChanged: onTypeCodeChanged,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: 'Sélectionner...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Champ nom client pour UP2
  Widget _buildClientNameField(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Nom du client ',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(16),
            ),
            children: const [
              TextSpan(text: '*', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.small),
        TextFormField(
          initialValue: selectedClientName,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          onChanged: onClientNameChanged,
          decoration: InputDecoration(
            hintText: 'Ex: MAMAD',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du client est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }
}
