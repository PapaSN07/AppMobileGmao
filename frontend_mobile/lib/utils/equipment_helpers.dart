import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:flutter/foundation.dart';

class EquipmentHelpers {
  /// Convertit une description en code depuis une liste de données
  static String? getCodeFromDescription(
    String? description,
    List<Map<String, dynamic>> dataList,
  ) {
    if (description == null || description.isEmpty) return null;

    for (final item in dataList) {
      final itemDescription = item['description']?.toString() ?? '';
      final itemCode = item['code']?.toString() ?? '';

      if (itemDescription == description) {
        return itemCode;
      }
    }

    return description;
  }

  /// ✅ CORRIGÉ: Récupère le system_category depuis la description
  static String? getSystemCategoryFromDescription(
    String? description,
    List<Map<String, dynamic>> items,
  ) {
    if (description == null || description.isEmpty) return null;

    for (final item in items) {
      final itemDesc = item['description']?.toString() ?? '';
      final itemCode = item['code']?.toString() ?? '';

      // Chercher par description OU code
      if (itemDesc == description || itemCode == description) {
        // ✅ CORRECTION: Retourner system_category en PRIORITÉ
        final systemCategory = item['system_category']?.toString();
        final code = item['code']?.toString();

        if (kDebugMode) {
          print('✅ EquipmentHelpers - Correspondance trouvée:');
          print('   - Description: $itemDesc');
          print('   - Code: $code');
          print('   - System Category: $systemCategory');
        }

        // ✅ Priorité: system_category > code
        return systemCategory ?? code;
      }
    }

    // Fallback : recherche partielle
    for (final item in items) {
      final itemDesc = item['description']?.toString() ?? '';
      if (itemDesc.toLowerCase().contains(description.toLowerCase()) ||
          description.toLowerCase().contains(itemDesc.toLowerCase())) {
        final systemCategory = item['system_category']?.toString();
        final code = item['code']?.toString();

        if (kDebugMode) {
          print('⚠️ EquipmentHelpers - Correspondance partielle:');
          print('   - Description: $itemDesc');
          print('   - Code: $code');
          print('   - System Category: $systemCategory');
        }

        return systemCategory ?? code;
      }
    }

    if (kDebugMode) {
      print('❌ EquipmentHelpers - Aucune correspondance pour: "$description"');
    }

    return null;
  }

  /// Formate intelligemment une description
  static String formatDescription(String description) {
    final cleanDesc =
        description
            .replaceAll(RegExp(r'\bCABLE\b', caseSensitive: false), 'C.')
            .replaceAll(RegExp(r'\bCELLULE\b', caseSensitive: false), 'CELL.')
            .replaceAll(
              RegExp(r'\bTRANSFORMATEUR\b', caseSensitive: false),
              'TRANSFO',
            )
            .replaceAll(
              RegExp(r'\bDISTRIBUTION\b', caseSensitive: false),
              'DISTRIB',
            )
            .replaceAll(
              RegExp(r'\bSOUTERRAIN\b', caseSensitive: false),
              'SOUT.',
            )
            .replaceAll(RegExp(r'\bLIAISON\b', caseSensitive: false), 'LIAIS.')
            .replaceAll(
              RegExp(r'\bPROTECTION\b', caseSensitive: false),
              'PROT.',
            )
            .replaceAll(
              RegExp(r'\bTRONCONS DE\b', caseSensitive: false),
              'TRONC.',
            )
            .trim();

    return cleanDesc.length > 40
        ? '${cleanDesc.substring(0, 40)}...'
        : cleanDesc;
  }

  /// Prépare les attributs pour l'envoi au backend
  static List<Map<String, String>> prepareAttributesForSave(
    List<EquipmentAttribute> availableAttributes,
    Map<String, String> selectedAttributeValues,
  ) {
    final attributs = <Map<String, String>>[];

    for (final attribute in availableAttributes) {
      if (attribute.name != null) {
        final attributeId =
            attribute.id ??
            '${attribute.name}_${DateTime.now().millisecondsSinceEpoch}';
        final selectedValue = selectedAttributeValues[attributeId];
        final finalValue = selectedValue ?? attribute.value ?? '';
        final attributeType = determineAttributeType(attribute);

        attributs.add({
          'id': attributeId,
          'name': attribute.name!,
          'specification': attribute.specification ?? '',
          'index': attribute.index ?? '',
          'value': finalValue,
          'type': attributeType,
        });
      }
    }

    return attributs;
  }

  /// Détermine automatiquement le type d'un attribut
  static String determineAttributeType(EquipmentAttribute attribute) {
    final name = attribute.name?.toLowerCase() ?? '';
    final value = attribute.value ?? '';

    // Type select pour les dropdowns
    if (name.contains('famille') ||
        name.contains('zone') ||
        name.contains('entité') ||
        name.contains('entity') ||
        name.contains('feeder') ||
        name.contains('unite') ||
        name.contains('centre') ||
        name.contains('marque')) {
      return 'select';
    }

    // Type number pour coordonnées et valeurs techniques
    if (name.contains('longitude') ||
        name.contains('latitude') ||
        name.contains('coordonn') ||
        name.contains('position') ||
        name.contains('calibre') ||
        name.contains('tension')) {
      return 'number';
    }

    // Type text pour descriptions longues
    if (name.contains('description') ||
        name.contains('commentaire') ||
        name.contains('note') ||
        name.contains('remarque') ||
        name.contains('observation')) {
      return 'text';
    }

    // Détection basée sur la valeur
    if (value.isNotEmpty) {
      if (double.tryParse(value) != null) {
        return 'number';
      }
      if (value.length < 50 &&
          !value.contains(' ') &&
          value.toUpperCase() == value) {
        return 'select';
      }
      if (value.length > 100) {
        return 'text';
      }
    }

    return 'string';
  }

  /// Extrait les options depuis une liste de données
  static List<String> getSelectorsOptions(
    List<Map<String, dynamic>> data, {
    String codeKey = 'description',
  }) {
    return data
        .map((item) {
          final code = item[codeKey]?.toString().trim() ?? '';
          return code;
        })
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}
