import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

/// ✅ TextField harmonisé avec EquipmentDropdown (Single Responsibility)
/// Respecte les mêmes dimensions, espacements et comportements
class EquipmentTextField extends StatefulWidget {
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
  final int? minLines;
  final bool showCounter;

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
    this.minLines,
    this.showCounter = false,
  });

  @override
  State<EquipmentTextField> createState() => _EquipmentTextFieldState();
}

class _EquipmentTextFieldState extends State<EquipmentTextField> {
  // ✅ AJOUT: Variable locale pour compter les caractères
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    // ✅ AJOUT: Initialiser avec la longueur actuelle
    _currentLength = widget.controller?.text.length ?? 0;
    // ✅ AJOUT: Écouter les changements du controller
    widget.controller?.addListener(_updateCounter);
  }

  @override
  void dispose() {
    // ✅ AJOUT: Nettoyer le listener
    widget.controller?.removeListener(_updateCounter);
    super.dispose();
  }

  // ✅ AJOUT: Méthode pour mettre à jour le compteur
  void _updateCounter() {
    if (mounted) {
      setState(() {
        _currentLength = widget.controller?.text.length ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    // ✅ Déterminer si c'est un textarea (multiline)
    final isTextarea = (widget.maxLines ?? 1) > 1 || widget.minLines != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Label identique à EquipmentDropdown
        RichText(
          text: TextSpan(
            text: widget.label,
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(16),
            ),
            children: [
              if (widget.isRequired)
                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: spacing.tiny),

        // ✅ TextField avec hauteur adaptative
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          // ✅ Style de texte identique
          style: TextStyle(
            color:
                widget.enabled ? AppTheme.secondaryColor : AppTheme.thirdColor,
            fontFamily: AppTheme.fontRoboto,
            fontSize: responsive.sp(14),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppTheme.thirdColor,
              fontFamily: AppTheme.fontRoboto,
              fontSize: responsive.sp(14),
            ),
            // ✅ Padding adapté selon le type
            contentPadding:
                isTextarea
                    ? spacing.custom(vertical: 12, horizontal: 12)
                    : spacing.custom(vertical: 12, horizontal: 0),

            // ✅ CORRIGÉ: Utiliser _currentLength au lieu de controller.text.length
            counterText:
                widget.showCounter && widget.maxLength != null
                    ? '$_currentLength/${widget.maxLength}'
                    : (widget.maxLength != null ? '' : null),
            counterStyle: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontSize: responsive.sp(12),
              color: _getCounterColor(_currentLength, widget.maxLength),
            ),

            // ✅ Borders adaptés selon le type
            border:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.thirdColor,
                        width: 1.0,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.thirdColor,
                        width: 1.0,
                      ),
                    ),
            enabledBorder:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.thirdColor,
                        width: 1.0,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.thirdColor,
                        width: 1.0,
                      ),
                    ),
            disabledBorder:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.thirdColor,
                        width: 0.5,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.thirdColor,
                        width: 0.5,
                      ),
                    ),
            focusedBorder:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 2.0,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 2.0,
                      ),
                    ),
            errorBorder:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
            focusedErrorBorder:
                isTextarea
                    ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(8),
                      ),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    )
                    : const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),

            // ✅ Icône uniquement pour les champs simples
            suffixIcon:
                !isTextarea
                    ? Icon(
                      Icons.edit,
                      color:
                          widget.enabled
                              ? AppTheme.secondaryColor
                              : AppTheme.thirdColor,
                      size: responsive.iconSize(20),
                    )
                    : null,

            // ✅ Style d'erreur cohérent
            errorStyle: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontSize: responsive.sp(12),
              color: Colors.red,
            ),
          ),
          // ✅ Validation par défaut
          validator:
              widget.validator ??
              (widget.isRequired
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  }
                  : null),
        ),
      ],
    );
  }

  /// ✅ Couleur dynamique du compteur selon le nombre de caractères
  Color _getCounterColor(int currentLength, int? maxLength) {
    if (maxLength == null) return AppTheme.thirdColor;

    final ratio = currentLength / maxLength;
    if (ratio >= 0.9) return Colors.red;
    if (ratio >= 0.7) return Colors.orange;
    return AppTheme.thirdColor;
  }
}
