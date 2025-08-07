import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class EquipmentApiService {
  late final ApiService _apiService;

  EquipmentApiService({ApiService? apiService}) {
    _apiService = apiService ?? ApiService(port: 8000);

    if (kDebugMode) {
      print(
        '🔧 EquipmentApiService configuré avec: ${_apiService.currentBaseUrl}',
      );
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

      final data = await _apiService.get(
        '/api/v1/equipments/',
        queryParameters: queryParams,
      );
      return ApiResponse.fromJson(
        data,
        nameItem: 'equipments',
        fromJson: (json) => Equipment.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur getEquipments: $e');
      }
      rethrow;
    }
  }

  /// Récupération des valeurs des sélecteurs pour les équipements
  Future<Map<String, dynamic>> getEquipmentSelectors({
    required String entity,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentApi - Récupération des sélecteurs pour entité: $entity',
        );
      }

      final data = await _apiService.get('/api/v1/equipments/values/$entity');

      if (kDebugMode) {
        print('📋 EquipmentApi - Données reçues: ${data['data']?.keys}');
      }
      for (var entity in data['data']['entities']) {
        if (kDebugMode) {
          print('📋 EquipmentApi - Entité: $entity');
        }
      }

      // ✅ Traiter les listes correctement et retourner le bon type
      final entities =
          (data['data']['entities'])
              .map((e) => Entity.fromJson(e));
      final unites =
          (data['data']['unites'])
              .map((e) => Unite.fromJson(e));
      final zones =
          (data['data']['zones'])
              .map((e) => Zone.fromJson(e));
      final familles =
          (data['data']['familles'])
              .map((e) => Famille.fromJson(e));
      final centreCharges =
          (data['data']['cost_charges'])
              .map((e) => CentreCharge.fromJson(e));
      final feeders =
          (data['data']['feeders'])
              .map((e) => Feeder.fromJson(e));

      // ✅ Retourner directement les objets typés (pas de mise en cache ici)
      final selectors = {
        'entities': entities,
        'unites': unites,
        'zones': zones,
        'familles': familles,
        'centreCharges': centreCharges,
        'feeders': feeders,
      };

      if (kDebugMode) {
        print(
          '✅ EquipmentApi - Sélecteurs traités: ${selectors.keys.join(', ')}',
        );
      }

      return selectors;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur getEquipmentSelectors: $e');
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

      final data = await _apiService.post(
        '/api/v1/equipments/',
        data: equipment.toJson(),
      );
      return Equipment.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur addEquipment: $e');
      }
      rethrow;
    }
  }

  /// Met à jour un équipement existant
  Future<Equipment> updateEquipment(
    String code,
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 EquipmentApi - Mise à jour équipement: $code');
      }

      final data = await _apiService.patch(
        '/api/v1/equipments/$code',
        data: updatedFields,
      );
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
