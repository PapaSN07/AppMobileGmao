import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class AttributesModal extends StatelessWidget {
  final List<EquipmentAttribute> availableAttributes;
  final Map<String, List<EquipmentAttribute>> attributeValuesBySpec;
  final Map<String, String> selectedAttributeValues;
  final bool isLoading;
  final VoidCallback onApply;

  const AttributesModal({
    super.key,
    required this.availableAttributes,
    required this.attributeValuesBySpec,
    required this.selectedAttributeValues,
    required this.isLoading,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      height: responsive.hp(80), // ✅ Hauteur responsive
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            responsive.spacing(30),
          ), // ✅ Border radius responsive
          topRight: Radius.circular(
            responsive.spacing(30),
          ), // ✅ Border radius responsive
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: spacing.custom(vertical: 12), // ✅ Margin responsive
            height: responsive.spacing(4), // ✅ Hauteur responsive
            width: responsive.spacing(40), // ✅ Largeur responsive
            decoration: BoxDecoration(
              color: AppTheme.thirdColor,
              borderRadius: BorderRadius.circular(
                responsive.spacing(2),
              ), // ✅ Border radius responsive
            ),
          ),

          // Header
          Padding(
            padding: spacing.custom(horizontal: 20), // ✅ Padding responsive
            child: Row(
              children: [
                SizedBox(
                  width: responsive.spacing(64), // ✅ Largeur responsive
                  height: responsive.spacing(34), // ✅ Hauteur responsive
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(
                        responsive.spacing(64),
                        responsive.spacing(34),
                      ), // ✅ Minimum size responsive
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: responsive.iconSize(20), // ✅ Icône responsive
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: spacing.medium), // ✅ Espacement responsive
                Expanded(
                  child: Text(
                    'Attributs',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMontserrat,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                      fontSize: responsive.sp(20), // ✅ Texte responsive
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: spacing.medium), // ✅ Espacement responsive
          // Loading ou contenu
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                  strokeWidth: responsive.spacing(4), // ✅ Épaisseur responsive
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Liste des attributs
                  Expanded(
                    child: ListView.builder(
                      padding: spacing.custom(
                        horizontal: 20,
                      ), // ✅ Padding responsive
                      itemCount: availableAttributes.length,
                      itemBuilder: (context, index) {
                        return _buildAttributeRow(
                          availableAttributes[index],
                          context,
                          responsive,
                          spacing,
                        );
                      },
                    ),
                  ),

                  // Boutons
                  Padding(
                    padding: spacing.allPadding, // ✅ Padding responsive
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Annuler',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(
                          width: spacing.medium,
                        ), // ✅ Espacement responsive
                        Expanded(
                          child: PrimaryButton(
                            text: 'Appliquer',
                            icon: Icons.check,
                            onPressed: onApply,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(
    EquipmentAttribute attribute,
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    final specKey = '${attribute.specification}_${attribute.index}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];
    final options =
        availableValues.map((a) => a.value ?? '').toSet().toList()..sort();
    final currentValue =
        selectedAttributeValues[attribute.id ?? ''] ?? attribute.value;

    return Padding(
      padding: spacing.custom(bottom: 20), // ✅ Padding responsive
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              attribute.name ?? 'Attribut',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: responsive.sp(16), // ✅ Texte responsive
              ),
            ),
          ),
          SizedBox(width: spacing.medium), // ✅ Espacement responsive
          Expanded(
            flex: 3,
            child: DropdownSearch<String>(
              items: options,
              selectedItem: currentValue,
              onChanged: (value) {
                if (attribute.id != null) {
                  selectedAttributeValues[attribute.id!] = value ?? '';
                }
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Sélectionner...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsive.spacing(8),
                    ), // ✅ Border radius responsive
                  ),
                  contentPadding: spacing.custom(
                    horizontal: 12,
                    vertical: 8,
                  ), // ✅ Padding responsive
                ),
              ),
              itemAsString: (String item) => item.isEmpty ? '(Vide)' : item,
            ),
          ),
        ],
      ),
    );
  }
}
