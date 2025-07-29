import 'package:appmobilegmao/models/attribut_value.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/equipment_hive.dart';
import '../models/equipment.dart';
import '../models/reference_data.dart';

class HiveService {
  static late Box<EquipmentHive> equipmentBox;
  static late Box<ReferenceDataHive> referenceBox;
  static late Box<String> metadataBox; // Pour stocker curseurs et métadonnées

  static Future<void> init() async {
    try {
      // Initialiser Hive
      await Hive.initFlutter();

      // Enregistrer les adaptateurs si pas déjà fait
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(EquipmentHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AttributeValueHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ReferenceDataHiveAdapter());
      }

      // Ouvrir les boxes
      equipmentBox = await Hive.openBox<EquipmentHive>('gmao_equipment_cache');
      referenceBox = await Hive.openBox<ReferenceDataHive>(
        'gmao_reference_cache',
      );
      metadataBox = await Hive.openBox<String>('gmao_metadata_cache');

      if (kDebugMode) {
        print('✅ Hive GMAO initialisé avec succès');
        print('📦 Équipements en cache: ${equipmentBox.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur initialisation Hive GMAO: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Cache equipments avec option append pour pagination
  Future<void> cacheEquipments(
    List<Equipment> equipments, {
    bool append = false,
    String? cursor,
  }) async {
    try {
      final now = DateTime.now();

      if (!append) {
        // Effacer le cache existant lors d'un refresh complet
        await equipmentBox.clear();
        await clearCursor(); // Effacer aussi le cursor
        if (kDebugMode) {
          print('🗑️ GMAO: Cache équipements effacé pour refresh complet');
        }
      }

      // Ajouter les nouveaux équipements
      for (final equipment in equipments) {
        final hiveEquipment = _equipmentToHive(equipment, now);
        // Utiliser l'ID comme clé ou générer une clé unique pour éviter les doublons
        final key =
            equipment.id ??
            '${equipment.code}_${DateTime.now().millisecondsSinceEpoch}';
        await equipmentBox.put(key, hiveEquipment);
      }

      // Sauvegarder le cursor si fourni
      if (cursor != null) {
        await saveLastCursor(cursor);
      }

      // Sauvegarder le timestamp de synchronisation
      await metadataBox.put('last_sync_time', DateTime.now().toIso8601String());

      if (kDebugMode) {
        print(
          '💾 GMAO: ${equipments.length} équipements mis en cache (append: $append)',
        );
        print('📦 GMAO: Total en cache: ${equipmentBox.length}');
        if (cursor != null) {
          print('💾 GMAO: Cursor sauvegardé: $cursor');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur cache équipements GMAO: $e');
      }
      rethrow;
    }
  }

  Future<List<Equipment>> getCachedEquipments({
    Map<String, String>? filters,
  }) async {
    try {
      final cached = equipmentBox.values.toList();

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
            if (filters.containsKey('zone') &&
                equipment.zone != filters['zone']) {
              return false;
            }
            if (filters.containsKey('famille') &&
                equipment.famille != filters['famille']) {
              return false;
            }
            if (filters.containsKey('entity') &&
                equipment.entity != filters['entity']) {
              return false;
            }
            if (filters.containsKey('search')) {
              final search = filters['search']!.toLowerCase();
              return equipment.code.toLowerCase().contains(search) ||
                  equipment.description.toLowerCase().contains(search);
            }
            return true;
          }).toList();

      if (kDebugMode) {
        print(
          '🔍 ${filtered.length}/${cached.length} équipements filtrés depuis cache GMAO',
        );
      }
      return filtered.map(_hiveToEquipment).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lecture cache équipements GMAO: $e');
      }
      return [];
    }
  }

  Future<void> cacheReferenceData(ReferenceData data) async {
    try {
      final hiveData = ReferenceDataHive(
        zones: data.zones.map((z) => z.name).toList(),
        familles: data.familles.map((f) => f.name).toList(),
        entities: data.entities.map((e) => e.name).toList(),
        lastSync: DateTime.now(),
      );

      await referenceBox.put('reference_data', hiveData);
      if (kDebugMode) {
        print('💾 Données de référence GMAO mises en cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur cache référence GMAO: $e');
      }
      rethrow;
    }
  }

  Future<ReferenceData?> getCachedReferenceData() async {
    try {
      final cached = referenceBox.get('reference_data');
      if (cached == null) return null;

      return ReferenceData(
        zones:
            cached.zones
                .map((name) => ReferenceItem(name: name, count: 0))
                .toList(),
        familles:
            cached.familles
                .map((name) => ReferenceItem(name: name, count: 0))
                .toList(),
        entities:
            cached.entities
                .map((name) => ReferenceItem(name: name, count: 0))
                .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lecture cache référence GMAO: $e');
      }
      return null;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Sauvegarder le dernier cursor de pagination
  Future<void> saveLastCursor(String cursor) async {
    try {
      await metadataBox.put('last_cursor', cursor);
      if (kDebugMode) {
        print('💾 GMAO: Cursor sauvegardé: $cursor');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur sauvegarde cursor: $e');
      }
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Récupérer le dernier cursor de pagination
  Future<String?> getLastCursor() async {
    try {
      final cursor = metadataBox.get('last_cursor');
      if (kDebugMode) {
        print('📄 GMAO: Cursor récupéré: $cursor');
      }
      return cursor;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur récupération cursor: $e');
      }
      return null;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Effacer le cursor (lors de refresh complet)
  Future<void> clearCursor() async {
    try {
      await metadataBox.delete('last_cursor');
      if (kDebugMode) {
        print('🗑️ GMAO: Cursor effacé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur effacement cursor: $e');
      }
    }
  }

  Future<bool> isCacheExpired({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final lastSync = metadataBox.get('last_sync_time');
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.tryParse(lastSync);
    if (lastSyncTime == null) return true;

    final isExpired = DateTime.now().difference(lastSyncTime) > maxAge;

    if (kDebugMode) {
      print('⏰ GMAO: Cache expiré: $isExpired (dernier sync: $lastSyncTime)');
    }

    return isExpired;
  }

  Future<void> clearEquipmentCache() async {
    await equipmentBox.clear();
    await clearCursor(); // ✅ Effacer aussi le cursor
    await metadataBox.delete(
      'last_sync_time',
    ); // ✅ Effacer le timestamp de synchronisation
    if (kDebugMode) {
      print('🗑️ Cache équipements GMAO vidé');
    }
  }

  Future<void> clearAllCache() async {
    await equipmentBox.clear();
    await referenceBox.clear();
    await metadataBox.clear();
    if (kDebugMode) {
      print('🗑️ Tout le cache GMAO vidé');
    }
  }

  // Méthodes de conversion
  EquipmentHive _equipmentToHive(Equipment equipment, DateTime cachedAt) {
    return EquipmentHive(
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
      attributs:
          equipment.attributs
              .map(
                (attr) => AttributeValueHive(
                  name: attr.name,
                  value: attr.value,
                  type: attr.type,
                ),
              )
              .toList(),
      cachedAt: cachedAt,
      isSync: true,
    );
  }

  Equipment _hiveToEquipment(EquipmentHive hiveEquipment) {
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
      attributs:
          hiveEquipment.attributs
              .map(
                (attr) => AttributValue(
                  name: attr.name,
                  value: attr.value,
                  type: attr.type,
                ),
              )
              .toList(),
    );
  }
}
