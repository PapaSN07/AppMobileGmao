import 'package:appmobilegmao/models/centre_charge.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';
import 'package:appmobilegmao/models/famille.dart';
import 'package:appmobilegmao/models/feeder.dart';
import 'package:appmobilegmao/models/historique_equipment.dart';
import 'package:appmobilegmao/models/unite.dart';
import 'package:appmobilegmao/models/zone.dart';
import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class EquipmentService {
  late final ApiService _apiService;
  // Logging et constantes
  static const String __logName = 'EquipmentService -';
  static const String __prefixURI = '/api/v1/mobile/equipments';

  EquipmentService({ApiService? apiService}) {
    _apiService = apiService ?? ApiService();

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
        print('🔍 $__logName Requête équipements: $queryParams');
      }

      final data = await _apiService.get(
        __prefixURI,
        queryParameters: queryParams,
      );
      return ApiResponse.fromJson(
        data,
        nameItem: 'equipments',
        fromJson: (json) => Equipment.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur getEquipments: $e');
      }
      rethrow;
    }
  }

  /// ✅ Récupération des valeurs d'attributs avec gestion des erreurs
  Future<Map<String, dynamic>> getAttributeValuesEquipment({
    required String specification,
    required String attributeIndex,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 $__logName Récupération des valeurs pour un attribut: $specification, $attributeIndex',
        );
      }

      final data = await _apiService.get(
        '$__prefixURI/attributes?specification=$specification&attribute_index=$attributeIndex',
      );

      if (kDebugMode) {
        print(
          '📋 $__logName Données reçues: ${data['attr']?.length ?? 0} valeurs',
        );
      }

      // ✅ CORRIGÉ: Vérifier si data['attr'] existe et n'est pas null
      final attrData = data['attr'];

      if (attrData == null || attrData is! List) {
        if (kDebugMode) {
          print(
            '⚠️ $__logName Aucun attribut trouvé ou format invalide pour $specification/$attributeIndex',
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
              name: e['name']?.toString(), // Nom générique pour les valeurs
              value: e['value']?.toString(),
            );
          }).toList();

      final result = {
        'attributes': attributes,
        'message': data['message'] ?? 'Attributs récupérés avec succès',
      };

      if (kDebugMode) {
        print('✅ $__logName ${attributes.length} attributs traités');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur getAttributeValuesEquipment: $e');
      }

      // ✅ Retourner une structure cohérente même en cas d'erreur
      return {
        'attributes': <EquipmentAttribute>[],
        'message': 'Erreur lors de la récupération: $e',
        'error': true,
      };
    }
  }

  Future<Map<String, dynamic>> getEquipmentAttributeValueByCode({
    required String codeFamille,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔧 $__logName Récupération des valeurs pour un attribut: $codeFamille',
        );
      }

      final data = await _apiService.get(
        '$__prefixURI/attributes/by-code?codeFamille=$codeFamille',
      );

      if (kDebugMode) {
        print(
          '📋 $__logName Données reçues: ${data['attr']?.length ?? 0} valeurs',
        );
      }

      // ✅ CORRIGÉ: Vérifier si data['attr'] existe et n'est pas null
      final attrData = data['attr'];

      if (attrData == null || attrData is! List) {
        if (kDebugMode) {
          print(
            '⚠️ $__logName Aucun attribut trouvé ou format invalide pour $codeFamille',
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
              specification:
                  e['specification']?.toString(), // Ajouter la spécification
              index: e['index']?.toString(), // Ajouter l'index
              name: e['name']?.toString(), // Nom générique pour les valeurs
              value: e['value']?.toString(),
            );
          }).toList();

      final result = {
        'attributes': attributes,
        'message': data['message'] ?? 'Attributs récupérés avec succès',
      };

      if (kDebugMode) {
        print('✅ $__logName ${attributes.length} attributs traités');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur getAttributeValuesEquipment: $e');
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
        print('🔧 $__logName Récupération des sélecteurs pour entité: $entity');
      }

      final data = await _apiService.get('$__prefixURI/values/$entity');

      if (kDebugMode) {
        print('📋 $__logName Données reçues: ${data['data']?.keys}');
      }
      for (var entity in data['data']['entities']) {
        if (kDebugMode) {
          print('📋 $__logName Entité: $entity');
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
        print('✅ $__logName Sélecteurs traités: ${selectors.keys.join(', ')}');
      }

      return selectors;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur getEquipmentSelectors: $e');
      }
      rethrow;
    }
  }

  /// ✅ CORRIGÉ: Ajoute un nouvel équipement avec gestion de la redirection 307
  Future<Equipment> addEquipment(Equipment equipment) async {
    try {
      if (kDebugMode) {
        print('➕ $__logName Ajout équipement: ${equipment.code}');
      }

      // ✅ VALIDATION: Vérifier les champs obligatoires
      if (equipment.famille.isEmpty) {
        throw Exception('Famille équipement requise');
      }

      // ✅ IMPORTANT: Utiliser toJson() qui respecte les spécifications backend
      final equipmentData = equipment.toJson();

      if (kDebugMode) {
        print('📊 $__logName Données envoyées au backend:');
        print('   - Code: ${equipmentData['code']}');
        print('   - Famille: ${equipmentData['famille']}');
        print('   - Zone: ${equipmentData['zone']}');
        print('   - Entity: ${equipmentData['entity']}');
        print('   - Description: ${equipmentData['description']}');
        print('   - Unite: ${equipmentData['unite']}');
        print('   - Centre charge: ${equipmentData['centre_charge']}');
        print('   - Code parent: ${equipmentData['code_parent']}');
        print('   - Feeder: ${equipmentData['feeder']}');
        print(
          '   - Feeder description: ${equipmentData['feeder_description']}',
        );
        print('   - Longitude: ${equipmentData['longitude']}');
        print('   - Latitude: ${equipmentData['latitude']}');
        print('   - Created By: ${equipmentData['createdBy']}');
        if (equipmentData['attributs'] != null) {
          final attributs = equipmentData['attributs'] as List;
          print('   - Attributs: ${attributs.length} éléments');
          for (final attr in attributs) {
            print(
              '     • ${attr['name']}: "${attr['value']}" (${attr['type']} - ${attr['specification']}/${attr['index']})',
            );
          }
        }
      }

      final data = await _apiService.post(__prefixURI, data: equipmentData);

      if (kDebugMode) {
        print('✅ $__logName Réponse API: $data');
        print('✅ $__logName Type de réponse: ${data.runtimeType}');
      }

      // ✅ NOUVEAU: Gestion des différents types de réponse de l'API
      if (data is Map<String, dynamic>) {
        // ✅ Cas 1: L'API renvoie un objet JSON complet
        if (kDebugMode) {
          print('📋 $__logName API a renvoyé un objet JSON');
        }
        return Equipment(
          id: data['equipment_id'].toString(), // Utiliser la réponse comme ID
          code: equipment.code,
          description: equipment.description,
          famille: equipment.famille,
          zone: equipment.zone,
          entity: equipment.entity,
          unite: equipment.unite,
          centreCharge: equipment.centreCharge,
          codeParent: equipment.codeParent,
          feeder: equipment.feeder,
          feederDescription: equipment.feederDescription,
          longitude: equipment.longitude,
          latitude: equipment.latitude,
          attributes: equipment.attributes,
          cachedAt: DateTime.now(),
        );
      } else {
        // ✅ Cas 2: Type de réponse inattendu
        if (kDebugMode) {
          print('⚠️ $__logName Type de réponse inattendu: ${data.runtimeType}');
          print('⚠️ $__logName Contenu: $data');
        }

        // Créer un équipement avec un ID généré
        return Equipment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          code: equipment.code,
          description: equipment.description,
          famille: equipment.famille,
          zone: equipment.zone,
          entity: equipment.entity,
          unite: equipment.unite,
          centreCharge: equipment.centreCharge,
          codeParent: equipment.codeParent,
          feeder: equipment.feeder,
          feederDescription: equipment.feederDescription,
          longitude: equipment.longitude,
          latitude: equipment.latitude,
          attributes: equipment.attributes,
          cachedAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur addEquipment: $e');
      }
      rethrow;
    }
  }

  /// Met à jour un équipement existant avec ses attributs
  Future<Equipment> updateEquipment(
    int equipmentId,
    Map<String, dynamic> equipmentData,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 EquipmentService - Mise à jour équipement: $equipmentId');
        print('📊 EquipmentService - Données envoyées: $equipmentData');
      }

      final response = await _apiService.post(
        '/api/v1/mobile/equipments/$equipmentId',
        data: equipmentData,
      );

      // ✅ CORRECTION: Vérifier le type de réponse avant de traiter
      if (response == null) {
        throw ApiException('Réponse vide du serveur');
      }

      // ✅ Vérifier si la réponse est une String HTML au lieu d'un Map JSON
      if (response is String) {
        if (response.contains('<html>') ||
            response.contains('Request Rejected')) {
          throw ApiException(
            'La requête a été bloquée par le pare-feu du serveur',
            statusCode: 403,
          );
        }
        throw ApiException('Réponse invalide du serveur (format inattendu)');
      }

      // ✅ Vérifier si la réponse est bien un Map
      if (response is! Map<String, dynamic>) {
        throw ApiException(
          'Format de réponse invalide: ${response.runtimeType}',
        );
      }

      if (kDebugMode) {
        print('✅ EquipmentService - Équipement mis à jour avec succès');
      }

      final equipmentJson = response['equipment'];
      if (equipmentJson is Map<String, dynamic>) {
        return Equipment.fromJson(equipmentJson);
      }

      // Certains endpoints renvoient equipment: null même en succès.
      // On reconstruit localement l'objet pour maintenir le flux UI/provider.
        final rawAttributes =
          equipmentData['attributs'] is List
            ? (equipmentData['attributs'] as List)
            : const <dynamic>[];
        final sanitizedAttributes =
          rawAttributes
            .whereType<Map<String, dynamic>>()
            .map(EquipmentAttribute.fromJson)
            .toList();

      if (kDebugMode) {
        print('⚠️ EquipmentService - Réponse sans equipment, fallback local');
      }

      return Equipment(
        id: equipmentId.toString(),
        codeParent: equipmentData['code_parent']?.toString() ?? '',
        feeder: equipmentData['feeder']?.toString() ?? '',
        feederDescription: equipmentData['feeder_description']?.toString() ?? '',
        code: equipmentData['code']?.toString() ?? '',
        famille: equipmentData['famille']?.toString() ?? '',
        zone: equipmentData['zone']?.toString() ?? '',
        entity: equipmentData['entity']?.toString() ?? '',
        unite: equipmentData['unite']?.toString() ?? '',
        centreCharge: equipmentData['centre_charge']?.toString() ?? '',
        description: equipmentData['description']?.toString() ?? '',
        longitude: equipmentData['longitude']?.toString() ?? '',
        latitude: equipmentData['latitude']?.toString() ?? '',
        attributes: sanitizedAttributes,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ EquipmentService - Erreur updateEquipment: $e');
      }
      rethrow;
    }
  }

  /// Récupère l'historique des équipements créés par un prestataire
  Future<List<HistoriqueEquipment>> getHistoriqueEquipmentPrestataire({
    required String username,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 EquipmentService - Récupération historique pour: $username');
      }

      final response = await _apiService.get(
        '$__prefixURI/historique/$username',
      );

      if (response == null) {
        throw ApiException('Réponse vide du serveur');
      }

      if (response is! Map<String, dynamic>) {
        throw ApiException(
          'Format de réponse invalide: ${response.runtimeType}',
        );
      }

      final List<dynamic> data = response['historique'] ?? [];
      final historique =
          data.map((json) => HistoriqueEquipment.fromJson(json)).toList();

      if (kDebugMode) {
        print(
          '✅ EquipmentService - ${historique.length} équipements récupérés',
        );
      }

      return historique;
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ EquipmentService - Erreur getHistoriqueEquipmentPrestataire: $e',
        );
      }
      rethrow;
    }
  }

  /// Supprime un équipement par son ID ou son code
  Future<bool> deleteEquipment(String equipmentId) async {
    try {
      if (kDebugMode) {
        print('🗑️ $__logName Suppression équipement: $equipmentId');
      }
      final response = await _apiService.delete('$__prefixURI/$equipmentId');
      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $__logName Erreur deleteEquipment: $e');
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
