import 'package:appmobilegmao/models/equipment.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';

class EquipmentHive extends HiveService {
  /// Cache des équipements
  static Future<void> cacheEquipments(List<Equipment> equipments) async {
    try {
      final now = DateTime.now();

      // Effacer le cache existant
      await HiveService.equipmentBox.clear();

      // Ajouter les nouveaux équipements
      for (final equipment in equipments) {
        final hiveEquipment = _equipmentToHive(equipment, now);
        final key = equipment.id ?? '${equipment.code}_${now.millisecondsSinceEpoch}';
        await HiveService.equipmentBox.put(key, hiveEquipment);
      }

      await _updateTimestamp('equipments');

      if (kDebugMode) {
        print('💾 GMAO: ${equipments.length} équipements mis en cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur cache équipements: $e');
      }
      rethrow;
    }
  }

  /// Récupération des équipements avec filtres
  static Future<List<Equipment>> getCachedEquipments({
    Map<String, String>? filters,
  }) async {
    try {
      final cached = HiveService.equipmentBox.values.toList();

      if (filters == null || filters.isEmpty) {
        final result = cached.map(_hiveToEquipment).toList();
        if (kDebugMode) {
          print('📋 GMAO: ${result.length} équipements récupérés du cache');
        }
        return result;
      }

      // Filtrage local
      final filtered =
          cached.where((equipment) {
            // Filtre par zone
            if (filters.containsKey('zone') &&
                equipment.zone != filters['zone']) {
              return false;
            }

            // Filtre par famille
            if (filters.containsKey('famille') &&
                equipment.famille != filters['famille']) {
              return false;
            }

            // Filtre par entité
            if (filters.containsKey('entity') &&
                equipment.entity != filters['entity']) {
              return false;
            }

            // Filtre par description
            if (filters.containsKey('description')) {
              final description = filters['description']!.toLowerCase();
              if (!equipment.description.toLowerCase().contains(description)) {
                return false;
              }
            }

            // Recherche générale
            if (filters.containsKey('search')) {
              final search = filters['search']!.toLowerCase();
              final searchableText =
                  [
                    equipment.code,
                    equipment.description,
                    equipment.zone,
                    equipment.famille,
                    equipment.entity,
                  ].join(' ').toLowerCase();

              if (!searchableText.contains(search)) {
                return false;
              }
            }

            return true;
          }).toList();

      if (kDebugMode) {
        print(
          '🔍 GMAO: ${filtered.length}/${cached.length} équipements filtrés',
        );
      }

      return filtered.map(_hiveToEquipment).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture cache équipements: $e');
      }
      return [];
    }
  }

  /// ✅ NOUVEAU: Mettre à jour un équipement spécifique dans le cache
  static Future<void> updateEquipmentInCache(Equipment updatedEquipment) async {
    try {
      if (updatedEquipment.id == null || updatedEquipment.id!.isEmpty) {
        if (kDebugMode) {
          print(
            '⚠️ GMAO: ID équipement manquant, impossible de mettre à jour le cache',
          );
        }
        return;
      }

      // Trouver l'équipement existant dans le cache
      final existingEquipmentKey = HiveService.equipmentBox.keys.firstWhere((key) {
        final equipment = HiveService.equipmentBox.get(key);
        return equipment?.id == updatedEquipment.id;
      }, orElse: () => null);

      if (existingEquipmentKey != null) {
        // Mettre à jour l'équipement existant
        await HiveService.equipmentBox.put(existingEquipmentKey, updatedEquipment);

        if (kDebugMode) {
          print(
            '✅ GMAO: Équipement ${updatedEquipment.code} mis à jour dans le cache',
          );
        }
      } else {
        // Si l'équipement n'existe pas, l'ajouter
        await HiveService.equipmentBox.add(updatedEquipment);

        if (kDebugMode) {
          print('✅ GMAO: Équipement ${updatedEquipment.code} ajouté au cache');
        }
      }

      // Mettre à jour le timestamp du cache
      await _updateTimestamp('equipments');
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur mise à jour équipement dans cache: $e');
      }
      rethrow;
    }
  }

  /// Conversion Equipment vers Equipment
  static Equipment _equipmentToHive(Equipment equipment, DateTime cachedAt) {
    return Equipment(
      id: equipment.id,
      codeParent: equipment.codeParent,
      feeder: equipment.feeder,
      feederDescription: equipment.feederDescription,
      code: equipment.code,
      famille: equipment.famille,
      zone: equipment.zone,
      entity: equipment.entity,
      unite: equipment.unite,
      centreCharge: equipment.centreCharge,
      description: equipment.description,
      longitude: equipment.longitude,
      latitude: equipment.latitude,
      attributes: equipment.attributes,
      cachedAt: cachedAt,
    );
  }

  /// Conversion Equipment vers Equipment
  static Equipment _hiveToEquipment(Equipment hiveEquipment) {
    return Equipment(
      id: hiveEquipment.id,
      codeParent: hiveEquipment.codeParent,
      feeder: hiveEquipment.feeder,
      feederDescription: hiveEquipment.feederDescription,
      code: hiveEquipment.code,
      famille: hiveEquipment.famille,
      zone: hiveEquipment.zone,
      entity: hiveEquipment.entity,
      unite: hiveEquipment.unite,
      centreCharge: hiveEquipment.centreCharge,
      description: hiveEquipment.description,
      longitude: hiveEquipment.longitude,
      latitude: hiveEquipment.latitude,
      attributes: hiveEquipment.attributes,
    );
  }

  /// Mise à jour du timestamp
  static Future<void> _updateTimestamp(String key) async {
    await HiveService.metadataBox.put('${key}_timestamp', DateTime.now().toIso8601String());
  }
}
