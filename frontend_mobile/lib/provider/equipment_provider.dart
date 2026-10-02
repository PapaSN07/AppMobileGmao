import 'package:appmobilegmao/services/pending_equipment_changes.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:appmobilegmao/utils/selector_loader.dart';

import 'package:appmobilegmao/services/connectivity_service.dart';
import 'package:appmobilegmao/services/offline_snapshots.dart';
import 'dart:async';
import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/historique_equipment.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _equipmentService = EquipmentService();
  final Connectivity _connectivity = Connectivity();
  late AuthProvider _authProvider; // ✅ Mutable pour supporter les mises à jour du ProxyProvider

  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _allEquipments = [];
  Map<String, String> _filters = {};
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  Map<String, dynamic>? _cachedSelectors;
  bool _selectorsLoaded = false;

  final Map<String, List<EquipmentAttribute>> _equipmentAttributes = {};
  final Map<String, List<EquipmentAttribute>> _attributeSpecifications = {};
  bool _attributesLoading = false;

  String? _lastLoadedEntity;
  final int _pageSize = 50;
  int _displayedCount = 50;
  bool _isLoadingMore = false;

  // ✅ Constructeur avec injection d'AuthProvider
  EquipmentProvider(this._authProvider) {
    _reconnection = ConnectivityService().onReconnected(() {
      if (_offlineSince != null || _error != null) fetchEquipments(forceRefresh: true);
    });
  }

  late final StreamSubscription<bool> _reconnection;

  @override
  void dispose() {
    _reconnection.cancel();
    super.dispose();
  }

  // ✅ FIX : Méthode appelée par ProxyProvider quand AuthProvider change (entité active modifiée dans les OT)
  void onAuthProviderUpdated(AuthProvider newAuthProvider) {
    _authProvider = newAuthProvider;
    final newEntity = newAuthProvider.activeEntity;
    // Recharger les équipements si l'entité active a changé
    if (_lastLoadedEntity != newEntity && newEntity.isNotEmpty) {
      if (kDebugMode) {
        print('🔄 EquipmentProvider: entité changée $_lastLoadedEntity → $newEntity, rechargement...');
      }
      _lastLoadedEntity = newEntity;
      // Appelé pendant la reconstruction des providers : on recharge juste après
      Future.microtask(() => fetchEquipments(forceRefresh: true));
    }
  }

  /// Numéro de la dernière demande de liste : au démarrage plusieurs demandes partent
  /// en même temps (écran, changement de service) ; seule la plus récente compte.
  int _fetchGeneration = 0;

  // Getters
  List<Map<String, dynamic>> get equipments => _equipments;
  List<Map<String, dynamic>> get visibleEquipments => _equipments.take(_displayedCount).toList();
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _displayedCount < _equipments.length;
  String? get error => _error;
  bool get isOffline => _isOffline;

  /// Liste affichée sans réseau : date de la copie enregistrée, sinon null.
  DateTime? _offlineSince;
  DateTime? get offlineSince => _offlineSince;

  static String _snapshotKey(String entity) => 'equipments|$entity';

  /// Affiche la dernière liste enregistrée pour [entity] ; false s'il n'y en a pas.
  bool _restoreSnapshot(String entity) {
    final saved = OfflineSnapshots.readList(_snapshotKey(entity));
    if (saved == null) return false;
    _allEquipments = saved.data;
    _equipments = List.from(_allEquipments);
    _displayedCount = _pageSize;
    _offlineSince = saved.savedAt;
    _error = null;
    return true;
  }
  Map<String, dynamic>? get cachedSelectors => _cachedSelectors;
  bool get selectorsLoaded => _selectorsLoaded;
  bool get attributesLoading => _attributesLoading;

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _displayedCount = (_displayedCount + _pageSize).clamp(0, _equipments.length);
    _isLoadingMore = false;
    notifyListeners();
  }

  // ✅ Initialisation avec entity de l'utilisateur
  Future<void> initialize() async {
    await _checkConnectivity();

    // ✅ Définir l'entity dans les filtres dès le départ
    final entity = _authProvider.activeEntity;
    if (entity.isNotEmpty) {
      _filters['entity'] = entity;
      await fetchEquipments();
    } else {
      _error = 'Utilisateur non connecté ou entité manquante';
      notifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result != ConnectivityResult.none) {
      _isOffline = false;
    } else {
      final base = ApiService().baseUrl;
      _isOffline = !(base.contains('127.0.0.1') || base.contains('10.0.2.2') || base.contains('localhost') || base.contains('192.168.'));
    }
  }

  // ✅ fetchEquipments : entity OBLIGATOIRE (vient de l'utilisateur/activeEntity) - 100% API Réelle
  Future<void> fetchEquipments({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    final generation = ++_fetchGeneration;
    bool isOutdated() => generation != _fetchGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _checkConnectivity();
      if (isOutdated()) return;

      final entity = _authProvider.activeEntity;
      if (entity.isEmpty) {
        _error = 'Entité utilisateur non définie';
        _isLoading = false;
        notifyListeners();
        return;
      }
      _lastLoadedEntity = entity;
      _filters['entity'] = entity;

      if (!forceRefresh && _allEquipments.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (!_isOffline) {
        final response = await _equipmentService.getEquipments(
          entity: entity,
          zone: _filters['zone'],
          famille: _filters['famille'],
          search: _filters['search'],
          description: _filters['description'],
        ).timeout(const Duration(seconds: 30));
        // Une demande plus récente (autre service) est partie entre-temps : sa réponse prime
        if (isOutdated()) return;

        final apiItems = response.items.map(_toMap).toList();
        _allEquipments = _deduplicateList(apiItems);
        _equipments = List.from(_allEquipments);
        _displayedCount = _pageSize;
        _offlineSince = null;
        // Liste complète du service (sans recherche) : gardée pour la consultation hors ligne
        if ((_filters['search'] ?? '').isEmpty && (_filters['description'] ?? '').isEmpty &&
            (_filters['zone'] ?? '').isEmpty && (_filters['famille'] ?? '').isEmpty) {
          unawaited(OfflineSnapshots.saveList(_snapshotKey(entity), _allEquipments));
        }
      } else if (!_restoreSnapshot(entity)) {
        _error = 'Mode hors-ligne : aucune liste enregistrée sur ce téléphone pour ce service';
      }
    } catch (e) {
      if (isOutdated()) return;
      if (isNetworkFailure(e) && _restoreSnapshot(_authProvider.activeEntity)) return;
      _error = 'Erreur lors de la récupération des équipements réels: ${e.toString()}';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      if (!isOutdated()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<Map<String, dynamic>> _deduplicateList(List<Map<String, dynamic>> list) {
    final seenKeys = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      final code = item['code']?.toString().trim().toUpperCase() ?? '';
      final id = item['id']?.toString().trim() ?? '';
      final key = code.isNotEmpty ? code : id;
      if (key.isNotEmpty && seenKeys.add(key)) {
        result.add(item);
      }
    }
    return result;
  }

    /// ✅ CORRIGÉ: Charge l'historique avec cache Hive
  Future<List<HistoriqueEquipment>> loadHistoriqueEquipmentPrestataire({
    required String username,
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentProvider: Récupération historique pour $username',
        );
      }
  
      // 1. ✅ Cache d'abord (si pas de refresh forcé)
      if (!forceRefresh) {
        final cached = HiveService.historiqueEquipmentBox.values
            .where((h) => h.createdBy == username)
            .toList();
  
        if (cached.isNotEmpty) {
          if (kDebugMode) {
            print(
              '� EquipmentProvider: ${cached.length} items depuis cache',
            );
          }
          return cached;
        }
      }
  
      // 2. ✅ Vérifier connectivité
      await _checkConnectivity();
      if (_isOffline) {
        // Fallback cache en mode hors ligne
        final cached = HiveService.historiqueEquipmentBox.values
            .where((h) => h.createdBy == username)
            .toList();
  
        if (cached.isNotEmpty) {
          if (kDebugMode) {
            print(
              '📦 EquipmentProvider: ${cached.length} items depuis cache (mode hors ligne)',
            );
          }
          return cached;
        }
  
        throw Exception('Aucune donnée disponible hors ligne');
      }
  
      // 3. ✅ Charger depuis l'API
      final historique = await _equipmentService.getHistoriqueEquipmentPrestataire(
        username: username,
      );
  
      // 4. ✅ Mettre en cache
      if (historique.isNotEmpty) {
        // Supprimer l'ancien cache pour cet utilisateur
        final oldKeys = HiveService.historiqueEquipmentBox.values
            .where((h) => h.createdBy == username)
            .map((h) => h.key)
            .toList();
  
        for (final key in oldKeys) {
          await HiveService.historiqueEquipmentBox.delete(key);
        }
  
        // Ajouter le nouveau cache
        for (final item in historique) {
          await HiveService.historiqueEquipmentBox.add(item);
        }
  
        if (kDebugMode) {
          print(
            '💾 EquipmentProvider: ${historique.length} items mis en cache',
          );
        }
      }
  
      return historique;
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ EquipmentProvider: Erreur loadHistoriqueEquipmentPrestataire: $e',
        );
      }
      rethrow;
    }
  }

  // ✅ loadSelectors : entity OBLIGATOIRE (vient de l'utilisateur) depuis l'API réelle
  Future<Map<String, dynamic>> loadSelectors() async {
    final entity = _authProvider.currentUser?.entity ?? 'SDDRCO2';
    final extracted = _buildSelectorsFromEquipments();

    try {
      final apiSelectors = await _equipmentService.getEquipmentSelectors(
        entity: entity,
      );

      final mergedFamilles = _mergeSelectorsList<Famille>(
        (apiSelectors['familles'] as List<Famille>?) ?? [],
        (extracted['familles'] as List<Famille>),
        (f) => f.description,
      );
      final mergedZones = _mergeSelectorsList<Zone>(
        (apiSelectors['zones'] as List<Zone>?) ?? [],
        (extracted['zones'] as List<Zone>),
        (z) => z.description,
      );
      final mergedEntities = _mergeSelectorsList<Entity>(
        (apiSelectors['entities'] as List<Entity>?) ?? [],
        (extracted['entities'] as List<Entity>),
        (e) => e.description,
      );
      final mergedUnites = _mergeSelectorsList<Unite>(
        (apiSelectors['unites'] as List<Unite>?) ?? [],
        (extracted['unites'] as List<Unite>),
        (u) => u.description,
      );
      final mergedCentreCharges = _mergeSelectorsList<CentreCharge>(
        (apiSelectors['centreCharges'] as List<CentreCharge>?) ?? [],
        (extracted['centreCharges'] as List<CentreCharge>),
        (c) => c.description,
      );
      final mergedFeeders = _mergeSelectorsList<Feeder>(
        (apiSelectors['feeders'] as List<Feeder>?) ?? [],
        (extracted['feeders'] as List<Feeder>),
        (f) => f.description,
      );

      final merged = {
        'familles': mergedFamilles,
        'zones': mergedZones,
        'entities': mergedEntities,
        'unites': mergedUnites,
        'centreCharges': mergedCentreCharges,
        'feeders': mergedFeeders,
      };

      await HiveService.put(HiveService.selectorsBox, 'selectors', merged);
      _cachedSelectors = merged;
      _selectorsLoaded = true;
      return merged;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ loadSelectors API: $e -> utilisation sélecteurs extraits');
      }
      _cachedSelectors = extracted;
      _selectorsLoaded = true;
      return extracted;
    }
  }

  List<T> _mergeSelectorsList<T>(List<T> list1, List<T> list2, String Function(T) keyExtractor) {
    final seen = <String>{};
    final result = <T>[];

    for (final item in list1) {
      final key = keyExtractor(item).trim().toUpperCase();
      if (key.isNotEmpty && seen.add(key)) {
        result.add(item);
      }
    }
    for (final item in list2) {
      final key = keyExtractor(item).trim().toUpperCase();
      if (key.isNotEmpty && seen.add(key)) {
        result.add(item);
      }
    }
    return result;
  }

  Map<String, dynamic> _buildSelectorsFromEquipments() {
    final Map<String, List<String>> collections = {
      'familles': [],
      'zones': [],
      'entities': [],
      'unites': [],
      'centreCharges': [],
      'feeders': [],
    };

    for (final eq in _allEquipments) {
      final famille = eq['famille']?.toString().trim();
      if (famille != null && famille.isNotEmpty && !collections['familles']!.contains(famille)) {
        collections['familles']!.add(famille);
      }
      final zone = eq['zone']?.toString().trim();
      if (zone != null && zone.isNotEmpty && !collections['zones']!.contains(zone)) {
        collections['zones']!.add(zone);
      }
      final entity = eq['entity']?.toString().trim();
      if (entity != null && entity.isNotEmpty && !collections['entities']!.contains(entity)) {
        collections['entities']!.add(entity);
      }
      final unite = eq['unite']?.toString().trim();
      if (unite != null && unite.isNotEmpty && !collections['unites']!.contains(unite)) {
        collections['unites']!.add(unite);
      }
      final centre = eq['centreCharge']?.toString().trim() ?? eq['centre_charge']?.toString().trim();
      if (centre != null && centre.isNotEmpty && !collections['centreCharges']!.contains(centre)) {
        collections['centreCharges']!.add(centre);
      }
      final feeder = eq['feeder']?.toString().trim();
      if (feeder != null && feeder.isNotEmpty && !collections['feeders']!.contains(feeder)) {
        collections['feeders']!.add(feeder);
      }
    }

    return {
      'familles': collections['familles']!.asMap().entries.map((entry) => Famille(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        parentCategory: '',
        systemCategory: '',
        level: '1',
        entity: '',
      )).toList(),

      'zones': collections['zones']!.asMap().entries.map((entry) => Zone(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        entity: '',
      )).toList(),

      'entities': collections['entities']!.asMap().entries.map((entry) => Entity(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        parentCategory: '',
        systemCategory: '',
        level: '1',
        entity: '',
      )).toList(),

      'unites': collections['unites']!.asMap().entries.map((entry) => Unite(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        entity: '',
      )).toList(),

      'centreCharges': collections['centreCharges']!.asMap().entries.map((entry) => CentreCharge(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        entity: '',
      )).toList(),

      'feeders': collections['feeders']!.asMap().entries.map((entry) => Feeder(
        id: (entry.key + 1).toString(),
        code: entry.value,
        description: entry.value,
        entity: '',
      )).toList(),
    };
  }

  // ✅ addEquipment : entity LIBRE (saisie par l'utilisateur dans equipmentData)
  /// Ajoute un équipement (proposition à valider sur le web). Sans réseau, il est gardé
  /// sur le téléphone et envoyé automatiquement au retour du réseau : renvoie alors true.
  Future<bool> addEquipment(Map<String, dynamic> equipmentData) async {
    final currentUser = _authProvider.currentUser;
    // L'écran envoie des codes ; un libellé éventuel est converti en code, jamais tronqué.
    String codeOf(String key, String selectorType) {
      final value = equipmentData[key]?.toString();
      return SelectorLoader.extractCodeFromTypedSelectors(value, selectorType, _cachedSelectors) ?? value ?? '';
    }

    final equipment = Equipment(
      code: equipmentData['code'] ?? '',
      description: equipmentData['description'] ?? '',
      famille: codeOf('famille', 'familles'),
      zone: codeOf('zone', 'zones'),
      entity: codeOf('entity', 'entities'),
      unite: codeOf('unite', 'unites'),
      centreCharge: codeOf('centreCharge', 'centreCharges'),
      codeParent: equipmentData['codeParent'] ?? '',
      feeder: codeOf('feeder', 'feeders'),
      feederDescription: equipmentData['feederDescription'],
      longitude: equipmentData['longitude'] ?? '',
      latitude: equipmentData['latitude'] ?? '',
      attributes: _extractAttributes(equipmentData['attributs']),
      createdBy: currentUser?.username ?? '',
    );
    if (equipment.famille.isEmpty) throw Exception('Famille équipement requise');

    await _checkConnectivity();
    var queued = _isOffline;
    if (!queued) {
      try {
        await _equipmentService.addEquipment(equipment);
      } catch (e) {
        if (!isNetworkFailure(e)) rethrow;
        queued = true;
      }
    }
    if (queued) {
      await PendingOtQueue.enqueue(
        PendingOtKind.createEquipment,
        equipment.code,
        data: equipment.toJson(),
        username: currentUser?.username ?? '',
      );
    } else {
      await PendingEquipmentChanges.markPending(equipment.code);
    }

    final shown = _toMap(equipment);
    _allEquipments.insert(0, shown);
    _equipments.insert(0, shown);
    notifyListeners();
    return queued;
  }

  Future<bool> createEquipment(Map<String, dynamic> equipmentData) => addEquipment(equipmentData);

  // Mettre à jour équipement
  Future<void> updateEquipment(String idOrCode, Map<String, dynamic> fields) async {
    int? numericId = int.tryParse(idOrCode);

    if (numericId == null) {
      final found = _allEquipments.firstWhere(
        (e) => e['code']?.toString() == idOrCode || e['id']?.toString() == idOrCode,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty && found['id'] != null) {
        numericId = int.tryParse(found['id'].toString());
      }
    }

    // Sans identifiant, le serveur ne peut pas recevoir la modification :
    // on le dit plutôt que de modifier seulement l'affichage du téléphone.
    if (numericId == null) {
      throw Exception('Équipement sans identifiant : la modification ne peut pas être envoyée au serveur.');
    }

    try {
      await _checkConnectivity();
      if (!_isOffline) {
        final updated = await _equipmentService.updateEquipment(numericId, fields);
        final updatedMap = _toMap(updated);

        final idxAll = _allEquipments.indexWhere((e) => e['id']?.toString() == numericId.toString() || e['code']?.toString() == idOrCode);
        if (idxAll != -1) _allEquipments[idxAll] = updatedMap;

        final idx = _equipments.indexWhere((e) => e['id']?.toString() == numericId.toString() || e['code']?.toString() == idOrCode);
        if (idx != -1) _equipments[idx] = updatedMap;

        notifyListeners();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ API update error: $e, mise à jour locale effectuée');
      }
    }

    // Fallback mise à jour locale
    final idxAll = _allEquipments.indexWhere((e) => e['id']?.toString() == numericId.toString() || e['code']?.toString() == idOrCode);
    if (idxAll != -1) {
      _allEquipments[idxAll] = {..._allEquipments[idxAll], ...fields};
      _equipments = List.from(_allEquipments);
      notifyListeners();
    }
  }

  // Charger attributs équipement
  Future<List<EquipmentAttribute>> loadEquipmentAttributes(String code) async {
    if (_attributesLoading) return _equipmentAttributes[code] ?? [];
    _attributesLoading = true;
    notifyListeners();

    try {
      final cached = await HiveService.getAttributeValues(code);
      if (cached != null && cached.isNotEmpty) {
        _equipmentAttributes[code] = cached;
        return cached;
      }

      final eq = _allEquipments.firstWhere(
        (e) => e['code'] == code,
        orElse: () => {},
      );
      if (eq.isEmpty) throw Exception('Équipement $code non trouvé');

      List<EquipmentAttribute> attrs = [];
      if (eq['attributes'] is List) {
        attrs =
            (eq['attributes'] as List).map((a) {
              if (a is Map<String, dynamic>) {
                return EquipmentAttribute.fromJson(a);
              }
              return a as EquipmentAttribute;
            }).toList();
      }

      if (attrs.isNotEmpty) {
        await HiveService.cacheAttributeValues(code, attrs);
        _equipmentAttributes[code] = attrs;
      }
      return attrs;
    } finally {
      _attributesLoading = false;
      notifyListeners();
    }
  }

  // Charger valeurs possibles d'un attribut
  Future<List<EquipmentAttribute>> loadPossibleValuesForAttribute(
    String specification,
    String attributeIndex,
  ) async {
    final key = '${specification}_$attributeIndex';
    if (_attributeSpecifications.containsKey(key)) {
      return _attributeSpecifications[key]!;
    }

    _attributesLoading = true;
    notifyListeners();

    try {
      final cacheKey = 'spec_${specification}_$attributeIndex';
      final cached = HiveService.get(HiveService.attributeValuesBox, cacheKey);
      if (cached != null && cached['attributes'] is List) {
        final attrs =
            (cached['attributes'] as List)
                .map(
                  (e) =>
                      EquipmentAttribute.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
        _attributeSpecifications[key] = attrs;
        return attrs;
      }

      final apiResponse = await _equipmentService.getAttributeValuesEquipment(
        specification: specification,
        attributeIndex: attributeIndex,
      );

      final attrs =
          apiResponse['attributes'] as List<EquipmentAttribute>? ?? [];

      await HiveService.put(HiveService.attributeValuesBox, cacheKey, {
        'attributes': attrs.map((a) => a.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      });

      _attributeSpecifications[key] = attrs;
      return attrs;
    } catch (e) {
      _attributeSpecifications[key] = [];
      return [];
    } finally {
      _attributesLoading = false;
      notifyListeners();
    }
  }

  // Filtres
  Future<void> applyFilters(Map<String, String> filters) async {
    _filters = Map.from(filters);
    // ✅ Toujours garder l'entity de l'utilisateur
    final entity = _authProvider.currentUser?.entity;
    if (entity != null) _filters['entity'] = entity;
    await fetchEquipments(forceRefresh: true);
  }

  Future<void> clearFilters() async {
    _filters.clear();
    // ✅ Toujours garder l'entity
    final entity = _authProvider.currentUser?.entity;
    if (entity != null) _filters['entity'] = entity;
    await fetchEquipments(forceRefresh: true);
  }

  void filterEquipments(String searchTerm) {
    _displayedCount = _pageSize;
    if (searchTerm.isEmpty) {
      _equipments = List.from(_allEquipments);
    } else {
      final q = searchTerm.toLowerCase();
      _equipments =
          _allEquipments.where((e) {
            final text =
                [
                  e['code'],
                  e['description'],
                  e['famille'],
                  e['zone'],
                  e['entity'],
                  e['unite'],
                ].where((v) => v != null).join(' ').toLowerCase();
            return text.contains(q);
          }).toList();
    }
    notifyListeners();
  }

  // ✅ NOUVELLES méthodes pour filtrer par champ spécifique
  void filterEquipmentsByField(String searchTerm, String field) {
    _displayedCount = _pageSize;
    if (searchTerm.isEmpty) {
      _equipments = List.from(_allEquipments);
    } else {
      final q = searchTerm.toLowerCase();
      _equipments =
          _allEquipments.where((e) {
            final value = e[field]?.toString().toLowerCase() ?? '';
            return value.contains(q);
          }).toList();
    }
    notifyListeners();
  }

  // ✅ Méthode pour appliquer des filtres avancés (zone, famille, etc.)
  Future<void> applyAdvancedFilters(Map<String, String> filters) async {
    _filters.addAll(filters);
    // Garder l'entity de l'utilisateur
    final entity = _authProvider.currentUser?.entity;
    if (entity != null) _filters['entity'] = entity;
    await fetchEquipments(forceRefresh: true);
  }

  // Helpers
  Map<String, dynamic> _toMap(Equipment eq) => {
    'id': eq.id,
    'code': eq.code,
    'description': eq.description,
    'famille': eq.famille,
    'zone': eq.zone,
    'entity': eq.entity,
    'unite': eq.unite,
    'centreCharge': eq.centreCharge,
    'codeParent': eq.codeParent,
    'feeder': eq.feeder,
    'feederDescription': eq.feederDescription,
    'longitude': eq.longitude,
    'latitude': eq.latitude,
    'attributes': eq.attributes?.map((a) => a.toJson()).toList() ?? [],
  };

  List<EquipmentAttribute>? _extractAttributes(dynamic attributsData) {
    if (attributsData == null || attributsData is! List) return null;
    return attributsData.map((a) {
      if (a is Map<String, dynamic>) {
        return EquipmentAttribute(
          id: a['id']?.toString(),
          specification: a['specification']?.toString(),
          index: a['index']?.toString(),
          name: a['name']?.toString(),
          value: a['value']?.toString() ?? '',
          type: a['type']?.toString() ?? 'string',
        );
      }
      return a as EquipmentAttribute;
    }).toList();
  }

  Future<bool> deleteEquipment(String equipmentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _equipmentService.deleteEquipment(equipmentId);
      if (success) {
        _equipments.removeWhere((e) => e['id']?.toString() == equipmentId || e['code']?.toString() == equipmentId);
        _allEquipments.removeWhere((e) => e['id']?.toString() == equipmentId || e['code']?.toString() == equipmentId);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
