import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:flutter/foundation.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';

class SelectorLoader {
  static const String __logName = 'SelectorLoader -';

  static Future<Map<String, List<Map<String, dynamic>>>> loadSelectors({
    required EquipmentProvider equipmentProvider,
  }) async {
    try {
      // Récupérer les sélecteurs depuis le provider (objets typés)
      final rawSelectors = await equipmentProvider.loadSelectors();

      // ✅ Convertir les objets typés en Maps
      return {
        'familles':
            (rawSelectors['familles'] as List<Famille>?)
                ?.map((f) => f.toJson())
                .toList() ??
            [],
        'zones':
            (rawSelectors['zones'] as List<Zone>?)
                ?.map((z) => z.toJson())
                .toList() ??
            [],
        'entities':
            (rawSelectors['entities'] as List<Entity>?)
                ?.map((e) => e.toJson())
                .toList() ??
            [],
        'unites':
            (rawSelectors['unites'] as List<Unite>?)
                ?.map((u) => u.toJson())
                .toList() ??
            [],
        'centreCharges':
            (rawSelectors['centreCharges'] as List<CentreCharge>?)
                ?.map((c) => c.toJson())
                .toList() ??
            [],
        'feeders':
            (rawSelectors['feeders'] as List<Feeder>?)
                ?.map((f) => f.toJson())
                .toList() ??
            [],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ SelectorLoader: Erreur chargement sélecteurs: $e');
      }
      return {
        'entities': [],
        'unites': [],
        'centreCharges': [],
        'zones': [],
        'familles': [],
        'feeders': [],
      };
    }
  }

  // ✅ NOUVELLE méthode locale pour extraire les codes depuis les objets typés
  static String? extractCodeFromTypedSelectors(
    String? displayValue,
    String selectorType,
    Map<String, dynamic>? cachedSelectors
  ) {
    if (displayValue == null || displayValue.isEmpty || cachedSelectors == null) {
      return null;
    }

    final selectorData = cachedSelectors[selectorType];
    if (selectorData == null) return null;

    try {
      switch (selectorType) {
        case 'familles':
          final list = selectorData as List<Famille>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;

        case 'zones':
          final list = selectorData as List<Zone>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;

        case 'entities':
          final list = selectorData as List<Entity>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;

        case 'unites':
          final list = selectorData as List<Unite>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;

        case 'centreCharges':
          final list = selectorData as List<CentreCharge>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;

        case 'feeders':
          final list = selectorData as List<Feeder>;
          for (final item in list) {
            if (item.description == displayValue) {
              return item.code;
            }
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur extraction code pour $selectorType: $e');
      }
    }

    return null;
  }
}
