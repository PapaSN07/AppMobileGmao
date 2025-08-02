import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appmobilegmao/services/equipment_api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/equipment.dart';
import 'package:appmobilegmao/models/reference_data.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentApiService _apiService = EquipmentApiService();
  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();

  // État de la liste d'équipements
  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _allEquipments = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _filters = {};
  bool _isOffline = false;

  // Données de référence
  ReferenceData? _referenceData;
  bool _isLoadingReference = false;

  // Getters
  List<Map<String, dynamic>> get equipments => _equipments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get filters => _filters;
  bool get isOffline => _isOffline;
  ReferenceData? get referenceData => _referenceData;
  bool get isLoadingReference => _isLoadingReference;

  // Initialisation
  Future<void> initialize() async {
    await _checkConnectivity();
    await loadReferenceData();
    await fetchEquipments();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOffline = result == ConnectivityResult.none;
  }

  // Charger les équipements
  Future<void> fetchEquipments({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      await _checkConnectivity();

      List<Equipment> equipments;

      // Charger depuis le cache si disponible
      if (!forceRefresh && (!_isOffline || await _isCacheValid())) {
        equipments = await _hiveService.getCachedEquipments(filters: _filters);
        if (equipments.isNotEmpty) {
          if (kDebugMode) {
            print('📋 GMAO: Chargement depuis cache');
          }
          _allEquipments = _convertToMapList(equipments);
          _equipments = List.from(_allEquipments);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Charger depuis l'API si connecté
      if (!_isOffline) {
        if (kDebugMode) {
          print('🌐 GMAO: Chargement depuis API');
        }

        final response = await _apiService.getEquipments(
          zone: _filters['zone'],
          famille: _filters['famille'],
          entity: _filters['entity'],
          search: _filters['search'],
          description: _filters['description'],
        );

        equipments = response.items;

        // Mettre en cache si pas de filtres
        if (_filters.isEmpty) {
          await _hiveService.cacheEquipments(equipments);
        }
      } else {
        // Mode hors ligne
        equipments = await _hiveService.getCachedEquipments(filters: _filters);
        if (equipments.isEmpty) {
          throw Exception('Aucune donnée disponible hors ligne');
        }
      }

      _allEquipments = _convertToMapList(equipments);
      _equipments = List.from(_allEquipments);

      if (kDebugMode) {
        print('📊 GMAO: ${equipments.length} équipements chargés');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode de recherche
  void filterEquipments(String searchTerm) {
    if (searchTerm.isEmpty) {
      _equipments = List.from(_allEquipments);
    } else {
      final lowercaseSearch = searchTerm.toLowerCase();
      _equipments = _allEquipments.where((equipment) {
        final code = equipment['code']?.toString().toLowerCase() ?? '';
        final description = equipment['description']?.toString().toLowerCase() ?? '';
        final zone = equipment['zone']?.toString().toLowerCase() ?? '';
        final famille = equipment['famille']?.toString().toLowerCase() ?? '';
        final entity = equipment['entity']?.toString().toLowerCase() ?? '';

        return code.contains(lowercaseSearch) ||
            description.contains(lowercaseSearch) ||
            zone.contains(lowercaseSearch) ||
            famille.contains(lowercaseSearch) ||
            entity.contains(lowercaseSearch);
      }).toList();
    }
    notifyListeners();
  }

  // Appliquer les filtres
  Future<void> applyFilters(Map<String, String> filters) async {
    _filters = Map.from(filters);
    await fetchEquipments(forceRefresh: true);
  }

  // Effacer les filtres
  Future<void> clearFilters() async {
    await applyFilters({});
  }

  // Charger les données de référence
  Future<void> loadReferenceData({bool forceRefresh = false}) async {
    if (_isLoadingReference) return;

    _isLoadingReference = true;
    notifyListeners();

    try {
      if (!forceRefresh) {
        final cached = await _hiveService.getCachedReferenceData();
        if (cached != null) {
          _referenceData = cached;
          _isLoadingReference = false;
          notifyListeners();
          return;
        }
      }

      if (!_isOffline) {
        final data = await _apiService.syncReferenceData();
        _referenceData = data;
        await _hiveService.cacheReferenceData(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur données référence: $e');
      }
      final cached = await _hiveService.getCachedReferenceData();
      if (cached != null) {
        _referenceData = cached;
      }
    } finally {
      _isLoadingReference = false;
      notifyListeners();
    }
  }

  // Méthode helper pour gérer les erreurs
  void _handleError(dynamic e) {
    if (kDebugMode) {
      print('❌ GMAO: Erreur chargement équipements: $e');
    }
    _error = e.toString();

    // Fallback sur cache en cas d'erreur
    _tryLoadFromCache();
  }

  Future<void> _tryLoadFromCache() async {
    try {
      final cached = await _hiveService.getCachedEquipments(filters: _filters);
      if (cached.isNotEmpty) {
        _allEquipments = _convertToMapList(cached);
        _equipments = List.from(_allEquipments);
        _error = 'Données en mode hors ligne';
      }
    } catch (cacheError) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur fallback cache: $cacheError');
      }
    }
  }

  // ✅ Méthode compatible avec add_equipment_screen.dart
  Future<void> addEquipment(Map<String, dynamic> equipmentData) async {
    try {
      await _checkConnectivity();

      if (!_isOffline) {
        // Envoyer à l'API
        final equipment = Equipment(
          code: equipmentData['code'] ?? '',
          famille: equipmentData['famille'] ?? '',
          zone: equipmentData['zone'] ?? '',
          entity: equipmentData['entity'] ?? '',
          unite: equipmentData['unite'] ?? '',
          centreCharge: equipmentData['centreCharge'] ?? '',
          description: equipmentData['description'] ?? '',
          longitude: equipmentData['longitude'] ?? '',
          latitude: equipmentData['latitude'] ?? '',
          codeParent: equipmentData['codeParent'],
          feeder: equipmentData['feeder'],
          feederDescription: equipmentData['infoFeeder'],
        );

        // Simuler l'ajout API (à remplacer par votre vraie API)
        final newEquipmentMap = _convertEquipmentToMap(equipment);
        newEquipmentMap['id'] =
            DateTime.now().millisecondsSinceEpoch.toString();

        // Ajouter à la liste locale
        _allEquipments.insert(0, newEquipmentMap);
        _equipments.insert(0, newEquipmentMap);

        // Mettre en cache
        await _hiveService.cacheEquipments([equipment]);

        if (kDebugMode) {
          print('✅ GMAO: Équipement ajouté avec succès');
        }
      } else {
        throw Exception(
          'Impossible d\'ajouter un équipement en mode hors ligne',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur ajout équipement: $e');
      }
      rethrow;
    }
  }

  // ✅ Méthode compatible avec modify_equipment_screen.dart
  Future<void> updateEquipment(
    String equipmentId,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      await _checkConnectivity();

      if (!_isOffline) {
        // Trouver l'équipement à modifier
        final index = _allEquipments.indexWhere(
          (eq) => eq['id'] == equipmentId,
        );
        if (index == -1) {
          throw Exception('Équipement non trouvé');
        }

        // Mettre à jour les champs modifiés
        final updatedEquipment = Map<String, dynamic>.from(
          _allEquipments[index],
        );
        updatedFields.forEach((key, value) {
          updatedEquipment[key] = value;
        });

        // Mettre à jour dans les listes
        _allEquipments[index] = updatedEquipment;
        final equipmentIndex = _equipments.indexWhere(
          (eq) => eq['id'] == equipmentId,
        );
        if (equipmentIndex != -1) {
          _equipments[equipmentIndex] = updatedEquipment;
        }

        if (kDebugMode) {
          print('✅ GMAO: Équipement modifié avec succès');
        }
      } else {
        throw Exception(
          'Impossible de modifier un équipement en mode hors ligne',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GMAO: Erreur modification équipement: $e');
      }
      rethrow;
    }
  }

  // Vérifier si le cache est valide
  Future<bool> _isCacheValid() async {
    return !await _hiveService.isCacheExpired();
  }

  // Conversion helper
  List<Map<String, dynamic>> _convertToMapList(List<Equipment> equipments) {
    return equipments.map((equipment) => _convertEquipmentToMap(equipment)).toList();
  }

  Map<String, dynamic> _convertEquipmentToMap(Equipment equipment) {
    return {
      'id': equipment.id,
      'codeParent': equipment.codeParent,
      'feeder': equipment.feeder,
      'feederDescription': equipment.feederDescription,
      'code': equipment.code,
      'famille': equipment.famille,
      'zone': equipment.zone,
      'entity': equipment.entity,
      'unite': equipment.unite,
      'centreCharge': equipment.centreCharge,
      'description': equipment.description,
      'longitude': equipment.longitude,
      'latitude': equipment.latitude,
      'attributs': equipment.attributs.map((attr) => {
        'name': attr.name,
        'value': attr.value,
        'type': attr.type,
      }).toList(),
    };
  }
}
