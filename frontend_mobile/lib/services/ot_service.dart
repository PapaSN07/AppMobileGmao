import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/cache_service.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OTService {
  final ApiService _apiService;
  final CacheService _cacheService = CacheService();

  // Configuration
  static const bool useMockData = true; // Mettre à true pour tester sans API
  static const String ordersEndpoint = '/ws/rest/api/orders';

  OTService(this._apiService);

  /// Vérifier la connectivité Internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Récupérer les détails d'un OT par son numéro
  Future<WorkOrder> getOTDetails(String otNumber) async {
    // MODE TEST - DONNÉES MOCKÉES
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return _getMockOrderDetails();
    }

    // MODE RÉEL AVEC CACHE
    final hasInternet = await hasInternetConnection();

    if (!hasInternet) {
      final cachedOrder = await _cacheService.getCachedOrderDetails(otNumber);
      if (cachedOrder != null) {
        print('📱 Chargement depuis le cache');
        return cachedOrder;
      }
      throw Exception(
        'Aucune connexion Internet et données non disponibles en cache',
      );
    }

    try {
      print('🌐 Chargement depuis l\'API: $ordersEndpoint/$otNumber');
      final response = await _apiService.get('$ordersEndpoint/$otNumber');
      final order = WorkOrder.fromJson(response);

      await _cacheService.cacheOrderDetails(otNumber, order);
      print('✅ OT $otNumber sauvegardé en cache');

      return order;
    } catch (e) {
      print('❌ Erreur API: $e');
      final cachedOrder = await _cacheService.getCachedOrderDetails(otNumber);
      if (cachedOrder != null) {
        print('📱 Chargement depuis le cache (après erreur API)');
        return cachedOrder;
      }
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  /// Récupérer tous les OT
  Future<List<WorkOrder>> getAllOrders() async {
    // MODE TEST
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return [_getMockOrderDetails()];
    }

    // MODE RÉEL
    final hasInternet = await hasInternetConnection();

    if (!hasInternet) {
      final cachedOrders = await _cacheService.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print('📱 ${cachedOrders.length} OT chargés depuis le cache');
        return cachedOrders;
      }
      throw Exception('Aucune connexion Internet et données non disponibles');
    }

    try {
      print('🌐 Chargement depuis l\'API: $ordersEndpoint');
      final response = await _apiService.get(ordersEndpoint);

      List<WorkOrder> orders;
      if (response is List) {
        orders = response.map((json) => WorkOrder.fromJson(json)).toList();
      } else if (response is Map && response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        orders = data.map((json) => WorkOrder.fromJson(json)).toList();
      } else {
        throw Exception('Format de réponse inattendu');
      }

      await _cacheService.cacheOrders(orders);
      print('✅ ${orders.length} OT sauvegardés en cache');

      return orders;
    } catch (e) {
      print('❌ Erreur API: $e');
      final cachedOrders = await _cacheService.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        print(
          '📱 ${cachedOrders.length} OT chargés depuis le cache (après erreur API)',
        );
        return cachedOrders;
      }
      throw Exception('Erreur lors de la récupération des OT: $e');
    }
  }

  /// Mettre à jour un OT
  Future<void> updateOT(int pkWorkOrder, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      throw Exception('Aucune connexion Internet pour mettre à jour l\'OT');
    }

    try {
      await _apiService.put('$ordersEndpoint/$pkWorkOrder', data: data);

      // Invalider le cache
      await _cacheService.clearCache();
      print('✅ OT mis à jour et cache effacé');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Effacer le cache manuellement
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Obtenir l'état du cache
  Future<Map<String, dynamic>> getCacheStatus() async {
    final lastSync = await _cacheService.getLastSyncTime();
    final cachedOrders = await _cacheService.getCachedOrders();

    return {
      'lastSync': lastSync,
      'cachedOrdersCount': cachedOrders?.length ?? 0,
      'hasCache': cachedOrders != null && cachedOrders.isNotEmpty,
    };
  }

  /// Données mockées pour tester sans API
  WorkOrder _getMockOrderDetails() {
    return WorkOrder.fromJson({
      "pkWorkOrder": 248095,
      "wowoCode": 2025246533,
      "wowoUserStatus": "CR",
      "wowoEquipment": "LM0805PAMK5TUR1",
      "wowoJob": "REMP_FUS-BT+REMP_COS",
      "wowoJobType": "CORR",
      "wowoJobClass": "POSTE",
      "wowoPriority": null,
      "wowoActionEntity": "SDPG",
      "wowoRequestEntity": "SDPG",
      "wowoScheduleDate": "2025-11-11T00:00:00.000Z",
      "wowoSupervisor": "5286",
      "wowoCostcentre": "DD304",
      "wowoTargetDate": "2025-11-11T00:00:00.000Z",
      "wowoStartDate": null,
      "wowoEndDate": null,
      "wowoJobRequest": "DI00054258",
      "wowoZone": "DAKAR",
      "wowoFunction": "UMP-PG",
      "wowoFeedbackNote": "Poste sale, poussiéreux et mal éclairée",
      "wowoEquipmentDescription": "POSTE PA MALIKA 5 - TABLEAU BT 1",
      "wowoActionEntityDescription":
          "SERVICE DE DISTRIBUTION PIKINE GUEDIAWAYE",
      "wowoCostcentreDescription": "Service Distribution Pikine Guédiawaye",
      "wowoJobClassDescription": "TRAVAUX SUR LES EQUIPEMENTS DU POSTE HTA/BT",
      "wowoJobTypeDescription": "CORRECTIF",
      "wowoSupervisorDescription": "ERIC DASYLVA CARDOZO",
      "mdjbDescription": "REMPLACEMENT FUSIBLE BT ET REMPLACEMENT COSSE",
      "wowoString1": "7318",
      "wowoString2": "523",
      "wowoString4": "SENELEC",
      "mdusDescription": "CREE",
    });
  }
}
