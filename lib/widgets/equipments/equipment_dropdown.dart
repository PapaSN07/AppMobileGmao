import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.secondaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        menuProps: MenuProps(
          backgroundColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.secondaryColor10 : null,
              border: Border(
                bottom: BorderSide(color: AppTheme.thirdColor30, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: 18,
                  ),
                if (isSelected) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
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
          labelStyle: const TextStyle(
            color: AppTheme.secondaryColor,
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.0),
          ),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.secondaryColor,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
