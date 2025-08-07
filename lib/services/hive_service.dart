import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/equipment.dart';
import '../models/user.dart';

/// Service de cache Hive générique pour toute l'application GMAO
/// Gère le stockage local des données avec synchronisation différée
class HiveService {
  // Boxes de cache
  static late Box<Equipment> equipmentBox;
  static late Box<User> userBox;
  static late Box<dynamic> selectorsBox; // Sélecteurs
  static late Box<String> metadataBox;
  static late Box<Map<String, dynamic>> pendingActionsBox; // Actions en attente
  static late Box<Map<String, dynamic>> workOrderBox; // Ordres de travail
  static late Box<Map<String, dynamic>>
  interventionBox; // Demandes d'intervention

  /// Initialisation du service Hive
  static Future<void> init() async {
    try {
      // Initialiser Hive
      await Hive.initFlutter();

      // Enregistrer les adaptateurs
      _registerAdapters();

      // Ouvrir les boxes
      await _openBoxes();

      if (kDebugMode) {
        print('✅ HiveService GMAO initialisé avec succès');
        _printCacheStats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur initialisation HiveService GMAO: $e');
      }
      rethrow;
    }
  }

  /// Enregistrement des adaptateurs Hive
  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EquipmentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AttributeValueAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserAdapter());
    }
  }

  /// Ouverture des boxes
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
  }

  /// Affichage des statistiques du cache
  static void _printCacheStats() {
    if (kDebugMode) {
      print('📦 GMAO Cache Stats:');
      print('   - Équipements: ${equipmentBox.length}');
      print('   - Utilisateurs: ${userBox.length}');
      print('   - Sélecteurs: ${selectorsBox.length}');
      print('   - Actions en attente: ${pendingActionsBox.length}');
      print('   - Ordres de travail: ${workOrderBox.length}');
      print('   - Interventions: ${interventionBox.length}');
    }
  }

  // ========================================
  // MÉTHODES GÉNÉRIQUES DE CACHE
  // ========================================

  /// Cache des données avec timestamp automatique
  static Future<void> cacheData<T>(
    Box<T> box,
    String key,
    T data, {
    bool updateTimestamp = true,
  }) async {
    try {
      await box.put(key, data);

      if (updateTimestamp) {
        await _updateTimestamp('${box.name}_$key');
      }

      if (kDebugMode) {
        print('💾 GMAO: Données mises en cache - ${box.name}:$key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur cache ${box.name}: $e');
      }
      rethrow;
    }
  }

  /// Récupération de données du cache
  static T? getCachedData<T>(Box<T> box, String key) {
    try {
      final data = box.get(key);
      if (data != null) {
        if (kDebugMode) {
          print('📋 GMAO: Données récupérées du cache - ${box.name}:$key');
        }
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture cache ${box.name}: $e');
      }
      return null;
    }
  }

  /// Vérification d'expiration du cache
  static Future<bool> isCacheExpired(
    String key, {
    Duration maxAge = const Duration(
      hours: 24,
    ), // ✅ Augmenté à 24h pour les sélecteurs
  }) async {
    final timestampKey = '${key}_timestamp';
    final timestamp = metadataBox.get(timestampKey);

    if (timestamp == null) return true;

    final cachedTime = DateTime.tryParse(timestamp);
    if (cachedTime == null) return true;

    final isExpired = DateTime.now().difference(cachedTime) > maxAge;

    if (kDebugMode) {
      print(
        '⏰ GMAO: Cache $key expiré: $isExpired (âge: ${DateTime.now().difference(cachedTime).inHours}h)',
      );
    }

    return isExpired;
  }

  /// Mise à jour du timestamp
  static Future<void> _updateTimestamp(String key) async {
    await metadataBox.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  // ========================================
  // GESTION DES ÉQUIPEMENTS
  // ========================================

  /// Cache des équipements
  static Future<void> cacheEquipments(List<Equipment> equipments) async {
    try {
      final now = DateTime.now();

      // Effacer le cache existant
      await equipmentBox.clear();

      // Ajouter les nouveaux équipements
      for (final equipment in equipments) {
        final hiveEquipment = _equipmentToHive(equipment, now);
        final key =
            equipment.id ?? '${equipment.code}_${now.millisecondsSinceEpoch}';
        await equipmentBox.put(key, hiveEquipment);
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

  // ========================================
  // GESTION DES SÉLECTEURS
  // ========================================

  /// Cache des sélecteurs
  static Future<void> cacheSelectors(Map<String, dynamic> selectors) async {
    try {
      await selectorsBox.clear();

      // ✅ Stocker chaque type de sélecteur individuellement
      for (final entry in selectors.entries) {
        await selectorsBox.put(entry.key, entry.value);
      }

      await _updateTimestamp('selectors');
      if (kDebugMode) {
        print(
          '💾 GMAO: Sélecteurs mis en cache (${selectors.keys.join(', ')})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur cache sélecteurs: $e');
      }
      rethrow;
    }
  }

  /// Récupération des sélecteurs
  static Map<String, dynamic>? getCachedSelectors() {
    try {
      final Map<String, dynamic> selectors = {};

      // ✅ Récupérer chaque type de sélecteur
      for (final key in selectorsBox.keys) {
        selectors[key] = selectorsBox.get(key);
      }

      if (selectors.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📋 GMAO: Sélecteurs récupérés du cache (${selectors.keys.join(', ')})',
          );
        }
        // ✅ Validation des données
        if (selectors.containsKey('entities') &&
            selectors.containsKey('zones') &&
            selectors.containsKey('familles') &&
            selectors.containsKey('centreCharges') &&
            selectors.containsKey('feeders')) {
          return selectors; // ✅ Retourner selectors, pas selectors['selectors']
        }
      }

      if (kDebugMode) {
        print('⚠️ GMAO: Cache sélecteurs vide ou incomplet');
      }
      return null; // ✅ Retourner null si pas de données valides
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture cache sélecteurs: $e');
      }
      return null;
    }
  }

  /// ✅ NOUVEAU: Vérifier si les sélecteurs sont en cache et valides
  static Future<bool> areSelectorsCached() async {
    try {
      final selectors = getCachedSelectors();
      if (selectors == null || selectors.isEmpty) {
        return false;
      }

      // Vérifier si le cache n'est pas expiré
      final isExpired = await isCacheExpired(
        'selectors',
        maxAge: const Duration(hours: 24),
      );
      return !isExpired;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur vérification cache sélecteurs: $e');
      }
      return false;
    }
  }

  // ========================================
  // GESTION DES UTILISATEURS
  // ========================================

  /// Cache de l'utilisateur connecté
  static Future<void> cacheCurrentUser(User user) async {
    await cacheData(userBox, 'current_user', user);
  }

  /// Récupération de l'utilisateur connecté
  static User? getCurrentUser() {
    return getCachedData(userBox, 'current_user');
  }

  /// Suppression de l'utilisateur connecté
  static Future<void> clearCurrentUser() async {
    await userBox.delete('current_user');
    if (kDebugMode) {
      print('🗑️ GMAO: Utilisateur connecté supprimé du cache');
    }
  }

  // ========================================
  // GESTION DES ACTIONS EN ATTENTE
  // ========================================

  /// Ajouter une action en attente (pour synchronisation différée)
  static Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final key =
          '${DateTime.now().millisecondsSinceEpoch}_${action['type'] ?? 'unknown'}';
      action['timestamp'] = DateTime.now().toIso8601String();
      action['status'] = 'pending';

      await pendingActionsBox.put(key, action);

      if (kDebugMode) {
        print('📝 GMAO: Action en attente ajoutée: ${action['type']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur ajout action en attente: $e');
      }
      rethrow;
    }
  }

  /// Récupération des actions en attente
  static List<Map<String, dynamic>> getPendingActions() {
    try {
      return pendingActionsBox.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture actions en attente: $e');
      }
      return [];
    }
  }

  /// Supprimer une action en attente
  static Future<void> removePendingAction(String key) async {
    await pendingActionsBox.delete(key);
    if (kDebugMode) {
      print('🗑️ GMAO: Action en attente supprimée: $key');
    }
  }

  /// Vider toutes les actions en attente
  static Future<void> clearPendingActions() async {
    await pendingActionsBox.clear();
    if (kDebugMode) {
      print('🗑️ GMAO: Toutes les actions en attente supprimées');
    }
  }

  // ========================================
  // GESTION DES ORDRES DE TRAVAIL
  // ========================================

  /// Cache des ordres de travail
  static Future<void> cacheWorkOrders(
    List<Map<String, dynamic>> workOrders,
  ) async {
    try {
      await workOrderBox.clear();

      for (int i = 0; i < workOrders.length; i++) {
        await workOrderBox.put('wo_$i', workOrders[i]);
      }

      await _updateTimestamp('work_orders');

      if (kDebugMode) {
        print('💾 GMAO: ${workOrders.length} ordres de travail mis en cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur cache ordres de travail: $e');
      }
      rethrow;
    }
  }

  /// Récupération des ordres de travail
  static List<Map<String, dynamic>> getCachedWorkOrders() {
    try {
      return workOrderBox.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture cache ordres de travail: $e');
      }
      return [];
    }
  }

  // ========================================
  // GESTION DES DEMANDES D'INTERVENTION
  // ========================================

  /// Cache des demandes d'intervention
  static Future<void> cacheInterventions(
    List<Map<String, dynamic>> interventions,
  ) async {
    try {
      await interventionBox.clear();

      for (int i = 0; i < interventions.length; i++) {
        await interventionBox.put('int_$i', interventions[i]);
      }

      await _updateTimestamp('interventions');

      if (kDebugMode) {
        print(
          '💾 GMAO: ${interventions.length} demandes d\'intervention mises en cache',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur cache interventions: $e');
      }
      rethrow;
    }
  }

  /// Récupération des demandes d'intervention
  static List<Map<String, dynamic>> getCachedInterventions() {
    try {
      return interventionBox.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur lecture cache interventions: $e');
      }
      return [];
    }
  }

  // ========================================
  // MÉTHODES DE NETTOYAGE
  // ========================================

  /// Nettoyage sélectif du cache
  static Future<void> clearCache(String cacheType) async {
    switch (cacheType) {
      case 'equipments':
        await equipmentBox.clear();
        break;
      case 'users':
        await userBox.clear();
        break;
      case 'selectors':
        await selectorsBox.clear();
        break;
      case 'work_orders':
        await workOrderBox.clear();
        break;
      case 'interventions':
        await interventionBox.clear();
        break;
      case 'pending_actions':
        await pendingActionsBox.clear();
        break;
    }

    if (kDebugMode) {
      print('🗑️ GMAO: Cache $cacheType vidé');
    }
  }

  /// Nettoyage complet du cache
  static Future<void> clearAllCache() async {
    await equipmentBox.clear();
    await userBox.clear();
    await selectorsBox.clear();
    await metadataBox.clear();
    await pendingActionsBox.clear();
    await workOrderBox.clear();
    await interventionBox.clear();

    if (kDebugMode) {
      print('🗑️ GMAO: Tout le cache vidé');
    }
  }

  /// Nettoyage du cache expiré
  static Future<void> clearExpiredCache({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final keys =
        metadataBox.keys
            .where((key) => key.toString().endsWith('_timestamp'))
            .toList();

    for (final key in keys) {
      final cacheKey = key.toString().replaceAll('_timestamp', '');
      if (await isCacheExpired(cacheKey, maxAge: maxAge)) {
        // Déterminer quel cache nettoyer
        if (cacheKey.contains('equipment')) {
          await equipmentBox.clear();
        } else if (cacheKey.contains('user')) {
          await userBox.clear();
        } else if (cacheKey.contains('selectors')) {
          await selectorsBox.clear();
        } else if (cacheKey.contains('work_orders')) {
          await workOrderBox.clear();
        } else if (cacheKey.contains('interventions')) {
          await interventionBox.clear();
        } else if (cacheKey.contains('pending_actions')) {
          await pendingActionsBox.clear();
        }
        await metadataBox.delete(key);
        if (kDebugMode) {
          print('🗑️ GMAO: Cache expiré nettoyé: $cacheKey');
        }
      }
    }

    if (kDebugMode) {
      print('🗑️ GMAO: Cache expiré nettoyé');
    }
  }

  // ========================================
  // MÉTHODES DE CONVERSION
  // ========================================

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
      attributs:
          equipment.attributs
              .map(
                (attr) => AttributeValue(
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
      attributs:
          hiveEquipment.attributs
              .map(
                (attr) => AttributeValue(
                  name: attr.name,
                  value: attr.value,
                  type: attr.type,
                ),
              )
              .toList(),
    );
  }

  // ========================================
  // UTILITAIRES
  // ========================================

  /// Statistiques détaillées du cache
  static Map<String, dynamic> getCacheStats() {
    return {
      'equipments': equipmentBox.length,
      'users': userBox.length,
      'selectors': selectorsBox.length,
      'pending_actions': pendingActionsBox.length,
      'work_orders': workOrderBox.length,
      'interventions': interventionBox.length,
      'metadata': metadataBox.length,
    };
  }

  /// Taille du cache en données
  static Future<Map<String, int>> getCacheSizes() async {
    return {
      'equipments_mb':
          (equipmentBox.toMap().toString().length / (1024 * 1024)).round(),
      'users_mb': (userBox.toMap().toString().length / (1024 * 1024)).round(),
      'work_orders_mb':
          (workOrderBox.toMap().toString().length / (1024 * 1024)).round(),
      'interventions_mb':
          (interventionBox.toMap().toString().length / (1024 * 1024)).round(),
      'selectors_mb':
          (selectorsBox.toMap().toString().length / (1024 * 1024)).round(),
    };
  }
}
