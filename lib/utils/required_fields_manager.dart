import 'package:appmobilegmao/utils/codification/codification_rules.dart';

/// ✅ Gestionnaire centralisé des champs requis (Single Responsibility)
class RequiredFieldsManager {
  /// Récupère les champs requis pour une famille donnée
  static RequiredFieldsConfig getRequiredFields(String? familleCode) {
    if (familleCode == null || familleCode.isEmpty) {
      return RequiredFieldsConfig.empty();
    }

    final normalized = CodificationRules.normalizeFamily(familleCode);

    return RequiredFieldsConfig(
      famille: normalized,
      requiresFeeder: CodificationRules.requiresFeeder(normalized),
      requiresNaturePoste: CodificationRules.requiresNaturePoste(normalized),
      requiresCodeH: CodificationRules.requiresCodeH(normalized),
      requiresTension: CodificationRules.requiresTension(normalized),
      requiresCelluleType: CodificationRules.requiresCelluleType(normalized),
      requiresClientName: CodificationRules.requiresClientName(normalized),
      requiresPosteNames: CodificationRules.requiresPosteNames(normalized),
    );
  }

  /// Valide si tous les champs requis sont remplis
  static ValidationFieldsResult validateRequiredFields({
    required RequiredFieldsConfig config,
    required String? feeder,
    required List<Map<String, String>> attributes,
    required String? clientName,
    required String? poste1,
    required String? poste2,
  }) {
    final missingFields = <String>[];

    if (config.requiresFeeder && (feeder == null || feeder.isEmpty)) {
      missingFields.add('Feeder');
    }

    if (config.requiresNaturePoste) {
      final hasNature = attributes.any(
        (attr) =>
            attr['name']?.toUpperCase().contains('STATUT') == true &&
            attr['value']?.isNotEmpty == true,
      );
      if (!hasNature) missingFields.add('Nature du poste (Statut)');
    }

    if (config.requiresCodeH) {
      final hasCodeH = attributes.any(
        (attr) =>
            attr['name']?.toUpperCase().contains('GENIE CIVIL') == true &&
            attr['value']?.isNotEmpty == true,
      );
      if (!hasCodeH) missingFields.add('Code H (Genie civil)');
    }

    if (config.requiresTension) {
      final hasTension = attributes.any(
        (attr) =>
            attr['name']?.toUpperCase().contains('STRUCTURE') == true &&
            attr['value']?.isNotEmpty == true,
      );
      if (!hasTension) missingFields.add('Tension (Structure poste)');
    }

    if (config.requiresCelluleType) {
      final hasCellule = attributes.any(
        (attr) =>
            attr['name']?.toUpperCase().contains('TYPE') == true &&
            attr['name']?.toUpperCase().contains('CELLULE') == true &&
            attr['value']?.isNotEmpty == true,
      );
      if (!hasCellule) missingFields.add('Type de cellule');
    }

    if (config.requiresClientName &&
        (clientName == null || clientName.isEmpty)) {
      missingFields.add('Nom du client');
    }

    if (config.requiresPosteNames) {
      if (poste1 == null || poste1.isEmpty) missingFields.add('Poste 1');
      if (poste2 == null || poste2.isEmpty) missingFields.add('Poste 2');
    }

    return ValidationFieldsResult(
      isValid: missingFields.isEmpty,
      missingFields: missingFields,
    );
  }
}

/// Configuration des champs requis pour une famille
class RequiredFieldsConfig {
  final String famille;
  final bool requiresFeeder;
  final bool requiresNaturePoste;
  final bool requiresCodeH;
  final bool requiresTension;
  final bool requiresCelluleType;
  final bool requiresClientName;
  final bool requiresPosteNames;

  const RequiredFieldsConfig({
    required this.famille,
    required this.requiresFeeder,
    required this.requiresNaturePoste,
    required this.requiresCodeH,
    required this.requiresTension,
    required this.requiresCelluleType,
    required this.requiresClientName,
    required this.requiresPosteNames,
  });

  factory RequiredFieldsConfig.empty() {
    return const RequiredFieldsConfig(
      famille: '',
      requiresFeeder: false,
      requiresNaturePoste: false,
      requiresCodeH: false,
      requiresTension: false,
      requiresCelluleType: false,
      requiresClientName: false,
      requiresPosteNames: false,
    );
  }

  bool get hasRequiredAttributes =>
      requiresNaturePoste ||
      requiresCodeH ||
      requiresTension ||
      requiresCelluleType;
}

/// Résultat de la validation des champs
class ValidationFieldsResult {
  final bool isValid;
  final List<String> missingFields;

  const ValidationFieldsResult({
    required this.isValid,
    required this.missingFields,
  });

  String get errorMessage {
    if (isValid) return '';
    return 'Champs obligatoires manquants :\n${missingFields.map((f) => '• $f').join('\n')}';
  }
}
