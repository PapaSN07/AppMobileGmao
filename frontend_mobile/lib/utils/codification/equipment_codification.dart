import 'package:appmobilegmao/utils/codification/codification_input.dart';
import 'package:appmobilegmao/utils/codification/codification_rules.dart';
import 'package:appmobilegmao/utils/codification/codification_validator.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service de codification - Point d'entrée unique
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
