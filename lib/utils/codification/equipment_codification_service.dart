import 'package:appmobilegmao/utils/codification/codification_input.dart';
import 'package:appmobilegmao/utils/codification/codification_rules.dart';
import 'package:flutter/foundation.dart';

/// ✅ Service simplifié - Façade pour la génération de codes
class EquipmentCodificationService {
  static const String _logName = 'EquipmentCodificationService';

  // ✅ AJOUT: Compteur statique pour la numérotation
  static final Map<String, int> _counters = {};

  /// ✅ Méthode principale : génère le code d'un équipement
  static CodificationResult generateEquipmentCode({
    required String familleCode,
    required String abbreviation,
    String? feeder,
    String? nature,
    String? codeH,
    String? tension,
    String? poste1,
    String? poste2,
    String? typeCode,
    String? clientName,
    String? celluleType,
  }) {
    try {
      if (kDebugMode) {
        print('🔄 $_logName Génération code pour: $familleCode');
        print('   - Abréviation: $abbreviation');
        print('   - Feeder: ${feeder ?? "N/A"}');
      }

      // ✅ AJOUT: Récupérer/incrémenter le compteur
      final counterKey = '$familleCode-${feeder ?? 'default'}';
      _counters[counterKey] = (_counters[counterKey] ?? 0) + 1;
      final counter = _counters[counterKey]!;

      // ✅ Créer l'input
      final input = CodificationInput(
        famille: familleCode,
        abbreviation: abbreviation,
        feeder: feeder,
        naturePoste: nature,
        codeH: codeH,
        tension: tension,
        poste1: poste1,
        poste2: poste2,
        typeEquipement: typeCode,
        clientName: clientName,
        celluleType: celluleType,
        counter: counter, // ✅ AJOUT
      );

      // ✅ Déléguer à EquipmentCodification
      return EquipmentCodification.generateCode(input);
    } catch (e) {
      if (kDebugMode) {
        print('❌ $_logName Erreur: $e');
      }
      return CodificationResult.error('Erreur: $e');
    }
  }

  /// ✅ Réinitialise les compteurs (pour tests)
  static void resetCounters() {
    _counters.clear();
  }

  /// ✅ Récupère les champs requis pour une famille
  static Map<String, bool> getRequiredFields(String familleCode) {
    return {
      'feeder': CodificationRules.requiresFeeder(familleCode),
      'nature': CodificationRules.requiresNaturePoste(familleCode),
      'codeH': CodificationRules.requiresCodeH(familleCode),
      'tension': CodificationRules.requiresTension(familleCode),
      'celluleType': CodificationRules.requiresCelluleType(familleCode),
      'poste1': CodificationRules.requiresPosteNames(familleCode),
      'poste2': CodificationRules.requiresPosteNames(familleCode),
      'typeCode': CodificationRules.requiresPosteNames(familleCode),
      'clientName': CodificationRules.requiresClientName(familleCode),
    };
  }
}
