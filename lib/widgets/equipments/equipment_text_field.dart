import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

/// ✅ TextField harmonisé avec EquipmentDropdown (Single Responsibility)
/// Respecte les mêmes dimensions, espacements et comportements
class EquipmentTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isRequired;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLines;

  const EquipmentTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.isRequired = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Label identique à EquipmentDropdown
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(16),
            ),
            children: [
              if (isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.tiny),

        // ✅ TextField avec hauteur et style identiques à DropdownSearch
        SizedBox(
          // ✅ IMPORTANT: Même hauteur que DropdownSearch (≈ 48px)
          height: responsive.spacing(48),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: textCapitalization,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            enabled: enabled,
            maxLines: maxLines,
            // ✅ Style de texte identique
            style: TextStyle(
              color: enabled ? AppTheme.secondaryColor : AppTheme.thirdColor,
              fontFamily: AppTheme.fontRoboto,
              fontSize: responsive.sp(14),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppTheme.thirdColor,
                fontFamily: AppTheme.fontRoboto,
                fontSize: responsive.sp(14),
              ),
              // ✅ Padding vertical identique à DropdownSearch
              contentPadding: spacing.custom(vertical: 12, horizontal: 0),
              counterText: maxLength != null ? '' : null,

              // ✅ Borders identiques à DropdownSearch
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor, width: 1.0),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor, width: 1.0),
              ),
              disabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.thirdColor, width: 0.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor,
                  width: 2.0,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),

              // ✅ Icône harmonisée (comme dropdown_button)
              suffixIcon: Icon(
                Icons.edit,
                color: enabled ? AppTheme.secondaryColor : AppTheme.thirdColor,
                size: responsive.iconSize(20),
              ),

              // ✅ Style d'erreur cohérent
              errorStyle: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontSize: responsive.sp(12),
                color: Colors.red,
              ),
            ),
            // ✅ Validation par défaut
            validator:
                validator ??
                (isRequired
                    ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ce champ est requis';
                      }
                      return null;
                    }
                    : null),
          ),
        ),
      ],
    );
  }
}
