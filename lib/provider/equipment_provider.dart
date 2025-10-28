import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:appmobilegmao/provider/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appmobilegmao/services/equipment_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _equipmentService = EquipmentService();
  final Connectivity _connectivity = Connectivity();
  late final AuthProvider _authProvider; // ✅ Changé en late pour injection

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

  // ✅ Constructeur avec injection d'AuthProvider
  EquipmentProvider(this._authProvider);

  // Getters
  List<Map<String, dynamic>> get equipments => _equipments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  Map<String, dynamic>? get cachedSelectors => _cachedSelectors;
  bool get selectorsLoaded => _selectorsLoaded;
  bool get attributesLoading => _attributesLoading;

  // ✅ Initialisation avec entity de l'utilisateur
  Future<void> initialize() async {
    await _checkConnectivity();

    // ✅ Définir l'entity dans les filtres dès le départ
    final entity = _authProvider.currentUser?.entity;
    if (entity != null && entity.isNotEmpty) {
      _filters['entity'] = entity;
      await fetchEquipments();
    } else {
      _error = 'Utilisateur non connecté ou entité manquante';
      notifyListeners();
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOffline = result == ConnectivityResult.none;
  }

  // ✅ fetchEquipments : entity OBLIGATOIRE (vient de l'utilisateur)
  Future<void> fetchEquipments({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _checkConnectivity();

      // ✅ Entity OBLIGATOIRE vient de l'utilisateur connecté
      final entity = _authProvider.currentUser?.entity;
      if (entity == null || entity.isEmpty) {
        throw Exception(
          'L\'entité est obligatoire pour charger les équipements. Veuillez vous reconnecter.',
        );
      }

      // ✅ S'assurer que l'entity est dans les filtres
      _filters['entity'] = entity;

      // 1. Cache d'abord (si pas de refresh forcé)
      if (!forceRefresh) {
        final cached = HiveService.equipmentBox.values.toList();
        if (cached.isNotEmpty) {
          final filteredCache = _filterCachedEquipments(cached, entity);
          if (filteredCache.isNotEmpty) {
            _allEquipments = filteredCache.map(_toMap).toList();
            _equipments = List.from(_allEquipments);
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }

      // 2. API si en ligne
      if (!_isOffline) {
        final response = await _equipmentService.getEquipments(
          entity: entity, // ✅ entity obligatoire
          zone: _filters['zone'],
          famille: _filters['famille'],
          search: _filters['search'],
          description: _filters['description'],
        );

        _allEquipments = response.items.map(_toMap).toList();
        _equipments = List.from(_allEquipments);

        // Cache uniquement si pas de filtres autres que entity
        if (_filters.length == 1 && _filters.containsKey('entity')) {
          await HiveService.clearBox(HiveService.equipmentBox);
          for (final eq in response.items) {
            await HiveService.equipmentBox.add(eq);
          }
          if (kDebugMode) {
            print('✅ ${response.items.length} équipements mis en cache');
          }
        }
      } else {
        throw Exception('Aucune donnée disponible hors ligne');
      }
    } catch (e) {
      _error = e.toString();
      // Fallback cache
      final entity = _authProvider.currentUser?.entity;
      if (entity != null && entity.isNotEmpty) {
        final cached = HiveService.equipmentBox.values.toList();
        final filteredCache = _filterCachedEquipments(cached, entity);
        if (filteredCache.isNotEmpty) {
          _allEquipments = filteredCache.map(_toMap).toList();
          _equipments = List.from(_allEquipments);
          _error =
              'Données en mode hors ligne (${_allEquipments.length} équipements)';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Equipment> _filterCachedEquipments(
    List<Equipment> cached,
    String entity,
  ) {
    var filtered = cached.where((eq) => eq.entity == entity);

    if (_filters['zone'] != null && _filters['zone']!.isNotEmpty) {
      filtered = filtered.where((eq) => eq.zone == _filters['zone']);
    }
    if (_filters['famille'] != null && _filters['famille']!.isNotEmpty) {
      filtered = filtered.where((eq) => eq.famille == _filters['famille']);
    }
    if (_filters['search'] != null && _filters['search']!.isNotEmpty) {
      final search = _filters['search']!.toLowerCase();
      filtered = filtered.where(
        (eq) =>
            eq.code.toLowerCase().contains(search) ||
            eq.description.toLowerCase().contains(search),
      );
    }

    return filtered.toList();
  }

  // ✅ loadSelectors : entity OBLIGATOIRE (vient de l'utilisateur)
  Future<Map<String, dynamic>> loadSelectors() async {
    // ✅ Entity OBLIGATOIRE vient de l'utilisateur
    final entity = _authProvider.currentUser?.entity;
    if (entity == null || entity.isEmpty) {
      throw Exception('Utilisateur non connecté ou entité manquante');
    }

    // Cache d'abord
    final cached = HiveService.get(HiveService.selectorsBox, 'selectors');
    if (cached != null && cached is Map<String, dynamic>) {
      _cachedSelectors = cached;
      _selectorsLoaded = true;
      return cached;
    }

    // API
    final apiSelectors = await _equipmentService.getEquipmentSelectors(
      entity: entity,
    );
    await HiveService.put(HiveService.selectorsBox, 'selectors', apiSelectors);
    _cachedSelectors = apiSelectors;
    _selectorsLoaded = true;
    return apiSelectors;
  }

  // ✅ addEquipment : entity LIBRE (saisie par l'utilisateur dans equipmentData)
  Future<void> addEquipment(Map<String, dynamic> equipmentData) async {
    await _checkConnectivity();
    if (_isOffline) throw Exception('Mode hors ligne');
    var currentUser = _authProvider.currentUser;

    final equipment = Equipment(
      code: equipmentData['code'] ?? '',
      description: equipmentData['description'] ?? '',
      famille: _extractCode(equipmentData['famille'], 'familles') ?? '',
      zone: _extractCode(equipmentData['zone'], 'zones') ?? '',
      entity:
          _extractCode(equipmentData['entity'], 'entities') ??
          '', // ✅ Saisie utilisateur
      unite: _extractCode(equipmentData['unite'], 'unites') ?? '',
      centreCharge:
          _extractCode(equipmentData['centreCharge'], 'centreCharges') ?? '',
      codeParent: equipmentData['codeParent'] ?? '',
      feeder: _extractCode(equipmentData['feeder'], 'feeders'),
      feederDescription: equipmentData['feederDescription'],
      longitude: equipmentData['longitude'] ?? '',
      latitude: equipmentData['latitude'] ?? '',
      attributes: _extractAttributes(equipmentData['attributs']),
      createdBy: currentUser?.username ?? '',
    );

    await _equipmentService.addEquipment(equipment);
    // final created = await _equipmentService.addEquipment(equipment);
    // final createdMap = _toMap(created);
    // _allEquipments.insert(0, createdMap);
    // _equipments.insert(0, createdMap);
    notifyListeners();
  }

  // Mettre à jour équipement
  Future<void> updateEquipment(String id, Map<String, dynamic> fields) async {
    await _checkConnectivity();
    if (_isOffline) throw Exception('Mode hors ligne');

    final updated = await _equipmentService.updateEquipment(int.parse(id), fields);
    final updatedMap = _toMap(updated);

    final idxAll = _allEquipments.indexWhere((e) => e['id'] == id);
    if (idxAll != -1) _allEquipments[idxAll] = updatedMap;

    final idx = _equipments.indexWhere((e) => e['id'] == id);
    if (idx != -1) _equipments[idx] = updatedMap;

    final boxIndex = HiveService.equipmentBox.values.toList().indexWhere(
      (eq) => eq.id == id,
    );
    if (boxIndex != -1) {
      await HiveService.equipmentBox.putAt(boxIndex, updated);
    }

    if (updated.attributes != null) {
      _equipmentAttributes[updated.code] = updated.attributes!;
    }

    notifyListeners();
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

  String? _extractCode(String? displayValue, String selectorType) {
    if (displayValue == null ||
        displayValue.isEmpty ||
        _cachedSelectors == null) {
      return null;
    }

    // ✅ CORRECTION: Gérer les objets typés au lieu des Maps
    final selectorData = _cachedSelectors![selectorType];

    if (selectorData == null) return null;

    try {
      // ✅ Détecter le type et extraire le code correspondant
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

        default:
          if (kDebugMode) {
            print(
              '⚠️ EquipmentProvider - Type de sélecteur inconnu: $selectorType',
            );
          }
          return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ EquipmentProvider - Erreur _extractCode pour $selectorType: $e',
        );
      }
      return null;
    }

    // Fallback: retourner la valeur tronquée si aucune correspondance
    if (kDebugMode) {
      print(
        '⚠️ EquipmentProvider - Aucune correspondance pour "$displayValue" dans $selectorType',
      );
    }
    return displayValue.length > 20
        ? displayValue.substring(0, 20)
        : displayValue;
  }

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
}
