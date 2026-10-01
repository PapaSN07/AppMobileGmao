import 'package:appmobilegmao/services/offline_snapshots.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'dart:async';
import 'package:appmobilegmao/models/work_order.dart';
import 'package:appmobilegmao/services/ot_service.dart';

/// Pagination antéchronologique des OT d'un service : du plus récent au plus
/// ancien, fenêtre par fenêtre, puis année précédente jusqu'à [minYear].
///
/// Partagée par l'accueil et la liste des OT.
class OTYearPaginator {
  OTYearPaginator(this._service, {this.minYear = 2023});

  final OTService _service;
  final int minYear;

  int currentYear = DateTime.now().year;
  bool hasMoreInYear = false;

  /// Code le plus haut de la prochaine fenêtre (null = OT le plus récent de l'année).
  int? _nextUpToCode;
  String _requestEntity = '';
  bool _excludeClosed = true;

  /// Liste affichée sans réseau : date de la copie enregistrée, sinon null.
  DateTime? offlineSince;

  bool get canLoadPreviousYear => offlineSince == null && currentYear > minYear;

  /// Plus rien à charger : fin de l'année en cours et plus d'année antérieure.
  bool get isExhausted => !hasMoreInYear && !canLoadPreviousYear;

  /// Lit la fenêtre suivante ; passe à l'année précédente quand l'année est épuisée.
  /// Retourne null quand tout l'historique a été parcouru.
  Future<List<WorkOrder>?> _nextBatch() async {
    if (!hasMoreInYear) {
      if (!canLoadPreviousYear) return null;
      currentYear--;
      _nextUpToCode = null;
    }
    final page = await _service.getOrdersPage(
      scope: 'service',
      requestEntity: _requestEntity,
      excludeClosed: _excludeClosed,
      upToCode: _nextUpToCode,
      targetYear: currentYear,
    );
    hasMoreInYear = page.hasMore;
    _nextUpToCode = page.lastCode != null ? page.lastCode! - 1 : null;
    return page.workorders;
  }

  /// Enchaîne les fenêtres jusqu'à ce que [stopWhen] soit satisfait ou [maxBatches]
  /// atteint. [onBatch] reçoit les OT trouvés à chaque fenêtre (affichage progressif).
  Future<List<WorkOrder>> _collect({
    required Set<int> knownCodes,
    required int maxBatches,
    required bool Function(List<WorkOrder> found) stopWhen,
    void Function(List<WorkOrder> found)? onBatch,
  }) async {
    final seen = {...knownCodes};
    final found = <WorkOrder>[];
    for (var batch = 0; batch < maxBatches; batch++) {
      final orders = await _nextBatch();
      if (orders == null) break;
      found.addAll(orders.where((o) => seen.add(o.wowoCode)));
      onBatch?.call(List.unmodifiable(found));
      if (stopWhen(found)) break;
    }
    return found;
  }

  String get _snapshotKey => 'ot_list|$_requestEntity|$_excludeClosed';

  /// Repart de l'OT le plus récent de l'année courante. Sans réseau, renvoie la
  /// dernière liste chargée sur ce téléphone (voir [offlineSince]).
  Future<List<WorkOrder>> loadFirst({
    required String requestEntity,
    required bool excludeClosed,
    int maxBatches = 1,
    bool Function(List<WorkOrder> collected)? stopWhen,
    void Function(List<WorkOrder> collected)? onBatch,
  }) async {
    _requestEntity = requestEntity;
    _excludeClosed = excludeClosed;
    currentYear = DateTime.now().year;
    hasMoreInYear = true;
    _nextUpToCode = null;
    offlineSince = null;
    try {
      final orders = await _collect(
        knownCodes: const {},
        maxBatches: maxBatches,
        stopWhen: stopWhen ?? (_) => true,
        onBatch: onBatch,
      );
      unawaited(OfflineSnapshots.saveList(_snapshotKey, orders.map((o) => o.toJson()).toList()));
      return orders;
    } catch (e) {
      final saved = isNetworkFailure(e) ? OfflineSnapshots.readList(_snapshotKey) : null;
      if (saved == null) rethrow;
      hasMoreInYear = false;
      offlineSince = saved.savedAt;
      return saved.data.map(WorkOrder.fromJson).toList();
    }
  }

  /// Charge la suite jusqu'à trouver [minNew] OT absents de [knownCodes],
  /// dans la limite de [maxBatches] fenêtres.
  Future<List<WorkOrder>> loadMore({
    required Set<int> knownCodes,
    int maxBatches = 1,
    int minNew = 1,
    void Function(List<WorkOrder> found)? onBatch,
  }) async {
    if (offlineSince != null) return const [];
    return _collect(
      knownCodes: knownCodes,
      maxBatches: maxBatches,
      stopWhen: (found) => found.length >= minNew,
      onBatch: onBatch,
    );
  }
}
