import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/cache_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/ot_payload_rules.dart';
import 'package:appmobilegmao/services/coswin_referential_service.dart';
import 'package:appmobilegmao/services/coswin_action_service.dart';
import 'package:appmobilegmao/services/ot_code_locator.dart';
import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/models/ot_status.dart';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Résultat d'un appel paginé à la liste des OT.
class OTPageResult {
  /// OT de cette page (filtrés selon le scope demandé), du plus récent au plus ancien.
  final List<WorkOrder> workorders;

  /// Plus petit code couvert par cette page : la page suivante commence juste en dessous.
  final int? lastCode;

  /// True s'il reste des OT plus anciens dans l'année [targetYear].
  final bool hasMore;

  /// Année ciblée par cette requête (ex: 2026, 2025).
  final int targetYear;

  const OTPageResult({
    required this.workorders,
    this.lastCode,
    required this.hasMore,
    this.targetYear = 2026,
  });
}

/// Balises des comptes-rendus Coswin utilisés pour stocker les sous-ressources
/// que l'API REST Coswin ne permet pas d'écrire directement.
enum FeedbackTag {
  part('[MATÉRIEL UTILISÉ]', '[MAT'),
  attribute('[ATTRIBUT TECHNIQUE]', '[ATT'),
  facility('[MOYEN UTILISÉ]', '[MOYEN'),
  service('[SERVICE UTILISÉ]', '[SERVICE');

  const FeedbackTag(this.label, this.prefix);

  final String label;
  final String prefix;

  bool matches(String text) => text.startsWith(prefix) || text.contains(label);

  static bool isTagged(String text) => values.any((t) => t.matches(text));
}

/// Entrée du cache mémoire d'un OT brut Coswin.
class _RawEntry {
  final Future<Map<String, dynamic>?> future;
  final DateTime fetchedAt;
  _RawEntry(this.future) : fetchedAt = DateTime.now();
}

class OTService {
  final ApiService _apiService;
  final CacheService _cacheService = CacheService();
  final CoswinReferentialService _referentials;
  final CoswinActionService _actions;
  late final OTCodeLocator _codeLocator = OTCodeLocator(_probeCodes);

  OTService(this._apiService, {CoswinReferentialService? referentials, CoswinActionService? actions})
      : _referentials = referentials ?? CoswinReferentialService(_apiService),
        _actions = actions ?? CoswinActionService(_apiService);

  /// Timeout étendu pour la récupération de liste d'OT.
  static const Duration _listOrdersTimeout = Duration(seconds: 60);

  /// Durée pendant laquelle un OT brut est partagé entre les onglets du détail.
  static const Duration _rawCacheTtl = Duration(seconds: 30);

  /// Taille d'une fenêtre de codes OT : Coswin renvoie au plus 50 OT par appel,
  /// et les codes étant séquentiels, 50 codes tiennent en un seul appel.
  static const int _windowSize = 50;

  /// Clé de la liste d'OT dans les réponses Coswin `/workorders`.
  static const String _workorderListKey = 'workorderfind';

  /// Un seul appel réseau par OT, partagé par getOperations/getParts/getDocuments...
  final Map<String, _RawEntry> _rawCache = {};

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // ========== RÉFÉRENTIELS ==========

  /// Référentiels officiels Coswin (types, classes, priorités, statuts, superviseurs).
  Future<OTReferentials> getReferentials() => _referentials.load();

  /// Nombre minimal de caractères pour interroger Coswin.
  static const int minSearchLength = 2;

