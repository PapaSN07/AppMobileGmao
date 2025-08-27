import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class EquipmentService {
  late final ApiService _apiService;

  EquipmentService({ApiService? apiService}) {
    _apiService = apiService ?? ApiService(port: 8000);

    if (kDebugMode) {
      print(
        '🔧 EquipmentService configuré avec: ${_apiService.currentBaseUrl}',
      );
    }
  }

  /// Accès à l'instance ApiService si nécessaire
  ApiService get apiService => _apiService;

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

  /// ✅ CORRIGÉ: Récupération des valeurs d'attributs avec gestion des erreurs
  Future<Map<String, dynamic>> getAttributeValuesEquipment({
    required String specification,
    required String attributeIndex,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 EquipmentApi - Récupération des valeurs pour un attribut: $specification, $attributeIndex',
        );
      }

      final data = await _apiService.get(
        '/api/v1/equipments/attributes?specification=$specification&attribute_index=$attributeIndex',
      );

      if (kDebugMode) {
        print(
          '📋 EquipmentApi - Données reçues: ${data['attr']?.length ?? 0} valeurs',
        );
      }

      // ✅ CORRIGÉ: Vérifier si data['attr'] existe et n'est pas null
      final attrData = data['attr'];

      if (attrData == null || attrData is! List) {
        if (kDebugMode) {
          print(
            '⚠️ EquipmentApi - Aucun attribut trouvé ou format invalide pour $specification/$attributeIndex',
          );
        }

        // Retourner une liste vide au lieu d'une erreur
        return {
          'attributes': <EquipmentAttribute>[],
          'message': data['detail'] ?? 'Aucun attribut trouvé',
        };
      }

      // ✅ Traiter les attributs uniquement s'ils existent
      final attributes =
          (attrData).map((e) {
            // Convertir les données API vers EquipmentAttribute
            return EquipmentAttribute(
              id: e['id']?.toString(),
              specification: specification, // Ajouter la spécification
              index: attributeIndex, // Ajouter l'index
              name: 'Valeur ${e['id']}', // Nom générique pour les valeurs
              value: e['value']?.toString(),
            );
          }).toList();

      final result = {
        'attributes': attributes,
        'message': data['message'] ?? 'Attributs récupérés avec succès',
      };

      if (kDebugMode) {
        print('✅ EquipmentApi - ${attributes.length} attributs traités');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentApi - Erreur getAttributeValuesEquipment: $e');
      }

      // ✅ Retourner une structure cohérente même en cas d'erreur
      return {
        'attributes': <EquipmentAttribute>[],
        'message': 'Erreur lors de la récupération: $e',
        'error': true,
      };
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
          (data['data']['entities'] as List)
              .map((e) => Entity.fromJson(e))
              .toList();
      final unites =
          (data['data']['unites'] as List)
              .map((e) => Unite.fromJson(e))
              .toList();
      final zones =
          (data['data']['zones'] as List).map((e) => Zone.fromJson(e)).toList();
      final familles =
          (data['data']['familles'] as List)
              .map((e) => Famille.fromJson(e))
              .toList();
      final centreCharges =
          (data['data']['cost_charges'] as List)
              .map((e) => CentreCharge.fromJson(e))
              .toList();
      final feeders =
          (data['data']['feeders'] as List)
              .map((e) => Feeder.fromJson(e))
              .toList();

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
}
