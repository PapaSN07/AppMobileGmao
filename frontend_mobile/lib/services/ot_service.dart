import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/cache_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Résultat d'un appel paginé à la liste des OT.
class OTPageResult {
  /// OT de cette page (filtrés selon le scope demandé).
  final List<WorkOrder> workorders;

  /// Token Coswin pour charger la page suivante (null si fin des données).
  final String? paginationContext;

  /// True s'il reste des pages disponibles côté Coswin.
  final bool hasMore;

  const OTPageResult({
    required this.workorders,
    required this.paginationContext,
    required this.hasMore,
  });
}

class OTService {
  final ApiService _apiService;
  final CacheService _cacheService = CacheService();

  // Configuration
  // Mettre a false pour utiliser l'API backend en temps reel.
  static const bool useMockData = false;
  // Endpoint backend FastAPI qui proxy vers Coswin OT.
  static const String ordersEndpoint = '/api/v1/mobile/ot/workorders';

  OTService(this._apiService);

  /// Vérifier la connectivité Internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Récupérer les détails d'un OT par son numéro
  Future<WorkOrder> getOTDetails(String otNumber) async {
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
      // Le backend renvoie un wrapper { success, data, message }.
      final payload = _extractDataPayload(response);
      final order = WorkOrder.fromJson(payload);

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

  /// Timeout étendu pour la récupération de liste d'OT.
  /// Chaque page Coswin prend ~9 secondes, on laisse 60s pour une page.
  static const Duration _listOrdersTimeout = Duration(seconds: 60);

  /// Récupère UNE PAGE d'OT filtrée selon le scope demandé.
  ///
  /// - scope='mine': OT du technicien connecté (wowoSupervisor=code).
  /// - scope='service': OT d'un service Coswin (wowoRequestEntity).
  /// - scope='all_open': tous les OT non clôturés.
  ///
  /// [paginationContext] : token renvoyé par la page précédente pour
  /// charger la page suivante (null = première page).
  ///
  /// Retourne un [OTPageResult] avec les OT, le token pour la page
  /// suivante, et un booléen [hasMore].
  Future<OTPageResult> getOrdersPage({
    String scope = 'mine',
    String? supervisorCode,
    String? requestEntity,
    bool excludeClosed = true,
    String? paginationContext,
  }) async {
    final hasInternet = await hasInternetConnection();

    if (!hasInternet) {
      // En mode hors-ligne, on renvoie le cache sans pagination.
      final cacheKey = _cacheKeyFor(scope, supervisorCode, requestEntity);
      final cachedOrders = await _cacheService.getCachedOrders(key: cacheKey);
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        // Dédoublonner par wowoCode pour nettoyer un historique de cache potentiellement pollué
        final seenCodes = <int>{};
        final uniqueOrders = <WorkOrder>[];
        for (final order in cachedOrders) {
          if (!seenCodes.contains(order.wowoCode)) {
            seenCodes.add(order.wowoCode);
            uniqueOrders.add(order);
          }
        }
        print('📱 ${uniqueOrders.length} OT uniques chargés depuis le cache ($cacheKey)');
        return OTPageResult(
          workorders: uniqueOrders,
          paginationContext: null,
          hasMore: false,
        );
      }
      throw Exception('Aucune connexion Internet et données non disponibles');
    }

    final Map<String, dynamic> queryParameters = {
      'scope': scope,
      'excludeClosed': excludeClosed,
    };

    if (scope == 'mine') {
      final code = supervisorCode ?? HiveService.getCurrentUser()?.code;
      if (code == null || code.isEmpty) {
        throw Exception(
          'Code agent introuvable pour l\'utilisateur connecté : '
          'impossible de filtrer "mes OT"',
        );
      }
      queryParameters['supervisorCode'] = code;
    } else if (scope == 'service') {
      if (requestEntity == null || requestEntity.isEmpty) {
        throw Exception('Code service requis (requestEntity) pour scope="service"');
      }
      queryParameters['requestEntity'] = requestEntity;
    }

    if (paginationContext != null) {
      queryParameters['paginationContext'] = paginationContext;
    }

    try {
      print('🌐 Chargement page OT: $ordersEndpoint?$queryParameters');
      final response = await _apiService.get(
        ordersEndpoint,
        queryParameters: queryParameters,
        timeout: _listOrdersTimeout,
      );
      final payload = _extractDataPayload(response);

      // Nouvelle structure : { workorders: [...], paginationContext: "...", hasMore: bool }
      if (payload is Map<String, dynamic> && payload.containsKey('workorders')) {
        final rawList = payload['workorders'] as List<dynamic>? ?? [];
        final orders = rawList.map((json) => WorkOrder.fromJson(json)).toList();
        
        // Dédoublonner par wowoCode pour éviter toute duplication visuelle sur l'UI
        final seenCodes = <int>{};
        final uniqueOrders = <WorkOrder>[];
        for (final order in orders) {
          if (!seenCodes.contains(order.wowoCode)) {
            seenCodes.add(order.wowoCode);
            uniqueOrders.add(order);
          }
        }

        final nextContext = payload['paginationContext'] as String?;
        final hasMore = payload['hasMore'] as bool? ?? false;

        // Met en cache la première page pour l'usage hors-ligne.
        if (paginationContext == null && uniqueOrders.isNotEmpty) {
          final cacheKey = _cacheKeyFor(scope, supervisorCode, requestEntity);
          await _cacheService.cacheOrders(uniqueOrders, key: cacheKey);
        }

        print('✅ ${uniqueOrders.length} OT uniques reçus, hasMore=$hasMore');
        return OTPageResult(
          workorders: uniqueOrders,
          paginationContext: nextContext,
          hasMore: hasMore,
        );
      }

      // Fallback : ancienne structure liste plate (compatibilité).
      if (payload is List) {
        final orders = payload.map((json) => WorkOrder.fromJson(json)).toList();
        final seenCodes = <int>{};
        final uniqueOrders = <WorkOrder>[];
        for (final order in orders) {
          if (!seenCodes.contains(order.wowoCode)) {
            seenCodes.add(order.wowoCode);
            uniqueOrders.add(order);
          }
        }
        return OTPageResult(workorders: uniqueOrders, paginationContext: null, hasMore: false);
      }

      throw Exception('Format de réponse OT inattendu');
    } catch (e) {
      print('❌ Erreur API: $e');
      final cacheKey = _cacheKeyFor(scope, supervisorCode, requestEntity);
      final cachedOrders = await _cacheService.getCachedOrders(key: cacheKey);
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        // Dédoublonner par wowoCode pour nettoyer un historique de cache potentiellement pollué
        final seenCodes = <int>{};
        final uniqueOrders = <WorkOrder>[];
        for (final order in cachedOrders) {
          if (!seenCodes.contains(order.wowoCode)) {
            seenCodes.add(order.wowoCode);
            uniqueOrders.add(order);
          }
        }
        print('📱 ${uniqueOrders.length} OT uniques depuis le cache (après erreur API)');
        return OTPageResult(
          workorders: uniqueOrders,
          paginationContext: null,
          hasMore: false,
        );
      }
      throw Exception('Erreur lors de la récupération des OT: $e');
    }
  }

  /// Raccourci rétrocompatible : récupère TOUTES les pages et les concatène.
  /// À n'utiliser que si vous avez besoin de la liste complète en une seule fois
  /// (ex: ot_info_details_screen). Préférez [getOrdersPage] pour l'affichage paginé.
  Future<List<WorkOrder>> getAllOrders({
    String scope = 'mine',
    String? supervisorCode,
    String? requestEntity,
    bool excludeClosed = true,
  }) async {
    final result = await getOrdersPage(
      scope: scope,
      supervisorCode: supervisorCode,
      requestEntity: requestEntity,
      excludeClosed: excludeClosed,
    );
    return result.workorders;
  }

  String _cacheKeyFor(
    String scope,
    String? supervisorCode,
    String? requestEntity,
  ) {
    switch (scope) {
      case 'mine':
        return 'mine_${supervisorCode ?? HiveService.getCurrentUser()?.code ?? ''}';
      case 'service':
        return 'service_${requestEntity ?? ''}';
      default:
        return 'all_open';
    }
  }

  /// Mettre à jour un OT
  Future<void> updateOT(int workOrderCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      throw Exception('Aucune connexion Internet pour mettre à jour l\'OT');
    }

    try {
      await _apiService.put('$ordersEndpoint/$workOrderCode', data: data);

      // Invalider le cache
      await _cacheService.clearCache();
      print('✅ OT mis à jour et cache effacé');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Créer un nouvel OT
  Future<WorkOrder> createOT(Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      throw Exception('Aucune connexion Internet pour créer l\'OT');
    }

    try {
      final response = await _apiService.post(ordersEndpoint, data: data);
      final payload = _extractDataPayload(response);
      final newOrder = WorkOrder.fromJson(payload);

      // Invalider le cache
      await _cacheService.clearCache();
      print('✅ OT créé et cache effacé');
      return newOrder;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'OT: $e');
    }
  }

  /// Supprimer un OT
  Future<void> deleteOT(int workOrderCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      throw Exception('Aucune connexion Internet pour supprimer l\'OT');
    }

    try {
      await _apiService.delete('$ordersEndpoint/$workOrderCode');

      // Invalider le cache
      await _cacheService.clearCache();
      print('✅ OT supprimé et cache effacé');
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'OT: $e');
    }
  }

  /// Effacer le cache manuellement
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Récupérer les opérations (mode opératoire) d'un OT
  Future<List<dynamic>> getOperations(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/operations');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getOperations: $e');
      return [];
    }
  }

  /// Récupérer la main d'œuvre affectée à un OT
  Future<List<dynamic>> getWorkforce(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/workforce');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getWorkforce: $e');
      return [];
    }
  }

  /// Récupérer les pièces de rechange d'un OT
  Future<List<dynamic>> getParts(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/parts');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getParts: $e');
      return [];
    }
  }

  /// Récupérer les services utilisés d'un OT (prestations de services / sous-traitance)
  Future<List<dynamic>> getServices(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/services');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getServices: $e');
      return [];
    }
  }

  /// Récupérer les commentaires/feedbacks d'un OT (employeefeedbacks Coswin)
  Future<List<dynamic>> getDocuments(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/documents');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getDocuments: $e');
      return [];
    }
  }

  /// Récupérer les sous-attributs d'un OT (attributes Coswin)
  Future<List<dynamic>> getAttributes(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/attributes');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getAttributes: $e');
      return [];
    }
  }

  /// Récupérer les moyens d'un OT (facilitiesused Coswin)
  Future<List<dynamic>> getMoyens(String otCode) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return [];
    try {
      final response = await _apiService.get('$ordersEndpoint/$otCode/facilitiesused');
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      print('❌ Erreur getMoyens: $e');
      return [];
    }
  }


  // ========== SUB-RESOURCES CRUD ==========
  Future<void> createOperation(String otCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.post('$ordersEndpoint/$otCode/operations', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur ajout opération: $e');
    }
  }

  Future<void> updateOperation(String otCode, int pk, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.put('$ordersEndpoint/$otCode/operations/$pk', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur modification opération: $e');
    }
  }

  Future<void> deleteOperation(String otCode, int pk) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.delete('$ordersEndpoint/$otCode/operations/$pk');
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur suppression opération: $e');
    }
  }

  Future<void> createDocument(String otCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.post('$ordersEndpoint/$otCode/documents', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur ajout commentaire: $e');
    }
  }

  Future<void> updateDocument(String otCode, int pk, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.put('$ordersEndpoint/$otCode/documents/$pk', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur modification commentaire: $e');
    }
  }

  Future<void> deleteDocument(String otCode, int pk) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.delete('$ordersEndpoint/$otCode/documents/$pk');
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur suppression commentaire: $e');
    }
  }

  Future<void> createWorkforce(String otCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.post('$ordersEndpoint/$otCode/workforce', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur ajout main d\'œuvre: $e');
    }
  }

  Future<void> updateWorkforce(String otCode, int pk, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.put('$ordersEndpoint/$otCode/workforce/$pk', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur modification main d\'œuvre: $e');
    }
  }

  Future<void> deleteWorkforce(String otCode, int pk) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.delete('$ordersEndpoint/$otCode/workforce/$pk');
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur suppression main d\'œuvre: $e');
    }
  }

  Future<void> createPart(String otCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.post('$ordersEndpoint/$otCode/parts', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur ajout article: $e');
    }
  }

  Future<void> updatePart(String otCode, int pk, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.put('$ordersEndpoint/$otCode/parts/$pk', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur modification article: $e');
    }
  }

  Future<void> deletePart(String otCode, int pk) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.delete('$ordersEndpoint/$otCode/parts/$pk');
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur suppression article: $e');
    }
  }

  Future<void> createAttribute(String otCode, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.post('$ordersEndpoint/$otCode/attributes', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur ajout attribut: $e');
    }
  }

  Future<void> updateAttribute(String otCode, int pk, Map<String, dynamic> data) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.put('$ordersEndpoint/$otCode/attributes/$pk', data: data);
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur modification attribut: $e');
    }
  }

  Future<void> deleteAttribute(String otCode, int pk) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Hors ligne : opération impossible');
    try {
      await _apiService.delete('$ordersEndpoint/$otCode/attributes/$pk');
      await _cacheService.clearCache();
    } catch (e) {
      throw Exception('Erreur suppression attribut: $e');
    }
  }

  dynamic _extractDataPayload(dynamic response) {
    // Accepte les reponses directes et les reponses enveloppees par le backend.
    if (response is Map<String, dynamic>) {
      // Si le backend renvoie une erreur (ex: 401), propager un message explicite.
      if (response.containsKey('detail') && response['detail'] != null) {
        throw Exception(response['detail'].toString());
      }

      // Certains services renvoient un message d'erreur via "message".
      if (response.containsKey('message') && !response.containsKey('data')) {
        throw Exception(response['message'].toString());
      }

      if (response.containsKey('data')) {
        return response['data'];
      }
    }

    return response;
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
}