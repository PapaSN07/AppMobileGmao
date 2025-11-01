import 'package:appmobilegmao/utils/codification/codification_rules.dart';
import 'package:appmobilegmao/utils/codification/codification_validator.dart';
import 'package:flutter/foundation.dart';

/// Résultat de la codification
class CodificationResult {
  final bool success;
  final String? code;
  final String? errorMessage;
  final String? description;

  CodificationResult({
    required this.success,
    this.code,
    this.errorMessage,
    this.description,
  });

  CodificationResult.success(String generatedCode, {String? desc})
    : this(success: true, code: generatedCode, description: desc);

  CodificationResult.error(String message)
    : this(success: false, errorMessage: message);

  @override
  String toString() {
    return success
        ? 'CodificationResult.success(code: $code, desc: $description)'
        : 'CodificationResult.error($errorMessage)';
  }
}

/// Modèle pour les données d'entrée de codification
class CodificationInput {
  final String famille;
  final String? feeder;
  final String? abbreviation;
  final String? naturePoste;
  final String? codeH;
  final String? tension;
  final String? poste1;
  final String? poste2;
  final String? typeEquipement;
  final String? clientName;
  final String? celluleType;
  final int? counter;

  CodificationInput({
    required this.famille,
    this.feeder,
    this.abbreviation,
    this.naturePoste,
    this.codeH,
    this.tension,
    this.poste1,
    this.poste2,
    this.typeEquipement,
    this.clientName,
    this.celluleType,
    this.counter,
  });

  CodificationInput copyWith({
    String? famille,
    String? feeder,
    String? abbreviation,
    String? naturePoste,
    String? codeH,
    String? tension,
    String? poste1,
    String? poste2,
    String? typeEquipement,
    String? clientName,
    String? celluleType,
    int? counter,
  }) {
    return CodificationInput(
      famille: famille ?? this.famille,
      feeder: feeder ?? this.feeder,
      abbreviation: abbreviation ?? this.abbreviation,
      naturePoste: naturePoste ?? this.naturePoste,
      codeH: codeH ?? this.codeH,
      tension: tension ?? this.tension,
      poste1: poste1 ?? this.poste1,
      poste2: poste2 ?? this.poste2,
      typeEquipement: typeEquipement ?? this.typeEquipement,
      clientName: clientName ?? this.clientName,
      celluleType: celluleType ?? this.celluleType,
      counter: counter ?? this.counter,
    );
  }

  Map<String, dynamic> toJson() => {
    'famille': famille,
    'feeder': feeder,
    'abbreviation': abbreviation,
    'naturePoste': naturePoste,
    'codeH': codeH,
    'tension': tension,
    'poste1': poste1,
    'poste2': poste2,
    'typeEquipement': typeEquipement,
    'clientName': clientName,
    'celluleType': celluleType,
    'counter': counter,
  };

  @override
  String toString() {
    if (kDebugMode) {
      return 'CodificationInput(${toJson()})';
    }
    return 'CodificationInput(famille: $famille)';
  }
}

/// Service de codification - Point d'entrée unique
class EquipmentCodification {
  static const String _logName = 'EquipmentCodification -';

  /// ✅ Méthode unique pour générer un code
  static CodificationResult generateCode(CodificationInput input) {
    if (kDebugMode) {
      print('🔢 $_logName Génération code pour: ${input.famille}');
    }

    // ✅ Validation
    final validation = CodificationValidator.validate(input);
    if (!validation.isValid) {
      return CodificationResult.error(validation.errorMessage!);
    }

    // ✅ Déléguer la génération aux règles
    return CodificationRules.generateCode(input);
  }
}
