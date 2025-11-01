import 'package:appmobilegmao/utils/codification/codification_input.dart';
import 'package:appmobilegmao/utils/codification/codification_rules.dart';

/// Résultat de validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> missingFields;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.missingFields = const [],
  });

  ValidationResult.success() : this(isValid: true);

  ValidationResult.error(String message, [List<String>? fields])
    : this(isValid: false, errorMessage: message, missingFields: fields ?? []);
}

/// Validateur de codification
class CodificationValidator {
  /// Valide une entrée de codification
  static ValidationResult validate(CodificationInput input) {
    final missingFields = <String>[];

    // ✅ Validation famille (obligatoire)
    if (input.famille.isEmpty) {
      return ValidationResult.error(
        'La famille d\'équipement est obligatoire',
        ['famille'],
      );
    }

    // ✅ CORRIGÉ: Validation feeder (obligatoire sauf pour POSTE_HTA_BT)
    if (CodificationRules.requiresFeeder(input.famille)) {
      if (input.feeder == null || input.feeder!.isEmpty) {
        missingFields.add('feeder');
      }
    }

    // ✅ Validation spécifique POSTES HTA/BT
    if (CodificationRules.requiresNaturePoste(input.famille)) {
      if (input.feeder == null || input.feeder!.isEmpty) {
        missingFields.add('feeder');
      }
      if (input.naturePoste == null || input.naturePoste!.isEmpty) {
        missingFields.add('naturePoste');
      }
      if (input.codeH == null || input.codeH!.isEmpty) {
        missingFields.add('codeH');
      }
      if (input.tension == null || input.tension!.isEmpty) {
        missingFields.add('tension');
      }
      if (input.abbreviation == null || input.abbreviation!.isEmpty) {
        missingFields.add('abbreviation');
      }
    }

    // ✅ Validation cellules (DEPART/PROTECTION)
    if (CodificationRules.requiresCelluleType(input.famille)) {
      if (input.celluleType == null || input.celluleType!.isEmpty) {
        missingFields.add('celluleType');
      }
    }

    // ✅ Validation DEPART_UP2
    if (CodificationRules.requiresClientName(input.famille)) {
      if (input.clientName == null || input.clientName!.isEmpty) {
        missingFields.add('clientName');
      }
    }

    // ✅ Validation tronçons et supports
    if (CodificationRules.requiresPosteNames(input.famille)) {
      if (input.poste1 == null || input.poste1!.isEmpty) {
        missingFields.add('poste1');
      }
      if (input.poste2 == null || input.poste2!.isEmpty) {
        missingFields.add('poste2');
      }
      if (input.typeEquipement == null || input.typeEquipement!.isEmpty) {
        missingFields.add('typeEquipement');
      }
    }

    // ✅ Retour du résultat
    if (missingFields.isNotEmpty) {
      return ValidationResult.error(
        'Champs manquants : ${missingFields.join(', ')}',
        missingFields,
      );
    }

    return ValidationResult.success();
  }

  /// Valide un feeder (format LM suivi de 4 chiffres)
  static bool validateFeeder(String? feeder) {
    if (feeder == null || feeder.isEmpty) return false;
    final regex = RegExp(r'^[A-Z]{2}\d{4}$');
    return regex.hasMatch(feeder.toUpperCase());
  }

  /// Valide une abréviation (3-5 caractères)
  static bool validateAbbreviation(String? abbr) {
    if (abbr == null || abbr.isEmpty) return false;
    return abbr.length >= 3 && abbr.length <= 5;
  }

  /// Valide un nom de poste (3-5 caractères)
  static bool validatePosteName(String? name) {
    if (name == null || name.isEmpty) return false;
    return name.length >= 3 && name.length <= 5;
  }
}
