import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class EquipmentDropdown extends StatelessWidget {
  final String label;
  final String? msgError;
  final List<String> items;
  final String? selectedValue;
  final Function(String?)? onChanged;
  final String hintText;
  final bool isRequired;

  const EquipmentDropdown({
    super.key,
    required this.label,
    this.msgError,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.hintText = 'Rechercher ou sélectionner...',
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    final cleanItems = items.toSet().toList()..sort();
    if (cleanItems.isEmpty) {
      cleanItems.add('Aucun élément disponible');
    }

    return DropdownSearch<String>(
      items: cleanItems,
      selectedItem: selectedValue,
      onChanged: onChanged,
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
              borderRadius: BorderRadius.circular(
                responsive.spacing(8),
              ), // ✅ Border radius responsive
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                responsive.spacing(8),
              ), // ✅ Border radius responsive
              borderSide: const BorderSide(
                color: AppTheme.secondaryColor,
                width: 2,
              ),
            ),
            contentPadding: spacing.custom(
              horizontal: 12,
              vertical: 8,
            ), // ✅ Padding responsive
          ),
        ),
        menuProps: MenuProps(
          backgroundColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(
            responsive.spacing(8),
          ), // ✅ Border radius responsive
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            padding: spacing.custom(
              horizontal: 16,
              vertical: 12,
            ), // ✅ Padding responsive
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.secondaryColor10 : null,
              border: Border(
                bottom: BorderSide(color: AppTheme.thirdColor30, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: responsive.iconSize(18), // ✅ Icône responsive
                  ),
                if (isSelected)
                  SizedBox(width: spacing.small), // ✅ Espacement responsive
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: responsive.sp(14), // ✅ Texte responsive
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
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: responsive.sp(16), // ✅ Texte responsive
          ),
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.secondaryColor,
          ),
          contentPadding: spacing.custom(vertical: 8), // ✅ Padding responsive
        ),
      ),
      validator:
          isRequired
              ? (value) {
                if (value == null ||
                    value.isEmpty ||
                    value == 'Aucun élément disponible') {
                  return msgError ?? 'Veuillez sélectionner une valeur';
                }
                return null;
              }
              : null,
      itemAsString:
          (String item) =>
              item.length > 30 ? '${item.substring(0, 30)}...' : item,
    );
  }
}
