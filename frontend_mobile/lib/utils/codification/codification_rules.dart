import 'package:appmobilegmao/utils/codification/codification_input.dart';
import 'package:flutter/foundation.dart';

class CodificationRules {
  static const String _logName = 'CodificationRules';

  // ================== CONSTANTES ==================

  static const String famillePosteHtaBt = 'POSTE_HTA_BT';
  static const String familleCelluleDepart = 'CELLULE_DEPART';
  static const String familleCelluleProtection = 'CELLULE_PROTECTION';
  static const String familleTroncon = 'TRONCON';
  static const String familleSupport = 'SUPPORT';
  static const String familleDepartUp2 = 'DEPART_UP2';

  // ✅ AJOUT: Mapper les noms alternatifs vers les codes standards
  static const Map<String, String> familleAliasMap = {
    'POSTE_HTA/BT': 'POSTE_HTA_BT',
    'POSTE HTA/BT': 'POSTE_HTA_BT',
    'POSTE HTA BT': 'POSTE_HTA_BT',
    'HTA/BT': 'POSTE_HTA_BT',
  };

  // ================== MAPS ==================

  static const Map<String, String> naturePosteMap = {
    'PRIVE': 'P',
    'PRIVÉ': 'P',
    'PUBLIC': 'O',
    'MIXTE': 'M',
  };

  static const Map<String, String> codeHMap = {'H59': 'C', 'H61': 'P'};

  static const Map<String, String> tensionMap = {
    '30KV': 'Y',
    '6,6KV': 'X',
    '6.6KV': 'X',
  };

  static const Map<String, String> celluleTypeMap = {
    'OUVERTE (O)': 'O',
    'FERMÉE (F)': 'F',
    'OUVERTE': 'O',
    'FERMEE': 'F',
    'O': 'O',
    'F': 'F',
  };

  static const Map<String, FamilleInfo> familleInfoMap = {
    'CELLULE_DEPART': FamilleInfo('Cellule départ', 'COD', 3),
    'CELLULE_PROTECTION': FamilleInfo('Cellule protection transfo', 'COT', 3),
    'RDD': FamilleInfo('Relais détecteur de défaut', 'RDD', 3),
    'ITI': FamilleInfo('ITI', 'ITI', 3),
    'CABLE_LIAISON_HTA': FamilleInfo('Câble liaison MT', 'LMT', 4),
    'TRANSFORMATEUR': FamilleInfo('Transformateur', 'TRF', 4),
    'CABLE_LIAISON_BT': FamilleInfo('Câble liaison BT', 'LBT', 4),
    'TABLEAU_DISTRIB': FamilleInfo('Tableau urbain de répartition', 'TUR', 4),
    'RESEAU_BT': FamilleInfo('Réseau BT', 'RXBT', 4),
    'JDCBT': FamilleInfo('JDCBT', 'JDCBT', 4),
    'TGBT': FamilleInfo('TGBT', 'TGBT', 4),
    'DISJONCTEUR': FamilleInfo('Disjoncteur', 'DJ', 4),
    'DEPART_BT': FamilleInfo('Départ BT', 'TRF1D', 5),
    'DEPART_UP2': FamilleInfo('Départ UP2', 'TRF1', 5),
    'ECLATEUR': FamilleInfo('Éclateur', 'EC', 3),
    'PARAFOUDRE': FamilleInfo('Parafoudre', 'PF', 3),
    'IACM': FamilleInfo('IACM', 'ICM', 3),
    'IAT': FamilleInfo('IAT', 'IAT', 3),
    'RDDA': FamilleInfo('RDDA', 'RDDA', 3),
  };

  // ================== GÉNÉRATION ==================