  /// Recherche Coswin par code (« contient »). Coswin ne sait pas chercher dans
  /// les descriptions : seule la recherche par code est possible.
  Future<List<Map<String, dynamic>>> _searchByCode(String path, String query) async {
    final q = query.trim();
    if (q.length < minSearchLength) return const [];
    final response = await _apiService.getCoswin(path, queryParameters: {
      'usePagination': 'true',
      'filterOperator': 'contains',
      'filterOperand1': q,
    });
    if (response is Map && response['list'] is Map) {
      for (final value in (response['list'] as Map).values) {
        if (value is List) return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  /// Articles du stock Coswin dont le code contient [query] (53 000+ articles : pas de liste complète).
  Future<List<StockItem>> searchItems(String query) async {
    final rows = await _searchByCode('/items', query);
    return rows
        .map((r) => StockItem(
              r['sritCode']?.toString().trim() ?? '',
              r['sritDescription']?.toString().trim() ?? '',
              unit: r['sritStockUnit']?.toString().trim() ?? '',
            ))
        .where((i) => i.code.isNotEmpty)
        .toList();
  }

  /// Compteurs Coswin dont le code contient [query].
  Future<List<RefItem>> searchMeters(String query) async {
    final rows = await _searchByCode('/meters', query);
    return rows
        .map((r) => RefItem(
              r['mdmtCode']?.toString().trim() ?? '',
              r['mdmtDescription']?.toString().trim() ?? '',
              entity: r['mdmtEntity']?.toString().trim() ?? '',
            ))
        .where((m) => m.code.isNotEmpty)
        .toList();
  }

  /// Actions Coswin (étapes du mode opératoire). Le premier chargement prend plusieurs minutes.
  Future<List<RefItem>> getActions() => _actions.load();

  /// Nombre d'actions déjà reçues pendant le premier chargement (affichage de la progression).
  ValueListenable<int> get actionsLoadedCount => _actions.loadedCount;

  /// Récupérer les spécifications techniques officielles Coswin Senelec (100% direct Coswin, 0 mock)
  Future<List<dynamic>> getSpecifications() async {
    try {
      final response = await _apiService.getCoswin('/specifications');
      if (response is Map<String, dynamic>) {
        final findList = response['specificationFindList'];
        if (findList is Map && findList['specificationRow'] is List) {
          final rows = findList['specificationRow'] as List;
          final formatted = <Map<String, dynamic>>[];
          final seenKeys = <String>{};

          for (final r in rows) {
            if (r is! Map) continue;
            final code = (r['cwspCode'] ?? '').toString().trim();
            final idx = r['cwspIndex'] ?? 1;
            final unit = (r['cwspUnit'] ?? '').toString().trim();
            final authVal = (r['cwspAuthorizedValue'] ?? '').toString().trim();
            final valType = r['cwspValueType'] ?? 0;

            final key = authVal.isNotEmpty ? '${code}_${idx}_$authVal' : '${code}_$idx';
            if (!seenKeys.add(key)) continue;

            String desc = authVal.isNotEmpty
                ? '$authVal (Classe $code)'
                : 'Caractéristique $code #$idx';
            if (unit.isNotEmpty) {
              desc += ' [$unit]';
            }

            formatted.add({
              'code': authVal.isNotEmpty ? authVal : 'SPEC_$code#$idx',
              'index': idx,
              'name': desc,
              'description': desc,
              'unit': unit,
              'classCode': code,
              'valueType': valType,
              'authorizedValue': authVal,
            });
          }
          return formatted;
        }
      }
      return [];
    } catch (e) {
      _log('⚠️ Impossible de charger les spécifications Coswin: $e');
      return [];
    }
  }

  /// Vérifier la connectivité Internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      return true;
    }
    final base = _apiService.currentBaseUrl;
    return base.contains('127.0.0.1') ||
        base.contains('10.0.2.2') ||
        base.contains('localhost') ||
        base.contains('192.168.');
  }

  // ========== LECTURE OT ==========

  /// Extrait `response.list.workorderfind` (ou `response.workorders`) d'une réponse Coswin.
  List<dynamic> _extractWorkOrderList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final list = response['list'];
      if (list is Map && list[_workorderListKey] is List) {
        return list[_workorderListKey] as List<dynamic>;
      }
      if (response['workorders'] is List) {
        return response['workorders'] as List<dynamic>;
      }
    }
    return const [];
  }

  static int? _parseCode(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  Future<Map<String, dynamic>?> _fetchRawWorkOrder(String otCode) async {
    final response = await _apiService.getCoswin(
      '/workorders',
      queryParameters: {
        'filterColumn': 'wowoCode',
        'filterOperator': 'equals',
        'filterOperand1': otCode,
      },
    );
    final list = _extractWorkOrderList(response);
    return list.isNotEmpty ? list.first as Map<String, dynamic> : null;
  }

  /// OT brut Coswin, partagé pendant [_rawCacheTtl] entre tous les appelants.
  /// Les erreurs ne sont pas mises en cache.
  Future<Map<String, dynamic>?> _rawWorkOrder(String otCode) {
    final cached = _rawCache[otCode];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < _rawCacheTtl) {
      return cached.future;
    }
    final future = _fetchRawWorkOrder(otCode);
    _rawCache[otCode] = _RawEntry(future);
    future.catchError((_) {
      _rawCache.remove(otCode);
      return null;
    });
    return future;
  }

  void _invalidateRaw(String? otCode) {
    if (otCode == null) {
      _rawCache.clear();
    } else {
      _rawCache.remove(otCode);
    }
  }

  /// Version tolérante pour les onglets : un OT illisible donne des listes vides.
  Future<Map<String, dynamic>> _getRawWorkOrder(String otCode) async {
    try {
      return await _rawWorkOrder(otCode) ?? {};
    } catch (e) {
      _log('⚠️ Erreur lecture OT brut $otCode: $e');
      return {};
    }
  }

  /// Récupérer les détails d'un OT par son numéro (100% Direct Réseau Coswin)
  Future<WorkOrder> getOTDetails(String otNumber) async {
    try {
      _log('🌐 Chargement direct depuis Coswin: /workorders (code=$otNumber)');
      final raw = await _rawWorkOrder(otNumber);
      if (raw != null) return WorkOrder.fromJson(raw);

      // Fallback appel direct par ID
      final directResp = await _apiService.getCoswin('/workorders/$otNumber');
      if (directResp is Map<String, dynamic>) {
        return WorkOrder.fromJson(directResp);
      }

      throw Exception('OT $otNumber introuvable dans Coswin');
    } catch (e) {
      _log('❌ Erreur API getOTDetails: $e');
      rethrow;
    }
  }

  /// Sonde Coswin entre deux codes (premier lot, ordre croissant).
  Future<CodeProbe> _probeCodes(int from, int to) async {
    final response = await _apiService.getCoswin(
      '/workorders',
      queryParameters: _betweenQuery(from, to),
      timeout: _listOrdersTimeout,
    );
    final codes = _extractWorkOrderList(response)
        .whereType<Map<String, dynamic>>()
        .map((row) => _parseCode(row['wowoCode']))
        .whereType<int>()
        .toList();
    final hasMore = response is Map<String, dynamic> && response['moreDataAvailable'] == true;
    return CodeProbe(codes, hasMore);
  }

  static Map<String, dynamic> _betweenQuery(int from, int to) => {
        'usePagination': 'true',
        'filterOperator': 'between',
        'filterOperand1': '$from',
        'filterOperand2': '$to',
      };

  /// Récupère UNE PAGE d'OT, du plus récent au plus ancien.
  ///
  /// Coswin ne sait ni trier ni filtrer par colonne : on lit une fenêtre de
  /// [_windowSize] codes consécutifs se terminant à [upToCode] (par défaut
  /// l'OT le plus récent de [targetYear]), puis on filtre sur l'appareil.
  ///
  /// - scope='mine': OT du technicien connecté (wowoSupervisor).
  /// - scope='service': OT d'un service Coswin (wowoRequestEntity/ActionEntity).
  /// - scope='all_open': tous les OT.
  Future<OTPageResult> getOrdersPage({
    String scope = 'mine',
    String? supervisorCode,
    String? requestEntity,
    bool excludeClosed = true,
    int? upToCode,
    int? targetYear,
  }) async {
    final year = targetYear ?? DateTime.now().year;

    String? supervisor;
    if (scope == 'mine') {
      supervisor = supervisorCode ?? HiveService.getCurrentUser()?.code;
      if (supervisor == null || supervisor.isEmpty) {
        throw Exception(
          'Code agent introuvable pour l\'utilisateur connecté : '
          'impossible de filtrer "mes OT"',
        );
      }
    }

    try {
      // Les statuts réels (fermé / ouvert) viennent du référentiel Coswin.
      await _referentials.load();

      final first = await _codeLocator.firstCode(year);
      final hi = upToCode ?? await _codeLocator.latestCode(year);
      if (first == null || hi == null || hi < first) {
        return OTPageResult(workorders: const [], hasMore: false, targetYear: year);
      }
      final lo = max(first, hi - _windowSize + 1);

      _log('🌐 Coswin /workorders [$lo → $hi] (année $year)');
      final response = await _apiService.getCoswin(
        '/workorders',
        queryParameters: _betweenQuery(lo, hi),
        timeout: _listOrdersTimeout,
      );

      final reqUpper = (requestEntity ?? '').toUpperCase().trim();
      final filterByService = scope == 'service' && reqUpper.isNotEmpty;

      final seenCodes = <int>{};
      final orders = _extractWorkOrderList(response)
          .whereType<Map<String, dynamic>>()
          .map(WorkOrder.fromJson)
          .where((o) => supervisor == null || (o.wowoSupervisor ?? '').trim() == supervisor)
          .where((o) =>
              !filterByService ||
              o.wowoRequestEntity.toUpperCase().contains(reqUpper) ||
              o.wowoActionEntity.toUpperCase().contains(reqUpper))
          .where((o) => !excludeClosed || !OTStatus.isClosed(o.wowoUserStatus))
          .where((o) => seenCodes.add(o.wowoCode))
          .toList()
        ..sort((a, b) => b.wowoCode.compareTo(a.wowoCode));

      _log('✅ ${orders.length} OT retenus sur [$lo → $hi]');
      return OTPageResult(
        workorders: orders,
        lastCode: lo,
        hasMore: lo > first,
        targetYear: year,
      );
    } catch (e) {
      _log('❌ Erreur API getOrdersPage: $e');
      rethrow;
    }
  }

  /// Raccourci : récupère la liste d'OT.
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

  // ========== ÉCRITURE : SOCLE COMMUN ==========

  /// Exécute une écriture Coswin : vérifie la connexion, invalide les caches
  /// en cas de succès et journalise le résultat.
  ///
  /// [action] complète les messages ("créer l'opération", "supprimer l'OT"...).
  /// [errorPrefix], si fourni, encapsule l'erreur dans un message métier.
  Future<T> _mutate<T>(
    String action,
    Future<T> Function() call, {
    String? otCode,
    String? errorPrefix,
  }) async {
    if (!await hasInternetConnection()) {
      throw Exception('Aucune connexion Internet pour $action');
    }
    try {
      final result = await call();
      await _cacheService.clearCache();
      _invalidateRaw(otCode);
      _log('✅ Coswin : $action${otCode != null ? ' (OT $otCode)' : ''} réussi');
      return result;
    } catch (e) {
      _log('❌ Coswin : échec pour $action : $e');
      if (errorPrefix != null) throw Exception('$errorPrefix: $e');
      rethrow;
    }
  }

  /// Suppression que l'API Coswin ne propose pas : on échoue explicitement
  /// plutôt que de laisser croire à l'utilisateur que l'élément a disparu.
  Never _notDeletable(String what) {
    throw UnsupportedError("Coswin ne permet pas de supprimer $what depuis l'application.");
  }

  // ========== ÉCRITURE : OT ==========

  /// Mettre à jour un OT dans Coswin (`PUT /workorders/{code}/update0`).
  ///
  /// Le statut est transmis à part, uniquement s'il a changé. `wowoJob`, la zone
  /// et l'entité demandeuse ne sont pas modifiables par l'API Coswin.
  Future<void> updateOT(int workOrderCode, Map<String, dynamic> data) {
    final code = '$workOrderCode';
    final path = '/workorders/$code/update0';

    return _mutate('mettre à jour l\'OT', otCode: code, () async {
      final payload = OTPayloadRules.forUpdate(data, await _referentials.load());
      final current = OTStatus.normalize((await _rawWorkOrder(code))?['wowoUserStatus']?.toString());
      final wanted = payload['wowoUserStatus']?.toString();
      final newStatus = wanted != null && wanted != current ? wanted : null;

      try {
        await _apiService.putCoswin(path, data: OTPayloadRules.update0Body(payload, newStatus: newStatus));
      } catch (e) {
        // Repli : Coswin a rejeté un champ référentiel → nouvelle tentative sans ce champ.
        final fallback = OTPayloadRules.withoutRejectedFields(payload, e);
        if (fallback == null) rethrow;
        _log('⚠️ Coswin a rejeté un champ référentiel. Nouvelle tentative allégée: $fallback');
        final retryStatus = fallback.containsKey('wowoUserStatus') ? newStatus : null;
        await _apiService.putCoswin(path, data: OTPayloadRules.update0Body(fallback, newStatus: retryStatus));
      }
    });
  }

  /// Créer un nouvel OT dans Coswin (`POST /workorders/createSimple0`).
  Future<WorkOrder> createOT(Map<String, dynamic> data) {
    return _mutate(
      'créer l\'OT',
      errorPrefix: 'Erreur lors de la création de l\'OT dans Coswin',
      () async {
        final otPayload = OTPayloadRules.forCreate(data, await _referentials.load());
        final response = await _apiService.postCoswin(
          '/workorders/createSimple0',
          data: OTPayloadRules.createSimple0Body(otPayload),
        );
        // Coswin ne renvoie que le code du nouvel OT : on relit l'OT complet.
        final newCode = response is Map ? _parseCode(response['wowoCode']) : null;
        if (newCode == null) throw Exception('Coswin n\'a pas renvoyé le code du nouvel OT');
        return getOTDetails('$newCode');
      },
    );
  }

  /// Coswin ne propose pas de suppression d'OT par l'API REST.
  Future<void> deleteOT(int workOrderCode) async => _notDeletable('un OT');

  /// Effacer le cache manuellement
  Future<void> clearCache() async {
    _invalidateRaw(null);
    await _cacheService.clearCache();
  }

  // ========== SOUS-RESSOURCES : LECTURE ==========

  static List<dynamic> _section(Map<String, dynamic> raw, String key) =>
      (raw[key] as List?) ?? const [];

  static String _feedbackText(dynamic fb) => (fb['woefLongString1'] ?? '').toString().trim();

  static dynamic _feedbackPk(dynamic fb) => fb['pkEmployeeFeedback'] ?? fb['pkDocument'] ?? 0;

  /// Comptes-rendus de l'OT portant la balise [tag].
  static Iterable<dynamic> _taggedFeedbacks(Map<String, dynamic> raw, FeedbackTag tag) =>
      _section(raw, 'employeeFeedbackViewworkorderfind')
          .where((fb) => tag.matches(_feedbackText(fb)));

  /// Valeur après `key:` dans un segment "key: valeur | key2: valeur2".
  static String? _segmentValue(String text, String key) {
    for (final segment in text.split('|')) {
      final s = segment.trim();
      final idx = s.indexOf(key);
      if (idx >= 0) return s.substring(idx + key.length).trim();
    }
    return null;
  }

  /// Récupérer les opérations (mode opératoire) d'un OT
  Future<List<dynamic>> getOperations(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    return _section(raw, 'workActionViewworkorderfind').map((act) {
      final code = act['wowaAction'] ?? act['operationCode'] ?? 'ACTION';
      final desc = act['mdatDescription'] ?? act['opopDescription'] ?? act['opopJobDescription'] ?? code;
      final pk = act['pkWorkAction'] ?? act['pkOperation'] ?? 0;
      final duration = act['wowaDuration'] ?? act['duration'] ?? 1.0;
      return {
        'pkOperation': pk,
        'pkWorkAction': pk,
        'wowaAction': code,
        'operationCode': code,
        'mdatDescription': desc,
        'opopDescription': desc,
        'opopJobDescription': desc,
        'duration': duration,
      };
    }).toList();
  }

  /// Récupérer la main d'œuvre affectée à un OT
  Future<List<dynamic>> getWorkforce(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    return _section(raw, 'employeeAllocatedViewworkorderfind').map((emp) {
      final pk = emp['pkEmployeeAllocated'] ?? emp['pkWorkforce'] ?? 0;
      final empCode = emp['reemCode'] ?? emp['woeaEmployee'] ?? '';
      final empName = emp['reemDescription'] ?? emp['woeaResource'] ?? 'Intervenant';
      final resource = emp['woeaResource'] ?? 'RDEF';
      return {
        'pkEmployeeAllocated': pk,
        'pkWorkforce': pk,
        'woeaEmployee': empCode,
        'reemCode': empCode,
        'reemDescription': empName,
        'woeaResource': resource,
        'woeaPlannedHours': emp['woeaPlannedHours'] ?? 0.0,
        'woeaAllocationDate': emp['woeaAllocationDate'],
        'woeaScheduleDate': emp['woeaScheduleDate'],
      };
    }).toList();
  }

  static Map<String, dynamic> _partRow(dynamic pk, String partCode, String desc, dynamic qty, [dynamic plannedQty]) => {
        'pkStockUsed': pk,
        'pkPart': pk,
        'wosyPart': partCode,
        'wosyCode': partCode,
        'stockPart': partCode,
        'wosyDescription': desc,
        'partDescription': desc,
        'article': desc,
        'wosyUsedQuantity': qty,
        'wosyQuantity': qty,
        'quantiteUtilise': qty.toString(),
        if (plannedQty != null) 'wospQtyPlanned': plannedQty,
      };

  /// Récupérer les pièces de rechange d'un OT
  Future<List<dynamic>> getParts(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    final parts = _section(raw, 'stockUsedViewworkorderfind').map((s) {
      final pk = s['pkStockUsed'] ?? s['pkPart'] ?? 0;
      final partCode = s['wosuSpare'] ?? s['wosyPart'] ?? s['wosyItem'] ?? '';
      final desc = s['wosuDescription'] ?? s['wosyDescription'] ?? partCode;
      final qty = s['wosuActualQuantity'] ?? s['wosuPlannedQuantity'] ?? s['wosyUsedQuantity'] ?? 1.0;
      return _partRow(pk, partCode, desc, qty);
    }).toList();

    // Pièces enregistrées via comptes-rendus tagués : "Article: CODE - desc | Qté: 2"
    for (final fb in _taggedFeedbacks(raw, FeedbackTag.part)) {
      final txt = _feedbackText(fb);
      final article = _segmentValue(txt, 'Article:');
      final artDesc = article ?? txt;
      final partCode = article != null ? _codeBeforeDash(article) : 'ARTICLE';
      final qty = double.tryParse(_segmentValue(txt, 'Qté:') ?? '') ?? 1.0;
      final planned = double.tryParse(_segmentValue(txt, 'Qté planifiée:') ?? '');
      parts.add(_partRow(_feedbackPk(fb), partCode, artDesc, qty, planned));
    }
    return parts;
  }

  /// Récupérer les services utilisés d'un OT
  Future<List<dynamic>> getServices(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    // Coswin n'a pas de services dans son API (free2 est une table libre sans rapport) :
    // seuls les services notés par l'application sont relus.
    final services = <dynamic>[];

    // "Service: CODE - desc | Qté planifiée: 2 | Qté consommée: 1 | Unité: U | Coût: … | Type: … | …"
    for (final fb in _taggedFeedbacks(raw, FeedbackTag.service)) {
      final txt = _feedbackText(fb);
      final label = _segmentValue(txt, 'Service:') ?? txt;
      final code = _codeBeforeDash(label);
      final desc = label.contains(' - ') ? label.substring(label.indexOf(' - ') + 3).trim() : label;
      // Ancien format : une seule quantité « Qté: »
      final legacyQty = double.tryParse(_segmentValue(txt, 'Qté:') ?? '');
      final pk = _feedbackPk(fb);
      services.add({
        'pkService': pk,
        'pkServiceUsed': pk,
        'woseService': code,
        'woseDescription': desc,
        'wosePlannedQuantity': double.tryParse(_segmentValue(txt, 'Qté planifiée:') ?? '') ?? legacyQty ?? 1.0,
        'woseUsedQuantity': double.tryParse(_segmentValue(txt, 'Qté consommée:') ?? '') ?? legacyQty ?? 0.0,
        'woseUnit': _segmentValue(txt, 'Unité:') ?? 'U',
        'woseCost': _segmentValue(txt, 'Coût:') ?? '',
        'woseReplacementType': _segmentValue(txt, 'Type:') ?? '',
        'woseMeter': _segmentValue(txt, 'Compteur:') ?? '',
        'woseAction': _segmentValue(txt, 'Action:') ?? '',
        'woseSequence': _segmentValue(txt, 'Séq:') ?? '',
      });
    }
    return services;
  }

  /// Récupérer les commentaires/feedbacks d'un OT
  Future<List<dynamic>> getDocuments(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    return _section(raw, 'employeeFeedbackViewworkorderfind')
        // Les comptes-rendus techniques tagués ont leur propre onglet
        .where((fb) => !FeedbackTag.isTagged(_feedbackText(fb)))
        .map((fb) {
      final txt = _feedbackText(fb);
      final author = (fb['woefEmployee'] ?? 'Agent').toString();
      final dateStr = (fb['woefStartDate'] ?? fb['woefEndDate'] ?? '').toString();
      final pk = _feedbackPk(fb);
      return {
        'pkDocument': pk,
        'pkEmployeeFeedback': pk,
        'comment': txt.isNotEmpty ? txt : 'Compte-rendu intervention',
        'wodoComment': txt,
        'wodoDescription': txt,
        'author': author,
        'wodoCreationUser': author,
        'woefEmployee': author,
        'createdAt': dateStr,
      };
    }).toList();
  }

  static Map<String, dynamic> _attributeRow(dynamic pk, dynamic name, dynamic value, dynamic desc, dynamic unit) => {
        'pkWorkOrderAttribute': pk,
        'pkAttribute': pk,
        'woatName': name,
        'woatValue': value,
        'woatDescription': desc,
        'woatUnitSymbol': unit,
      };

  /// Récupérer les sous-attributs d'un OT
  Future<List<dynamic>> getAttributes(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    final attrs = _section(raw, 'workOrderAttributeViewworkorderfind')
        .map((a) => _attributeRow(
              a['pkWorkOrderAttribute'] ?? a['pkAttribute'] ?? 0,
              a['woatName'] ?? 'Attribut',
              a['woatValue'] ?? '',
              a['woatDescription'] ?? '',
              a['woatUnitSymbol'] ?? '',
            ))
        .toList();

    // Attributs enregistrés via comptes-rendus tagués : "[ATTRIBUT TECHNIQUE] Nom: valeur (desc)"
    for (final fb in _taggedFeedbacks(raw, FeedbackTag.attribute)) {
      final txt = _feedbackText(fb);
      String name = 'Attribut';
      String value = '';
      String desc = '';
      final closing = txt.indexOf(']');
      final body = closing >= 0 ? txt.substring(closing + 1).trim() : '';
      final colon = body.indexOf(':');
      if (colon >= 0) {
        name = body.substring(0, colon).trim();
        final right = body.substring(colon + 1).trim();
        final open = right.lastIndexOf('(');
        if (open >= 0 && right.endsWith(')')) {
          desc = right.substring(open + 1, right.length - 1).trim();
          value = right.substring(0, open).trim();
        } else {
          value = right;
        }
      }
      attrs.add(_attributeRow(_feedbackPk(fb), name, value, desc, ''));
    }
    return attrs;
  }

  /// Récupérer les moyens d'un OT
  Future<List<dynamic>> getMoyens(String otCode) async {
    final raw = await _getRawWorkOrder(otCode);
    // Coswin n'a pas de moyens dans son API (free1 contient des codes comptables) :
    // seuls les moyens notés par l'application sont relus.
    final facilities = <Map<String, dynamic>>[];

    // Moyens enregistrés via comptes-rendus tagués : "Moyen: X | Immat: Y | Durée: 2h"
    for (final fb in _taggedFeedbacks(raw, FeedbackTag.facility)) {
      final txt = _feedbackText(fb);
      final pk = _feedbackPk(fb);
      final moyen = _segmentValue(txt, 'Moyen:') ?? 'VEHICULE';
      facilities.add({
        'pkFacility': pk,
        'pkFacilityUsed': pk,
        'wofuFacility': _codeBeforeDash(moyen),
        'wofuDescription': moyen.contains(' - ') ? moyen.substring(moyen.indexOf(' - ') + 3).trim() : '',
        'wofuEquipment': _segmentValue(txt, 'Immat:') ?? 'VEHICULE',
        'wofuDuration': (_segmentValue(txt, 'Durée:') ?? '1.0').replaceAll('h', '').trim(),
        'wofuStartDate': fb['woefStartDate'] ?? '',
      });
    }
    return facilities;
  }

  /// Récupérer les équipements réels depuis le backend FastAPI Senelec
  Future<List<dynamic>> getEquipments() async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) throw Exception('Pas de connexion internet');
    try {
      final response = await _apiService.get('/api/v1/mobile/equipments', queryParameters: {'entity': 'SENELEC'});
      if (response is Map && response['equipments'] is List) {
        return response['equipments'];
      }
      final payload = _extractDataPayload(response);
      return payload is List ? payload : [];
    } catch (e) {
      _log('❌ Erreur getEquipments: $e');
      rethrow;
    }
  }

  // ========== SOUS-RESSOURCES : ÉCRITURE (DIRECT COSWIN) ==========

  static String _nowIso() => DateTime.now().toUtc().toIso8601String();

  /// Garde la date fournie si elle est au format ISO 8601, sinon maintenant.
  static String _isoOrNow(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.contains('T') ? s : _nowIso();
  }

  static String _codeBeforeDash(String label) =>
      label.contains(' - ') ? label.split(' - ')[0].trim() : label;

  /// Créer une action (mode opératoire) dans Coswin (/actions)
  Future<void> createOperation(String otCode, Map<String, dynamic> data) {
    final desc = (data['opopDescription'] ?? data['opopJobDescription'] ?? data['description'] ?? 'Action OT').toString().trim();
    // Code d'action Coswin (référentiel /actions), transmis tel quel : pas de troncature.
    final actionCode = (data['wowaAction'] ?? _codeBeforeDash(desc)).toString().trim();
    return _mutate('créer l\'opération', otCode: otCode, () async {
      // wowaEquipment est obligatoire pour Coswin : équipement de l'OT par défaut.
      final equipment = (data['wowaEquipment'] ?? (await _getRawWorkOrder(otCode))['wowoEquipment'] ?? '')
          .toString()
          .trim();
      final payload = {
        'wowaAction': actionCode.isEmpty ? 'ACTION' : actionCode,
        'wowaEquipment': equipment,
        'mdatDescription': desc,
        'wowaDuration': _duration(data),
      };
      await _apiService.postCoswin('/workorders/$otCode/actions', data: payload);
    });
  }

  static double _duration(Map<String, dynamic> data) =>
      double.tryParse((data['duration'] ?? data['wowaDuration'] ?? '1.0').toString()) ?? 1.0;

  /// Modifier une opération (seule la durée est modifiable côté Coswin).
  Future<void> updateOperation(String otCode, int pk, Map<String, dynamic> data) {
    return _mutate('modifier l\'opération', otCode: otCode,
        () => _apiService.putCoswin('/workorders/$otCode/actions/$pk', data: {'wowaDuration': _duration(data)}));
  }

  Future<void> deleteOperation(String otCode, int pk) async => _notDeletable('une opération');

  /// Créer un commentaire / compte-rendu d'intervention directement dans Coswin (employeefeedbacks)
  Future<void> createDocument(String otCode, Map<String, dynamic> data) {
    final currentUser = HiveService.getCurrentUser();
    final userMatricule = (data['woefEmployee'] ?? currentUser?.matricule ?? currentUser?.code)
        ?.toString()
        .trim();

    if (userMatricule == null || userMatricule.isEmpty) {
      throw Exception("Matricule utilisateur introuvable. Veuillez vous déconnecter et vous reconnecter.");
    }

    final normalizedStatus = OTStatus.normalize(
      (data['woefUserStatus'] ?? data['woefEmployeeUserStatus'] ?? data['status'])?.toString(),
    );
    final status = OTStatus.feedbackCodes.contains(normalizedStatus) ? normalizedStatus! : OTStatus.created;

    final commentText = (data['reemDescription'] ??
            data['comment'] ??
            data['wodoComment'] ??
            data['description'] ??
            data['woefLongString1'] ??
            'Compte-rendu intervention')
        .toString()
        .trim();

    final payload = {
      'woefEmployee': userMatricule,
      'woefEmployeeUserStatus': status,
      'woefUserStatus': status,
      'woefStartDate': _isoOrNow(data['woefStartDate']),
      'woefEndDate': _isoOrNow(data['woefEndDate']),
      'woefActualHours': double.tryParse(data['woefActualHours']?.toString() ?? '1.0') ?? 1.0,
      'woefLongString1': commentText,
    };

    return _mutate('enregistrer le commentaire', otCode: otCode,
        () => _apiService.postCoswin('/workorders/$otCode/employeefeedbacks', data: payload));
  }

  /// Modifier le texte d'un compte-rendu.
  Future<void> updateDocument(String otCode, int pk, Map<String, dynamic> data) {
    final text = (data['comment'] ?? data['wodoComment'] ?? data['woefLongString1'] ?? '').toString().trim();
    return _putFeedbackText(otCode, pk, text, 'modifier le commentaire');
  }

  Future<void> _putFeedbackText(String otCode, int pk, String text, String action) {
    return _mutate(action, otCode: otCode,
        () => _apiService.putCoswin('/workorders/$otCode/employeefeedbacks/$pk', data: {'woefLongString1': text}));
  }

  Future<void> deleteDocument(String otCode, int pk) async => _notDeletable('un compte-rendu');

  /// Enregistre une sous-ressource sous forme de compte-rendu tagué.
  Future<void> _createTaggedFeedback(String otCode, FeedbackTag tag, String body) {
    final text = '${tag.label} $body';
    return createDocument(otCode, {
      'woefLongString1': text,
      'comment': text,
      'woefUserStatus': OTStatus.created,
      'woefActualHours': 0.0,
    });
  }

  /// Réécrit une sous-ressource taguée. Refuse de toucher un élément natif
  /// Coswin (stock, attribut...) dont le pk n'est pas celui d'un compte-rendu.
  Future<void> _updateTaggedFeedback(String otCode, int pk, FeedbackTag tag, String body) async {
    final raw = await _getRawWorkOrder(otCode);
    if (!_taggedFeedbacks(raw, tag).any((fb) => _feedbackPk(fb) == pk)) {
      throw UnsupportedError(
        'Cet élément provient directement de Coswin et ne peut pas être modifié depuis l\'application.',
      );
    }
    await _putFeedbackText(otCode, pk, '${tag.label} $body', 'modifier l\'élément');
  }

  /// Affecter un intervenant (main d'œuvre) à un OT dans Coswin (/allocatedemployees)
  Future<void> createWorkforce(String otCode, Map<String, dynamic> data) {
    final rawEmp = (data['woeaEmployee'] ?? data['employee'] ?? '').toString().trim();
    final currentMatricule = HiveService.getCurrentUser()?.matricule ?? '';
    final employee = rawEmp.isNotEmpty && rawEmp.toLowerCase() != OTPayloadRules.systemSupervisor
        ? rawEmp
        : currentMatricule;
    if (employee.isEmpty) {
      throw Exception('Intervenant non renseigné et matricule utilisateur introuvable.');
    }

    final resource = _codeBeforeDash((data['woeaResource'] ?? data['resource'] ?? 'RDEF').toString().trim());

    final payload = {
      'woeaEmployee': employee,
      'woeaResource': resource.isNotEmpty ? resource : 'RDEF',
      'woeaPlannedHours': double.tryParse((data['woeaPlannedHours'] ?? data['actualHours'] ?? '1.0').toString()) ?? 1.0,
      'woeaAllocationDate': _isoOrNow(data['woeaAllocationDate']),
      'woeaScheduleDate': _isoOrNow(data['woeaScheduleDate'] ?? data['woeaAllocationDate']),
      'woeaIsPlanned': data['woeaIsPlanned'] ?? true,
    };

    return _mutate('affecter l\'intervenant', otCode: otCode,
        () => _apiService.postCoswin('/workorders/$otCode/allocatedemployees', data: payload));
  }

  /// Modifier une affectation (heures et dates ; l'intervenant n'est pas modifiable côté Coswin).
  Future<void> updateWorkforce(String otCode, int pk, Map<String, dynamic> data) {
    final payload = {
      'woeaPlannedHours': double.tryParse((data['woeaPlannedHours'] ?? data['actualHours'] ?? '1.0').toString()) ?? 1.0,
      'woeaAllocationDate': _isoOrNow(data['woeaAllocationDate']),
      'woeaScheduleDate': _isoOrNow(data['woeaScheduleDate'] ?? data['woeaAllocationDate']),
    };
    return _mutate('modifier l\'intervenant', otCode: otCode,
        () => _apiService.putCoswin('/workorders/$otCode/allocatedemployees/$pk', data: payload));
  }

  Future<void> deleteWorkforce(String otCode, int pk) {
    return _mutate('supprimer l\'intervenant', otCode: otCode,
        () => _apiService.deleteCoswin('/workorders/$otCode/allocatedemployees/$pk'));
  }

  /// Enregistrer une pièce de rechange utilisée sur l'OT dans Coswin via compte-rendu tagué
  Future<void> createPart(String otCode, Map<String, dynamic> data) =>
      _createTaggedFeedback(otCode, FeedbackTag.part, _partText(data));

  static String _partText(Map<String, dynamic> data) {
    final partCode = (data['wospItem'] ?? data['wospPart'] ?? data['partCode'] ?? data['wosyPart'] ?? '').toString().trim();
    final desc = (data['wospPartDescription'] ?? data['article'] ?? data['partDescription'] ?? data['wosyDescription'] ?? partCode).toString().trim();
    final qty = (data['wospQtyUsed'] ?? data['qtyUsed'] ?? data['wosyUsedQuantity'] ?? data['wosyQuantity'] ?? '1.0').toString().trim();
    final planned = (data['wospQtyPlanned'] ?? data['plannedQty'] ?? '').toString().trim();
    return 'Article: $partCode - $desc | Qté: $qty${planned.isNotEmpty ? ' | Qté planifiée: $planned' : ''}';
  }

  Future<void> updatePart(String otCode, int pk, Map<String, dynamic> data) =>
      _updateTaggedFeedback(otCode, pk, FeedbackTag.part, _partText(data));

  Future<void> deletePart(String otCode, int pk) async => _notDeletable('une pièce');

  /// Enregistrer un sous-attribut sur l'OT dans Coswin via compte-rendu tagué
  Future<void> createAttribute(String otCode, Map<String, dynamic> data) =>
      _createTaggedFeedback(otCode, FeedbackTag.attribute, _attributeText(data));

  static String _attributeText(Map<String, dynamic> data) {
    final name = (data['woatName'] ?? data['name'] ?? 'Attribut').toString().trim();
    final value = (data['woatValue'] ?? data['value'] ?? '').toString().trim();
    final unit = (data['woatUnitSymbol'] ?? data['unit'] ?? '').toString().trim();
    final desc = (data['woatDescription'] ?? data['description'] ?? '').toString().trim();

    final unitPart = unit.isNotEmpty ? ' $unit' : '';
    final descPart = desc.isNotEmpty ? ' ($desc)' : '';
    return '$name: $value$unitPart$descPart';
  }

  Future<void> updateAttribute(String otCode, int pk, Map<String, dynamic> data) =>
      _updateTaggedFeedback(otCode, pk, FeedbackTag.attribute, _attributeText(data));

  Future<void> deleteAttribute(String otCode, int pk) async => _notDeletable('un attribut');

  /// Enregistrer un moyen/véhicule utilisé sur l'OT dans Coswin via compte-rendu tagué
  Future<void> createFacilityUsed(String otCode, Map<String, dynamic> data) {
    final moyen = (data['wofuFacility'] ?? data['moyen'] ?? 'VEHICULE').toString().trim();
    final desc = (data['wofuDescription'] ?? data['moyenDesc'] ?? '').toString().trim();
    final immat = (data['wofuEquipment'] ?? data['equipement'] ?? moyen).toString().trim();
    final duration = (data['wofuDuration'] ?? data['duration'] ?? '1.0').toString().trim();
    final label = desc.isNotEmpty && desc != moyen ? '$moyen - $desc' : moyen;

    return _createTaggedFeedback(otCode, FeedbackTag.facility, 'Moyen: $label | Immat: $immat | Durée: ${duration}h');
  }

  Future<void> deleteFacilityUsed(String otCode, int pk) async => _notDeletable('un moyen');

  /// Enregistrer un service utilisé sur l'OT dans Coswin via compte-rendu tagué
  Future<void> createServiceUsed(String otCode, Map<String, dynamic> data) {
    String field(String key, [String fallback = '']) => (data[key] ?? fallback).toString().trim();
    final code = field('woseService', field('serviceCode'));
    final desc = field('woseDescription', code);

    final segments = <String>[
      'Service: $code - $desc',
      'Qté planifiée: ${field('wosePlannedQuantity', '1.0')}',
      'Qté consommée: ${field('woseUsedQuantity', '0.0')}',
      'Unité: ${field('woseUnit', 'U')}',
      // Champs facultatifs : notés seulement s'ils sont renseignés
      for (final e in const {
        'woseCost': 'Coût',
        'woseReplacementType': 'Type',
        'woseMeter': 'Compteur',
        'woseAction': 'Action',
        'woseSequence': 'Séq',
      }.entries)
        if (field(e.key).isNotEmpty) '${e.value}: ${field(e.key)}',
    ];
    return _createTaggedFeedback(otCode, FeedbackTag.service, segments.join(' | '));
  }

  Future<void> deleteServiceUsed(String otCode, int pk) async => _notDeletable('un service');

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
