import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.thirdColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Text(
                    'Attributs',
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

          const SizedBox(height: 20),

          // Loading ou contenu
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryColor,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Header colonnes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 1,
                            color: AppTheme.thirdColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Liste des attributs
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: availableAttributes.length,
                      itemBuilder: (context, index) {
                        return _buildAttributeRow(
                          availableAttributes[index],
                          context,
                        );
                      },
                    ),
                  ),

                  // Boutons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: 'Annuler',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
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
  ) {
    final specKey = '${attribute.specification}_${attribute.index}';
    final availableValues = attributeValuesBySpec[specKey] ?? [];
    final options =
        availableValues.map((a) => a.value ?? '').toSet().toList()..sort();
    final currentValue =
        selectedAttributeValues[attribute.id ?? ''] ?? attribute.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              attribute.name ?? 'Attribut',
              style: const TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
}