  static CodificationResult generateCode(CodificationInput input) {
    try {
      // ✅ AJOUT: Normaliser le nom de famille
      var famille = input.famille.toUpperCase().replaceAll(' ', '_');

      // Remplacer les alias par le code standard
      if (familleAliasMap.containsKey(famille)) {
        famille = familleAliasMap[famille]!;
        if (kDebugMode) {
          print('🔄 $_logName Famille normalisée: ${input.famille} → $famille');
        }
      }

      if (kDebugMode) {
        print('🔄 $_logName Génération pour: $famille');
      }

      // ✅ Vérifier si on peut générer
      if (!_canGenerateCode(input.copyWith(famille: famille))) {
        if (kDebugMode) {
          print('⚠️ $_logName Conditions non remplies');
        }
        return CodificationResult.error(
          'Conditions de codification non remplies',
        );
      }

      switch (famille) {
        case 'POSTE_HTA_BT':
          return _generateCodePosteHtaBt(input);
        case 'CELLULE_DEPART':
        case 'CELLULE_PROTECTION':
          return _generateCodeCellule(input);
        case 'RDD':
        case 'ITI':
        case 'CABLE_LIAISON_HTA':
        case 'TRANSFORMATEUR':
        case 'CABLE_LIAISON_BT':
        case 'TABLEAU_DISTRIB':
        case 'RESEAU_BT':
        case 'JDCBT':
        case 'TGBT':
        case 'DISJONCTEUR':
          return _generateCodeEquipementPoste(input);
        case 'DEPART_BT':
          return _generateCodeDepartBt(input);
        case 'DEPART_UP2':
          return _generateCodeDepartUp2(input);
        case 'TRONCON':
          return _generateCodeTroncon(input);
        case 'SUPPORT':
          return _generateCodeSupport(input);
        case 'ECLATEUR':
        case 'PARAFOUDRE':
        case 'IACM':
        case 'IAT':
        case 'RDDA':
          return _generateCodeElementTroncon(input);
        default:
          if (kDebugMode) {
            print('❌ $_logName Famille non reconnue: $famille');
          }
          return CodificationResult.error('Famille non reconnue: $famille');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $_logName Erreur: $e');
      }
      return CodificationResult.error('Erreur génération: $e');
    }
  }

  // ✅ CORRIGÉ: Vérification avec famille normalisée
  static bool _canGenerateCode(CodificationInput input) {
    final famille =
        familleAliasMap[input.famille.toUpperCase().replaceAll(' ', '_')] ??
        input.famille.toUpperCase().replaceAll(' ', '_');

    switch (famille) {
      case 'POSTE_HTA_BT':
        return input.feeder != null &&
            input.abbreviation != null &&
            input.naturePoste != null &&
            input.codeH != null &&
            input.tension != null;

      case 'CELLULE_DEPART':
      case 'CELLULE_PROTECTION':
        return input.feeder != null &&
            input.abbreviation != null &&
            input.celluleType != null;

      case 'TRONCON':
      case 'SUPPORT':
        return input.feeder != null &&
            input.poste1 != null &&
            input.poste2 != null;

      case 'DEPART_UP2':
        return input.feeder != null &&
            input.abbreviation != null &&
            input.clientName != null;

      default:
        return input.feeder != null && input.abbreviation != null;
    }
  }

  // ✅ AJOUT: Normalisation publique
  static String normalizeFamily(String famille) {
    var normalized = famille.toUpperCase().replaceAll(' ', '_');
    return familleAliasMap[normalized] ?? normalized;
  }

  // ================== GÉNÉRATEURS ==================

  static CodificationResult _generateCodePosteHtaBt(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final nature = naturePosteMap[input.naturePoste!.toUpperCase()] ?? 'X';
    final codeH = codeHMap[input.codeH!.toUpperCase()] ?? 'N';
    final tension =
        tensionMap[input.tension!.toUpperCase().replaceAll(' ', '')] ?? 'Z';
    final abbr = _normalizeAbbreviation(input.abbreviation ?? '');

    final code = '${feeder}P$nature$codeH$tension$abbr';

    return CodificationResult.success(code, desc: 'Poste HTA/BT $abbr');
  }

  static CodificationResult _generateCodeCellule(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final poste = _normalizeAbbreviation(input.abbreviation ?? '');
    final counter = input.counter ?? 1;
    final celluleCode = celluleTypeMap[input.celluleType?.toUpperCase()] ?? 'O';
    final typeCode = input.famille == familleCelluleDepart ? 'D' : 'T';

    final code = '$feeder${poste}C$celluleCode$typeCode$counter';

    return CodificationResult.success(
      code,
      desc: 'Cellule ${typeCode == 'D' ? 'départ' : 'protection'} n°$counter',
    );
  }

