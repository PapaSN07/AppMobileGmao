import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/api_response.dart';
import '../models/reference_data.dart';
import 'api_service.dart';

class EquipmentApiService {
  late final ApiService _apiService;

  EquipmentApiService({ApiService? apiService}) {
    _apiService = apiService ?? ApiService(port: 8000);
    
    if (kDebugMode) {
      print('🔧 EquipmentApiService configuré avec: ${_apiService.currentBaseUrl}');
    }
  }

  /// Récupère la liste des équipements avec pagination et filtres
  Future<ApiResponse<Equipment>> getEquipments({
    required String entity,
    String? zone,
    String? famille,
    String? search,
    String? description,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (zone != null) 'zone': zone,
        if (famille != null) 'famille': famille,
        if (entity.isNotEmpty) 'entity': entity,
        if (search != null) 'search': search,
        if (description != null) 'description': description,
      };
      
      if (kDebugMode) {
        print('🔍 EquipmentApi - Requête équipements: $queryParams');
      }
      
      final data = await _apiService.get('/api/v1/equipments/', queryParameters: queryParams);
      return ApiResponse.fromJson(data, nameItem: 'equipments', fromJson: (json) => Equipment.fromJson(json));
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur getEquipments: $e');
      }
      rethrow;
    }
  }

  /// Récupère les détails d'un équipement spécifique
  Future<Equipment> getEquipmentDetail(String code) async {
    try {
      if (kDebugMode) {
        print('🔍 EquipmentApi - Récupération détail équipement: $code');
      }
      
      final data = await _apiService.get('/api/v1/equipments/$code');
      return Equipment.fromJson(data['equipment']);
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur getEquipmentDetail: $e');
      }
      rethrow;
    }
  }

  /// Synchronise les données de référence (zones, familles, entités)
  Future<ReferenceData> syncReferenceData() async {
    try {
      if (kDebugMode) {
        print('📊 EquipmentApi - Synchronisation données de référence...');
      }
      
      final data = await _apiService.get('/api/v1/equipments/reference/sync');
      return ReferenceData.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur syncReferenceData: $e');
      }
      rethrow;
    }
  }

  /// Ajoute un nouvel équipement
  Future<Equipment> addEquipment(Equipment equipment) async {
    try {
      if (kDebugMode) {
        print('➕ EquipmentApi - Ajout équipement: ${equipment.code}');
      }
      
      final data = await _apiService.post('/api/v1/equipments/', data: equipment.toJson());
      return Equipment.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur addEquipment: $e');
      }
      rethrow;
    }
  }

  /// Met à jour un équipement existant
  Future<Equipment> updateEquipment(String code, Map<String, dynamic> updatedFields) async {
    try {
      if (kDebugMode) {
        print('🔄 EquipmentApi - Mise à jour équipement: $code');
      }

      final data = await _apiService.patch('/api/v1/equipments/$code', data: updatedFields);
      return Equipment.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur updateEquipment: $e');
      }
      rethrow;
    }
  }

  /// Change l'URL de base (utile pour basculer entre environnements)
  void setBaseUrl(String url) {
    _apiService.setCustomBaseUrl(url);
  }

  /// Change le port (utile pour le développement)
  void setPort(int port) {
    _apiService.setPort(port);
  }

  /// Accès à l'instance ApiService si nécessaire
  ApiService get apiService => _apiService;
}
