import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/equipment.dart';
import '../models/user.dart';
import '../models/equipment_attribute.dart';
import '../models/historique_equipment.dart';

/// Version simplifiée du HiveService : uniquement les opérations essentielles.
class HiveService {
  static late Box<Equipment> equipmentBox;
  static late Box<User> userBox;
  static late Box<dynamic> selectorsBox;
  static late Box<String> metadataBox;
  static late Box<Map<String, dynamic>> pendingActionsBox;
  static late Box<Map<String, dynamic>> workOrderBox;
  static late Box<Map<String, dynamic>> interventionBox;
  static late Box<Map<String, dynamic>> attributeValuesBox;
  static late Box<HistoriqueEquipment> historiqueEquipmentBox; // ✅ AJOUTÉ
  static const String _authBoxName = 'auth';

  /// Initialisation minimale
  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
    if (kDebugMode) {
      print('✅ HiveService initialisé — boxes ouvertes');
    }
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(EquipmentAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserAdapter());
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(EquipmentAttributeAdapter());
    }
    // ✅ AJOUT: Enregistrer les adaptateurs manquants
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(EntityAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(UniteAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(ZoneAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(FamilleAdapter());
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(CentreChargeAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(FeederAdapter());
    if (!Hive.isAdapterRegistered(16)) {
      // ✅ AJOUTÉ
      Hive.registerAdapter(HistoriqueEquipmentAdapter());
    }

    if (kDebugMode) {
      print('✅ HiveService: Adaptateurs enregistrés');
    }
  }

  static Future<void> _openBoxes() async {
    equipmentBox = await Hive.openBox<Equipment>('gmao_equipment_cache');
    userBox = await Hive.openBox<User>('gmao_user_cache');
    selectorsBox = await Hive.openBox<dynamic>('gmao_selectors_cache');
    metadataBox = await Hive.openBox<String>('gmao_metadata_cache');
    pendingActionsBox = await Hive.openBox<Map<String, dynamic>>(
      'gmao_pending_actions',
    );
    workOrderBox = await Hive.openBox<Map<String, dynamic>>('gmao_work_orders');
    interventionBox = await Hive.openBox<Map<String, dynamic>>(
      'gmao_interventions',
    );
    attributeValuesBox = await Hive.openBox<Map<String, dynamic>>(
      'gmao_attribute_values',
    );
    historiqueEquipmentBox = await Hive.openBox<HistoriqueEquipment>(
      // ✅ AJOUTÉ
      'gmao_historique_equipment',
    );
  }

  // -------------------------
  // Méthodes génériques simples
  // -------------------------
  static Future<void> put<T>(Box<T> box, String key, T value) async {
    await box.put(key, value);
    await _updateTimestamp('${box.name}_$key');
  }

  static T? get<T>(Box<T> box, String key) {
    try {
      return box.get(key);
    } catch (e) {
      if (kDebugMode) print('HiveService.get error: $e');
      return null;
    }
  }

  static Future<void> delete<T>(Box<T> box, String key) async {
    await box.delete(key);
    await metadataBox.delete('${box.name}_${key}_timestamp');
  }

  static Future<void> clearBox(Box box) async {
    await box.clear();
  }

  static Future<void> clearAllCache() async {
    await equipmentBox.clear();
    await userBox.clear();
    await selectorsBox.clear();
    await metadataBox.clear();
    await pendingActionsBox.clear();
    await workOrderBox.clear();
    await interventionBox.clear();
    await attributeValuesBox.clear();
    await historiqueEquipmentBox.clear(); // ✅ AJOUTÉ
    if (kDebugMode) print('HiveService: tout le cache vidé');
  }

  // -------------------------
  // Attributs / valeurs d'attributs (API simplifiée)
  // -------------------------
  static Future<void> cacheAttributeValues(
    String equipmentCode,
    List<EquipmentAttribute> attributes,
  ) async {
    if (equipmentCode.isEmpty) return;
    final data = {
      'attributes': attributes.map((a) => a.toJson()).toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await attributeValuesBox.put(equipmentCode, data);
    await _updateTimestamp('attribute_values_$equipmentCode');
  }

  static Future<List<EquipmentAttribute>?> getAttributeValues(
    String equipmentCode,
  ) async {
    if (equipmentCode.isEmpty) return null;
    final cached = attributeValuesBox.get(equipmentCode);
    if (cached == null) return null;
    final raw = cached['attributes'] as List<dynamic>? ?? [];
    return raw
        .map((e) => EquipmentAttribute.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> clearAttributeValues(String equipmentCode) async {
    if (equipmentCode.isEmpty) return;
    await attributeValuesBox.delete(equipmentCode);
    await metadataBox.delete('attribute_values_${equipmentCode}_timestamp');
  }

  // -------------------------
  // Gestion minimale des tokens (auth)
  // -------------------------
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final box = await Hive.openBox(_authBoxName);
    await box.put('access_token', accessToken);
    await box.put('refresh_token', refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final box = await Hive.openBox(_authBoxName);
    return box.get('access_token') as String?;
  }

  static Future<String?> getRefreshToken() async {
    final box = await Hive.openBox(_authBoxName);
    return box.get('refresh_token') as String?;
  }

  static Future<void> saveAccessToken(String token) async {
    final box = await Hive.openBox(_authBoxName);
    await box.put('access_token', token);
  }

  static Future<void> clearTokens() async {
    final box = await Hive.openBox(_authBoxName);
    await box.delete('access_token');
    await box.delete('refresh_token');
  }

  // -------------------------
  // Gestion de l'utilisateur connecté
  // -------------------------
  static const String _currentUserKey = 'current_user';

  /// Sauvegarde l'utilisateur courant dans la box `userBox`
  static Future<void> cacheCurrentUser(User user) async {
    await userBox.put(_currentUserKey, user);
    await _updateTimestamp('current_user');
  }

  /// Récupère l'utilisateur courant (ou null)
  static User? getCurrentUser() {
    try {
      return userBox.get(_currentUserKey);
    } catch (e) {
      if (kDebugMode) print('HiveService.getCurrentUser error: $e');
      return null;
    }
  }

  /// Supprime l'utilisateur courant du cache
  static Future<void> clearCurrentUser() async {
    await userBox.delete(_currentUserKey);
    await metadataBox.delete('current_user_timestamp');
  }

  // -------------------------
  // Utilitaires
  // -------------------------
  static Future<void> _updateTimestamp(String key) async {
    await metadataBox.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  static Map<String, int> getCacheCounts() {
    return {
      'equipments': equipmentBox.length,
      'users': userBox.length,
      'selectors': selectorsBox.length,
      'pending_actions': pendingActionsBox.length,
      'work_orders': workOrderBox.length,
      'interventions': interventionBox.length,
      'attribute_values': attributeValuesBox.length,
      'historique_equipment': historiqueEquipmentBox.length, // ✅ AJOUTÉ
    };
  }
}