  static CodificationResult _generateCodeEquipementPoste(
    CodificationInput input,
  ) {
    final info = familleInfoMap[input.famille]!;
    final feeder = input.feeder!.toUpperCase();
    final poste = _normalizeAbbreviation(input.abbreviation ?? '');
    final counter = input.counter ?? 1;

    final code = '$feeder$poste${info.baseCode}$counter';

    return CodificationResult.success(
      code,
      desc: '${info.displayName} n°$counter',
    );
  }

  static CodificationResult _generateCodeDepartBt(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final poste = _normalizeAbbreviation(input.abbreviation ?? '');
    final counter = input.counter ?? 1;

    final code = '$feeder${poste}TRF1D$counter';

    return CodificationResult.success(code, desc: 'Départ BT n°$counter');
  }

  static CodificationResult _generateCodeDepartUp2(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final poste = _normalizeAbbreviation(input.abbreviation ?? '');
    final client = _normalizeAbbreviation(input.clientName ?? '');

    final code = '$feeder${poste}TRF1$client';

    return CodificationResult.success(code, desc: 'Départ UP2 $client');
  }

  static CodificationResult _generateCodeTroncon(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final poste1 = _normalizeAbbreviation(input.poste1 ?? '');
    final poste2 = _normalizeAbbreviation(input.poste2 ?? '');

    final code = '${feeder}T$poste1-$poste2';

    return CodificationResult.success(code, desc: 'Tronçon $poste1-$poste2');
  }

  static CodificationResult _generateCodeSupport(CodificationInput input) {
    final feeder = input.feeder!.toUpperCase();
    final poste1 = _normalizeAbbreviation(input.poste1 ?? '');
    final poste2 = _normalizeAbbreviation(input.poste2 ?? '');

    final code = '${feeder}S$poste1-$poste2';

    return CodificationResult.success(code, desc: 'Support $poste1-$poste2');
  }

  static CodificationResult _generateCodeElementTroncon(
    CodificationInput input,
  ) {
    final info = familleInfoMap[input.famille]!;
    final feeder = input.feeder!.toUpperCase();
    final typeCode = input.typeEquipement?.toUpperCase() ?? 'T';
    final poste1 = _normalizeAbbreviation(input.poste1 ?? '');
    final poste2 = _normalizeAbbreviation(input.poste2 ?? '');
    final counter = input.counter ?? 1;

    final code = '$feeder$typeCode$poste1-$poste2${info.baseCode}$counter';

    return CodificationResult.success(
      code,
      desc: '${info.displayName} n°$counter sur tronçon $poste1-$poste2',
    );
  }

  // ================== HELPERS ==================

  static String _normalizeAbbreviation(String text) {
    const accents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const sansAccents = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    var cleaned = text;
    for (var i = 0; i < accents.length; i++) {
      cleaned = cleaned.replaceAll(accents[i], sansAccents[i]);
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

    if (cleaned.isEmpty) return 'XXXXX';
    return cleaned.length > 5
        ? cleaned.substring(0, 5)
        : cleaned.padRight(5, 'X');
  }

  static FamilleInfo? getFamilleInfo(String famille) {
    return familleInfoMap[famille.toUpperCase()];
  }

  static bool requiresNaturePoste(String famille) =>
      famille.toUpperCase() == famillePosteHtaBt;

  static bool requiresCodeH(String famille) =>
      famille.toUpperCase() == famillePosteHtaBt;

  static bool requiresTension(String famille) =>
      famille.toUpperCase() == famillePosteHtaBt;

  static bool requiresCelluleType(String famille) => [
    familleCelluleDepart,
    familleCelluleProtection,
  ].contains(famille.toUpperCase());

  static bool requiresClientName(String famille) =>
      famille.toUpperCase() == familleDepartUp2;

  static bool requiresPosteNames(String famille) => [
    familleTroncon,
    familleSupport,
    'ECLATEUR',
    'PARAFOUDRE',
    'IACM',
    'IAT',
    'RDDA',
  ].contains(famille.toUpperCase());

  static bool requiresFeeder(String famille) =>
      famille.toUpperCase() != famillePosteHtaBt;
}

class FamilleInfo {
  final String displayName;
  final String baseCode;
  final int niveau;

  const FamilleInfo(this.displayName, this.baseCode, this.niveau);
}
