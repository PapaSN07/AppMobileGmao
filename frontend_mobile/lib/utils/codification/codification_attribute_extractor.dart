import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:flutter/foundation.dart';

class CodificationAttributeExtractor {
  static const String _logName = 'CodificationAttributeExtractor';

  /// ✅ CORRIGÉ: Recherche Nature du poste (PRIVE/PUBLIC/MIXTE)
  static String? extractNaturePoste(
    List<EquipmentAttribute> attributes,
    Map<String, String> selectedValues,
  ) {
    // Chercher "Statut" qui contient la nature du poste
    final attr = attributes.firstWhere((a) {
      final name = a.name?.toUpperCase() ?? '';
      return name.contains('STATUT') ||
          (name.contains('NATURE') && !name.contains('CELLULE'));
    }, orElse: () => EquipmentAttribute());

    if (attr.id != null && selectedValues.containsKey(attr.id!)) {
      final value = selectedValues[attr.id!]?.toUpperCase() ?? '';

      if (kDebugMode) {
        print('$_logName Nature extraite: "$value" (attribut: ${attr.name})');
      }

      // Mapper les valeurs
      if (value.contains('PRIV')) return 'PRIVE';
      if (value.contains('PUBLIC')) return 'PUBLIC';
      if (value.contains('MIXTE')) return 'MIXTE';

      return value;
    }

    if (kDebugMode) {
      print('⚠️ $_logName Nature non trouvée dans les attributs');
    }

    return null;
  }

  /// ✅ CORRIGÉ: Code H (Genie civil)
  static String? extractCodeH(
    List<EquipmentAttribute> attributes,
    Map<String, String> selectedValues,
  ) {
    // "Genie civil" contient le code H (H59/H61)
    final attr = attributes.firstWhere((a) {
      final name = a.name?.toUpperCase() ?? '';
      return name.contains('GENIE CIVIL') ||
          name.contains('CODE H') ||
          name.contains('H59') ||
          name.contains('H61');
    }, orElse: () => EquipmentAttribute());

    if (attr.id != null && selectedValues.containsKey(attr.id!)) {
      final value = selectedValues[attr.id!]?.toUpperCase() ?? '';

      if (kDebugMode) {
        print('$_logName Code H extrait: "$value" (attribut: ${attr.name})');
      }

      if (value.contains('H59')) return 'H59';
      if (value.contains('H61')) return 'H61';

      return value;
    }

    if (kDebugMode) {
      print('⚠️ $_logName Code H non trouvé dans les attributs');
    }

    return null;
  }

  /// ✅ CORRIGÉ: Tension (Structure poste)
  static String? extractTension(
    List<EquipmentAttribute> attributes,
    Map<String, String> selectedValues,
  ) {
    // "Structure poste" contient la tension (30KV/6,6KV)
    final attr = attributes.firstWhere((a) {
      final name = a.name?.toUpperCase() ?? '';
      return name.contains('STRUCTURE') ||
          name.contains('TENSION') ||
          name.contains('30KV') ||
          name.contains('6,6KV');
    }, orElse: () => EquipmentAttribute());

    if (attr.id != null && selectedValues.containsKey(attr.id!)) {
      final value = selectedValues[attr.id!]?.toUpperCase().replaceAll(' ', '');

      if (kDebugMode) {
        print('$_logName Tension extraite: "$value" (attribut: ${attr.name})');
      }

      if (value!.contains('30') && value.contains('KV')) return '30KV';
      if (value.contains('6') && value.contains('KV')) return '6,6KV';

      return value;
    }

    if (kDebugMode) {
      print('⚠️ $_logName Tension non trouvée dans les attributs');
    }

    return null;
  }

  /// ✅ Type de cellule
  static String? extractCelluleType(
    List<EquipmentAttribute> attributes,
    Map<String, String> selectedValues,
  ) {
    final attr = attributes.firstWhere((a) {
      final name = a.name?.toUpperCase() ?? '';
      return name.contains('TYPE') && name.contains('CELLULE');
    }, orElse: () => EquipmentAttribute());

    if (attr.id != null && selectedValues.containsKey(attr.id!)) {
      final value = selectedValues[attr.id!]?.toUpperCase() ?? '';

      if (kDebugMode) {
        print(
          '$_logName Type cellule extrait: "$value" (attribut: ${attr.name})',
        );
      }

      if (value.contains('OUVERTE') || value == 'O') return 'O';
      if (value.contains('FERMEE') ||
          value.contains('FERMÉE') ||
          value == 'F') {
        return 'F';
      }

      return value;
    }

    return null;
  }

  /// ✅ Abréviation depuis feeder
  static String extractAbbreviationFromFeeder(String? feederDescription) {
    if (feederDescription == null || feederDescription.isEmpty) {
      return 'XXXXX';
    }

    // Supprimer tout sauf lettres
    final cleaned = feederDescription.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final abbr = cleaned.toUpperCase();

    if (abbr.isEmpty) return 'XXXXX';

    final result =
        abbr.length > 5 ? abbr.substring(0, 5) : abbr.padRight(5, 'X');

    if (kDebugMode) {
      print(
        '$_logName Abréviation extraite: "$result" depuis "$feederDescription"',
      );
    }

    return result;
  }
}
