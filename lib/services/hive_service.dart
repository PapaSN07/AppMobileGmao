import 'package:appmobilegmao/models/attribute_value.dart';
import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
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
  // ✅ NOUVEAU: Box pour les valeurs d'attributs des équipements
  static late Box<Map<String, dynamic>>
  attributeValuesBox; // Valeurs d'attributs par équipement

  // Logging
  static const String __logName = 'HiverService -';

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
        print('✅ $__logName HiveService GMAO initialisé avec succès');
        _printCacheStats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur initialisation HiveService GMAO: $e');
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
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FamilleAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(EntityAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(CentreChargeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(UniteAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(FeederAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(ZoneAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(EquipmentAttributeAdapter());
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
    // ✅ NOUVEAU: Ouverture de la box pour les valeurs d'attributs
    attributeValuesBox = await Hive.openBox<Map<String, dynamic>>(
      'gmao_attribute_values',
    );
  }

  /// Affichage des statistiques du cache
  static void _printCacheStats() {
    if (kDebugMode) {
      print('📦 $__logName GMAO Cache Stats:');
      print('   - Équipements: ${equipmentBox.length}');
      print('   - Utilisateurs: ${userBox.length}');
      print('   - Sélecteurs: ${selectorsBox.length}');
      print('   - Actions en attente: ${pendingActionsBox.length}');
      print('   - Ordres de travail: ${workOrderBox.length}');
      print('   - Interventions: ${interventionBox.length}');
      print('   - Valeurs d\'attributs: ${attributeValuesBox.length}');
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
        print('💾 $__logName GMAO: Données mises en cache - ${box.name}:$key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache ${box.name}: $e');
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
          print('📋 $__logName GMAO: Données récupérées du cache - ${box.name}:$key');
        }
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur lecture cache ${box.name}: $e');
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
        '⏰ $__logName GMAO: Cache $key expiré: $isExpired (âge: ${DateTime.now().difference(cachedTime).inHours}h)',
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
        print('💾 $__logName GMAO: ${equipments.length} équipements mis en cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache équipements: $e');
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
          print('📋 $__logName GMAO: ${result.length} équipements récupérés du cache');
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
          '🔍 $__logName GMAO: ${filtered.length}/${cached.length} équipements filtrés',
        );
      }

      return filtered.map(_hiveToEquipment).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur lecture cache équipements: $e');
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
            '⚠️ $__logName ID équipement manquant, impossible de mettre à jour le cache',
          );
        }
        return;
      }              

      // Trouver l'équipement existant dans le cache par ID
      int? keyToUpdate;
      Equipment? existingEquipment;

      for (int i = 0; i < equipmentBox.length; i++) {
        final equipment = equipmentBox.getAt(i);
        if (equipment?.id == updatedEquipment.id ||
            equipment?.code == updatedEquipment.code) {
          keyToUpdate = i;
          existingEquipment = equipment;
          break;
        }
      }

      if (keyToUpdate != null && existingEquipment != null) {
        // ✅ IMPORTANT: Créer un nouvel équipement avec toutes les données mises à jour
        final mergedEquipment = Equipment(
          id: updatedEquipment.id ?? existingEquipment.id,
          code:
              updatedEquipment.code.isNotEmpty
                  ? updatedEquipment.code
                  : existingEquipment.code,
          description:
              updatedEquipment.description.isNotEmpty
                  ? updatedEquipment.description
                  : existingEquipment.description,
          famille:
              updatedEquipment.famille.isNotEmpty
                  ? updatedEquipment.famille
                  : existingEquipment.famille,
          zone:
              updatedEquipment.zone.isNotEmpty
                  ? updatedEquipment.zone
                  : existingEquipment.zone,
          entity:
              updatedEquipment.entity.isNotEmpty
                  ? updatedEquipment.entity
                  : existingEquipment.entity,
          unite:
              updatedEquipment.unite.isNotEmpty
                  ? updatedEquipment.unite
                  : existingEquipment.unite,
          centreCharge:
              updatedEquipment.centreCharge.isNotEmpty == true
                  ? updatedEquipment.centreCharge
                  : existingEquipment.centreCharge,
          codeParent:
              updatedEquipment.codeParent?.isNotEmpty == true
                  ? updatedEquipment.codeParent
                  : existingEquipment.codeParent,
          feeder:
              updatedEquipment.feeder?.isNotEmpty == true
                  ? updatedEquipment.feeder
                  : existingEquipment.feeder,
          feederDescription:
              updatedEquipment.feederDescription?.isNotEmpty == true
                  ? updatedEquipment.feederDescription
                  : existingEquipment.feederDescription,
          longitude:
              updatedEquipment.longitude.isNotEmpty == true
                  ? updatedEquipment.longitude
                  : existingEquipment.longitude,
          latitude:
              updatedEquipment.latitude.isNotEmpty == true
                  ? updatedEquipment.latitude
                  : existingEquipment.latitude,
          attributes:
              updatedEquipment.attributes?.isNotEmpty == true
                  ? updatedEquipment.attributes
                  : existingEquipment.attributes,
          cachedAt: DateTime.now(),
        );

        // Mettre à jour l'équipement dans la box
        await equipmentBox.putAt(keyToUpdate, mergedEquipment);

        if (kDebugMode) {
          print(
            '✅ $__logName Équipement ${mergedEquipment.code} mis à jour dans le cache (index: $keyToUpdate)',
          );
        }
      } else {
        // Si l'équipement n'existe pas, l'ajouter
        await equipmentBox.add(updatedEquipment);

        if (kDebugMode) {
          print(
            '✅ $__logName Équipement ${updatedEquipment.code} ajouté au cache (nouvel équipement)',
          );
        }
      }

      // Mettre à jour le timestamp du cache
      await _updateTimestamp('equipments');
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur mise à jour équipement dans cache: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Nettoyer les valeurs d'attributs pour un équipement
  static Future<void> clearAttributeValues(String equipmentCode) async {
    try {
      if (attributeValuesBox.containsKey(equipmentCode)) {
        await attributeValuesBox.delete(equipmentCode);
        if (kDebugMode) {
          print(
            '✅ $__logName Valeurs attributs supprimées pour $equipmentCode',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur suppression valeurs attributs: $e');
      }
    }
  }

  /// ✅ CORRIGÉ: Sauvegarder les valeurs d'attributs
  static Future<void> cacheAttributeValues(
    String equipmentCode,
    List<EquipmentAttribute> attributes,
  ) async {
    try {
      if (equipmentCode.isEmpty || attributes.isEmpty) {
        if (kDebugMode) {
          print(
            '⚠️ $__logName Code équipement vide ou aucun attribut à sauvegarder',
          );
        }
        return;
      }

      // Convertir les EquipmentAttribute en Map<String, String> pour le cache
      final Map<String, String> attributeValues = {};
      for (final attr in attributes) {
        if (attr.name != null && attr.name!.isNotEmpty) {
          attributeValues[attr.name!] = attr.value ?? '';
        }
      }

      await attributeValuesBox.put(equipmentCode, attributeValues);

      if (kDebugMode) {
        print(
          '✅ $__logName ${attributeValues.length} valeurs attributs sauvegardées pour $equipmentCode',
        );
        for (final entry in attributeValues.entries) {
          print('   - ${entry.key}: "${entry.value}"');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur sauvegarde valeurs attributs: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // GESTION DES SÉLECTEURS
  // ========================================

  /// Cache des sélecteurs
  // ✅ Stocker directement la réponse API complète sous forme de Map
  static Future<void> cacheSelectors(Map<String, dynamic> selectorsData) async {
    try {
      // ✅ Force la conversion des données avant de les stocker
      final sanitizedData = selectorsData.map(
        (key, value) => MapEntry(
          key.toString(),
          value is List
              ? value.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                }
                if (item is Map) {
                  return item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  );
                }
                return item;
              }).toList()
              : value,
        ),
      );

      await selectorsBox.put('data', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'selectors': sanitizedData,
      });

      if (kDebugMode) {
        print(
          '💾 $__logName GMAO: Sélecteurs mis en cache (${sanitizedData.keys.join(', ')})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache sélecteurs: $e');
      }
    }
  }

  /// Récupération des sélecteurs
  static Map<String, dynamic>? getCachedSelectors() {
    try {
      final cachedData = selectorsBox.get('data');

      if (cachedData == null) return null;

      final timestamp = cachedData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cacheValidityDuration = 24 * 60 * 60 * 1000; // 24h en ms

      final isExpired = (now - timestamp) > cacheValidityDuration;

      if (kDebugMode) {
        final ageHours = ((now - timestamp) / (60 * 60 * 1000)).round();
        print('⏰ $__logName GMAO: Cache selectors expiré: $isExpired (âge: ${ageHours}h)');
      }

      if (isExpired) {
        return null;
      }

      // ✅ Conversion explicite des données en Map<String, dynamic>
      final selectors = (cachedData['selectors'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );

      if (selectors.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📋 $__logName GMAO: Sélecteurs récupérés du cache (${selectors.keys.join(', ')})',
          );
        }
      }

      return selectors;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur lecture cache sélecteurs: $e');
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
        print('❌ $__logName GMAO: Erreur vérification cache sélecteurs: $e');
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
      print('🗑️ $__logName GMAO: Utilisateur connecté supprimé du cache');
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
        print('📝 $__logName GMAO: Action en attente ajoutée: ${action['type']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur ajout action en attente: $e');
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
        print('❌ $__logName GMAO: Erreur lecture actions en attente: $e');
      }
      return [];
    }
  }

  /// Supprimer une action en attente
  static Future<void> removePendingAction(String key) async {
    await pendingActionsBox.delete(key);
    if (kDebugMode) {
      print('🗑️ $__logName GMAO: Action en attente supprimée: $key');
    }
  }

  /// Vider toutes les actions en attente
  static Future<void> clearPendingActions() async {
    await pendingActionsBox.clear();
    if (kDebugMode) {
      print('🗑️ $__logName GMAO: Toutes les actions en attente supprimées');
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
        print('💾 $__logName GMAO: ${workOrders.length} ordres de travail mis en cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache ordres de travail: $e');
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
        print('❌ $__logName GMAO: Erreur lecture cache ordres de travail: $e');
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
          '💾 $__logName GMAO: ${interventions.length} demandes d\'intervention mises en cache',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache interventions: $e');
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
        print('❌ $__logName GMAO: Erreur lecture cache interventions: $e');
      }
      return [];
    }
  }

  // ========================================
  // GESTION DES VALEURS D'ATTRIBUTS
  // ========================================

  /// ✅ NOUVEAU: Méthode pour préserver le cache des sélecteurs lors des mises à jour
  static Future<void> preserveSelectorsCache() async {
    try {
      // Vérifier que le cache des sélecteurs existe toujours
      final selectorsData = getCachedSelectors();

      if (selectorsData == null || selectorsData.isEmpty) {
        if (kDebugMode) {
          print(
            '⚠️ $__logName GMAO: Cache des sélecteurs manquant, conservation des données existantes',
          );
        }
        return;
      }

      // Remettre à jour le timestamp pour éviter l'expiration
      await _updateTimestamp('selectors');

      if (kDebugMode) {
        print('✅ $__logName GMAO: Cache des sélecteurs préservé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur préservation cache sélecteurs: $e');
      }
    }
  }

  /// ✅ NOUVEAU: Nettoyage ciblé sans affecter les autres caches
  static Future<void> cleanDuplicateAttributeCaches() async {
    try {
      final equipmentKeys = <String>[];
      final specificationKeys = <String>[];

      // Séparer les clés par type
      for (final key in attributeValuesBox.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('attribute_values_')) {
          // Clé d'équipement invalide (devrait être juste le code équipement)
          continue;
        } else if (keyStr.contains('_') &&
            !keyStr.startsWith('attribute_values_')) {
          // Clé de spécification (format: "specification_index")
          specificationKeys.add(keyStr);
        } else {
          // Clé d'équipement (code équipement simple)
          equipmentKeys.add(keyStr);
        }
      }

      if (kDebugMode) {
        print('🔍 $__logName GMAO: Analyse cache attributs:');
        print('   - Équipements: ${equipmentKeys.length}');
        print('   - Spécifications: ${specificationKeys.length}');
      }

      // Vérifier et nettoyer les doublons d'équipements
      final duplicatedEquipments = <String>[];
      for (final equipmentKey in equipmentKeys) {
        final cachedData = attributeValuesBox.get(equipmentKey);
        if (cachedData != null && cachedData['attributes'] is List) {
          final attributes = cachedData['attributes'] as List;
          if (attributes.length > 10) {
            // Seuil arbitraire pour détecter les doublons
            duplicatedEquipments.add(equipmentKey);
          }
        }
      }

      // Nettoyer les équipements avec trop d'attributs (probablement dupliqués)
      for (final equipmentKey in duplicatedEquipments) {
        await attributeValuesBox.delete(equipmentKey);
        await metadataBox.delete('attribute_values_$equipmentKey');

        if (kDebugMode) {
          print(
            '🗑️ $__logName GMAO: Cache dupliqué nettoyé pour équipement: $equipmentKey',
          );
        }
      }

      if (kDebugMode) {
        print(
          '✅ $__logName GMAO: ${duplicatedEquipments.length} caches dupliqués nettoyés',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur nettoyage caches dupliqués: $e');
      }
    }
  }

  /// ✅ IMPROVED: Récupération des valeurs d'attributs avec logs détaillés
  static Future<List<EquipmentAttribute>?> getCachedAttributeValues(
    String equipmentCode,
  ) async {
    try {
      // ✅ AJOUTÉ: Validation du code équipement
      if (equipmentCode.isEmpty) {
        if (kDebugMode) {
          print('⚠️ $__logName GMAO: Code équipement vide, abandon récupération cache');
        }
        return null;
      }

      final cachedData = attributeValuesBox.get(equipmentCode);

      if (cachedData == null) {
        if (kDebugMode) {
          print(
            '📋 $__logName GMAO: Aucune valeur d\'attribut en cache pour équipement $equipmentCode',
          );
        }
        return null;
      }

      // Vérifier l'expiration du cache (24h par défaut)
      final isExpired = await isCacheExpired(
        'attribute_values_$equipmentCode',
        maxAge: const Duration(hours: 24),
      );

      if (isExpired) {
        if (kDebugMode) {
          print(
            '⏰ $__logName GMAO: Cache des valeurs d\'attributs expiré pour équipement $equipmentCode',
          );
        }
        await attributeValuesBox.delete(equipmentCode);
        return null;
      }

      // Convertir les données en liste d'EquipmentAttribute
      final attributesData = cachedData['attributes'] as List;
      final attributeValues =
          attributesData
              .map(
                (data) => EquipmentAttribute.fromJson(
                  Map<String, dynamic>.from(data),
                ),
              )
              .toList();

      if (kDebugMode) {
        print(
          '📋 $__logName GMAO: ${attributeValues.length} valeurs d\'attributs récupérées du cache pour équipement $equipmentCode',
        );
        // ✅ NOUVEAU: Logs détaillés des valeurs récupérées
        for (final attr in attributeValues) {
          print('   - RÉCUPÉRÉ: ${attr.name}: "${attr.value}"');
        }
      }

      return attributeValues;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur lecture cache valeurs d\'attributs: $e');
      }
      return null;
    }
  }

  /// ✅ NOUVEAU: Cache des spécifications d'attributs avec leurs valeurs possibles
  static Future<void> cacheAttributeSpecifications(
    String specification,
    String attributeIndex,
    List<EquipmentAttribute> attributeValues,
  ) async {
    try {
      final specKey = '${specification}_$attributeIndex';

      final attributesData =
          attributeValues.map((attr) => attr.toJson()).toList();

      final cacheData = {
        'specification': specification,
        'attributeIndex': attributeIndex,
        'attributes': attributesData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await attributeValuesBox.put(specKey, cacheData);
      await _updateTimestamp('attribute_spec_$specKey');

      if (kDebugMode) {
        print(
          '💾 $__logName GMAO: ${attributeValues.length} spécifications d\'attributs mises en cache pour $specKey',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur cache spécifications attributs: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Récupération des spécifications d'attributs
  static Future<List<EquipmentAttribute>?> getCachedAttributeSpecifications(
    String specification,
    String attributeIndex,
  ) async {
    try {
      final specKey = '${specification}_$attributeIndex';
      final cachedData = attributeValuesBox.get(specKey);

      if (cachedData == null) {
        if (kDebugMode) {
          print('📋 $__logName GMAO: Aucune spécification en cache pour $specKey');
        }
        return null;
      }

      // Vérifier l'expiration du cache
      final isExpired = await isCacheExpired(
        'attribute_spec_$specKey',
        maxAge: const Duration(hours: 24),
      );

      if (isExpired) {
        if (kDebugMode) {
          print('⏰ $__logName GMAO: Cache des spécifications expiré pour $specKey');
        }
        await attributeValuesBox.delete(specKey);
        return null;
      }

      final attributesData = cachedData['attributes'] as List;
      final attributeValues =
          attributesData
              .map(
                (data) => EquipmentAttribute.fromJson(
                  Map<String, dynamic>.from(data),
                ),
              )
              .toList();

      if (kDebugMode) {
        print(
          '📋 $__logName GMAO: ${attributeValues.length} spécifications récupérées pour $specKey',
        );
      }

      return attributeValues;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur lecture spécifications attributs: $e');
      }
      return null;
    }
  }

  /// ✅ MODIFIÉ: Mettre à jour une valeur d'attribut spécifique (compatible EquipmentAttribute)
  static Future<void> updateAttributeValue(
    String equipmentCode,
    String attributeId,
    String newValue,
  ) async {
    try {
      final cachedData = attributeValuesBox.get(equipmentCode);
      if (cachedData == null) {
        throw Exception(
          '$__logName Aucune valeur d\'attribut trouvée pour l\'équipement $equipmentCode',
        );
      }

      final attributesData = List<Map<String, dynamic>>.from(
        cachedData['attributes'],
      );

      // Trouver et mettre à jour l'attribut
      bool updated = false;
      for (int i = 0; i < attributesData.length; i++) {
        if (attributesData[i]['id'] == attributeId) {
          attributesData[i]['value'] = newValue;
          updated = true;
          break;
        }
      }

      if (!updated) {
        throw Exception(
          '$__logName Attribut $attributeId non trouvé pour l\'équipement $equipmentCode',
        );
      }

      // Sauvegarder les modifications
      final updatedCacheData = Map<String, dynamic>.from(cachedData);
      updatedCacheData['attributes'] = attributesData;
      updatedCacheData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      updatedCacheData['lastModified'] = DateTime.now().toIso8601String();

      await attributeValuesBox.put(equipmentCode, updatedCacheData);
      await _updateTimestamp('attribute_values_$equipmentCode');

      if (kDebugMode) {
        print(
          '✅ $__logName GMAO: Valeur d\'attribut mise à jour pour équipement $equipmentCode',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur mise à jour valeur d\'attribut: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Nettoyer tous les caches d'attributs
  static Future<void> clearAllAttributeCaches() async {
    try {
      // Nettoyer toutes les clés qui commencent par 'attribute_values_' OU qui sont des spécifications
      final keys =
          attributeValuesBox.keys.where((key) {
            final keyStr = key.toString();
            return keyStr.startsWith('attribute_values_') ||
                keyStr.contains('_') && !keyStr.startsWith('attribute_values_');
          }).toList();

      for (final key in keys) {
        await attributeValuesBox.delete(key);
        await metadataBox.delete('attribute_values_$key');

        // Nettoyer aussi les métadonnées des spécifications
        if (!key.toString().startsWith('attribute_values_')) {
          await metadataBox.delete('attribute_spec_$key');
        }
      }

      if (kDebugMode) {
        print(
          '🗑️ $__logName GMAO: Tous les caches d\'attributs nettoyés (${keys.length} entrées)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur nettoyage complet cache attributs: $e');
      }
    }
  }

  /// ✅ NOUVEAU: Obtenir tous les équipements avec valeurs d'attributs en cache
  static List<String> getEquipmentsWithCachedAttributes() {
    try {
      return attributeValuesBox.keys.map((key) => key.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur liste équipements avec attributs: $e');
      }
      return [];
    }
  }

  /// ✅ NOUVEAU: Statistiques des valeurs d'attributs
  static Map<String, dynamic> getAttributeValuesStats() {
    try {
      final equipmentCodes = attributeValuesBox.keys.toList();
      int totalAttributes = 0;

      for (final code in equipmentCodes) {
        final data = attributeValuesBox.get(code);
        if (data != null && data['attributes'] is List) {
          totalAttributes += (data['attributes'] as List).length;
        }
      }

      return {
        'equipments_with_attributes': equipmentCodes.length,
        'total_attributes': totalAttributes,
        'cache_size_mb':
            (attributeValuesBox.toMap().toString().length / (1024 * 1024))
                .round(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName GMAO: Erreur statistiques valeurs d\'attributs: $e');
      }
      return {
        'equipments_with_attributes': 0,
        'total_attributes': 0,
        'cache_size_mb': 0,
      };
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
      case 'attribute_values':
        await attributeValuesBox.clear();
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
    await attributeValuesBox.clear();

    if (kDebugMode) {
      print('🗑️ $__logName GMAO: Tout le cache vidé');
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
        } else if (cacheKey.contains('attribute_values')) {
          final equipmentCode = cacheKey.replaceAll('attribute_values_', '');
          await attributeValuesBox.delete(equipmentCode);
        }
        await metadataBox.delete(key);
        if (kDebugMode) {
          print('🗑️ $__logName GMAO: Cache expiré nettoyé: $cacheKey');
        }
      }
    }

    if (kDebugMode) {
      print('🗑️ $__logName GMAO: Cache expiré nettoyé');
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
      'attribute_values': attributeValuesBox.length,
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
      'attribute_values_mb':
          (attributeValuesBox.toMap().toString().length / (1024 * 1024))
              .round(),
    };
  }
}
