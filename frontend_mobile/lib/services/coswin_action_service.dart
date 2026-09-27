import 'dart:async';

import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Référentiel des actions Coswin (étapes du mode opératoire).
///
/// Coswin en compte plusieurs milliers et ne sait filtrer que par code : la liste
/// complète est téléchargée une fois (plusieurs minutes), conservée [_ttl] sur
/// l'appareil, puis rafraîchie en arrière-plan quand elle est périmée.
class CoswinActionService {
  CoswinActionService(this._api);

  final ApiService _api;

  static const String _boxName = 'coswin_actions';
  static const String _itemsKey = 'items';
  static const String _savedAtKey = 'saved_at';
  static const Duration _ttl = Duration(days: 7);

  /// Garde-fou : Coswin renvoie 200 actions par page.
  static const int _maxPages = 200;

  List<RefItem>? _memory;
  Future<List<RefItem>>? _inFlight;

  /// Nombre d'actions déjà téléchargées pendant un chargement en cours.
  final ValueNotifier<int> loadedCount = ValueNotifier(0);

  bool get isLoading => _inFlight != null;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Actions disponibles le plus vite possible : mémoire, puis appareil, puis Coswin.
  Future<List<RefItem>> load() async {
    final memory = _memory;
    if (memory != null) return memory;

    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_itemsKey);
      if (raw is List && raw.isNotEmpty) {
        final cached = raw
            .whereType<Map>()
            .map((m) => RefItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _memory = cached;
        final savedAt = DateTime.tryParse(box.get(_savedAtKey)?.toString() ?? '');
        if (savedAt == null || DateTime.now().difference(savedAt) > _ttl) unawaited(refresh());
        return cached;
      }
    } catch (e) {
      _log('⚠️ Cache des actions illisible: $e');
    }
    return refresh();
  }

  /// Retélécharge toutes les actions depuis Coswin (un seul chargement à la fois).
  Future<List<RefItem>> refresh() => _inFlight ??= _fetchAll().whenComplete(() => _inFlight = null);

  Future<List<RefItem>> _fetchAll() async {
    final actions = <RefItem>[];
    loadedCount.value = 0;
    try {
      var response = await _api.getCoswin('/actions', queryParameters: {
        'usePagination': 'true',
        'filterOperator': 'different',
        'filterOperand1': 'ZZZZ_DUMMY',
      });
      for (var page = 1; page <= _maxPages; page++) {
        actions.addAll(_rowsOf(response).map((r) => RefItem(
              r['mdatCode']?.toString().trim() ?? '',
              r['mdatDescription']?.toString().trim() ?? '',
              entity: r['mdatEntity']?.toString().trim() ?? '',
            )).where((a) => a.code.isNotEmpty));
        loadedCount.value = actions.length;

        final context = response is Map ? response['paginationContext'] : null;
        if (!(response is Map && response['moreDataAvailable'] == true) || context == null) break;
        response = await _api.getCoswin('/actions/nextPage', queryParameters: {'paginationContext': context});
      }
    } catch (e) {
      // Liste incomplète : on ne l'enregistre pas, la dernière version connue reste en place.
      _log('⚠️ Chargement des actions Coswin interrompu après ${actions.length} actions: $e');
      return _memory ?? actions;
    }

    actions.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
    _memory = actions;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_itemsKey, actions.map((a) => a.toJson()).toList());
      await box.put(_savedAtKey, DateTime.now().toIso8601String());
    } catch (e) {
      _log('⚠️ Impossible de sauvegarder les actions: $e');
    }
    _log('✅ ${actions.length} actions Coswin chargées');
    return actions;
  }

  static List<Map<String, dynamic>> _rowsOf(dynamic response) {
    if (response is Map && response['list'] is Map) {
      for (final value in (response['list'] as Map).values) {
        if (value is List) return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}
