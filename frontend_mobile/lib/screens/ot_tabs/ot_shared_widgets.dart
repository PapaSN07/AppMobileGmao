import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class EmployeFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final bool readOnly;
  final bool enabled;
  final Color? backgroundColor;
  final VoidCallback? onDateTap;
  final Function(String)? onChanged;

  const EmployeFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.readOnly = false,
    this.enabled = true,
    this.backgroundColor,
    this.onDateTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
            fontSize: responsive.sp(13),
          ),
        ),
        SizedBox(height: spacing.tiny),
        Container(
          decoration:
              backgroundColor != null
                  ? BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  )
                  : null,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly || isDateField,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(13),
                  ),
                  decoration: InputDecoration(
                    contentPadding: spacing.custom(vertical: 8, horizontal: 8),
                    border:
                        backgroundColor == null
                            ? const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            )
                            : InputBorder.none,
                  ),
                ),
              ),
              if (hasDropdown)
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(20),
                    ),
                  ),
                ),
              if (isDateField)
                InkWell(
                  onTap: onDateTap,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.secondaryColor,
                      size: responsive.iconSize(18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ActionIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          color: const Color(0xFF0F1B80),
          size: responsive.iconSize(20),
        ),
      ),
    );
  }
}

class ActionSearchBar extends StatelessWidget {
  const ActionSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class MaterielActionBar extends StatelessWidget {
  final VoidCallback onAddTap;

  const MaterielActionBar({super.key, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasDropdown;
  final bool isDateField;
  final VoidCallback? onDropdownTap;

  const FormField({
    super.key,
    required this.label,
    required this.controller,
    this.hasDropdown = false,
    this.isDateField = false,
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label du champ en bleu
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F1B80), // Bleu
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Champ de saisie avec icône dropdown ou calendrier
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly:
                      isDateField, // Seul le champ date est en lecture seule
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E), // Gris clair pour la valeur
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onTap: isDateField ? () => _selectDate(context) : null,
                ),
              ),
              if (isDateField)
                InkWell(
                  onTap: () => _selectDate(context),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF0F1B80),
                    size: 20,
                  ),
                )
              else if (hasDropdown)
                InkWell(
                  onTap: onDropdownTap ?? () => _showDropdownOptions(context),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0F1B80),
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F1B80), // Couleur bleue
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _showDropdownOptions(BuildContext context) {
    // Pour l'instant, affiche un message simple
    // Plus tard, on pourra afficher une liste de choix spécifiques
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner $label',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1B80),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Options à venir...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
