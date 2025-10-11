import 'package:flutter/foundation.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/provider/equipment_provider.dart';

class SelectorLoader {
  static Future<Map<String, List<Map<String, dynamic>>>> loadSelectors({
    required EquipmentProvider equipmentProvider,
  }) async {
    try {
      // 1. Tenter de charger depuis le cache (✅ CORRIGÉ)
      final selectorsBox = HiveService.get(
        HiveService.selectorsBox,
        'selectors',
      );

      // ✅ Vérifier que les données existent et sont valides
      if (selectorsBox != null && selectorsBox is Map<String, dynamic>) {
        if (kDebugMode) {
          print('✅ SelectorLoader: Chargement depuis le cache');
        }
        return _extractSelectorsFromCache(selectorsBox);
      }

      // 2. Charger depuis l'API si pas de cache
      if (kDebugMode) {
        print('🔄 SelectorLoader: Chargement depuis l\'API');
      }
      final selectors = await equipmentProvider.loadSelectors();
      return _extractSelectorsFromAPI(selectors);
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

  static Map<String, List<Map<String, dynamic>>> _extractSelectorsFromCache(
    Map<String, dynamic> selectorsBox,
  ) {
    return {
      'entities': _extractSelectorData(selectorsBox['entities']),
      'unites': _extractSelectorData(selectorsBox['unites']),
      'centreCharges': _extractSelectorData(selectorsBox['centreCharges']),
      'zones': _extractSelectorData(selectorsBox['zones']),
      'familles': _extractSelectorData(selectorsBox['familles']),
      'feeders': _extractSelectorData(selectorsBox['feeders']),
    };
  }

  static Map<String, List<Map<String, dynamic>>> _extractSelectorsFromAPI(
    Map<String, dynamic> selectors,
  ) {
    return {
      'entities': _extractSelectorData(selectors['entities']),
      'unites': _extractSelectorData(selectors['unites']),
      'centreCharges': _extractSelectorData(selectors['centreCharges']),
      'zones': _extractSelectorData(selectors['zones']),
      'familles': _extractSelectorData(selectors['familles']),
      'feeders': _extractSelectorData(selectors['feeders']),
    };
  }

  static List<Map<String, dynamic>> _extractSelectorData(dynamic data) {
    if (data == null) return [];

    final List<dynamic> list =
        data is Iterable ? data.toList() : (data is List ? data : const []);

    return list
        .map((item) {
          if (item is Map<String, dynamic>) return item;
          if (item is Map) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          }

          try {
            final jsonMap = (item as dynamic).toJson();
            if (jsonMap is Map) {
              return jsonMap.map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }
          } catch (_) {}

          return <String, dynamic>{};
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }
}
