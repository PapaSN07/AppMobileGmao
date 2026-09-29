import 'dart:async';
import 'dart:convert';

import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/models/ot_status.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Charge les référentiels OT officiels depuis Coswin (types, classes,
/// priorités, statuts, superviseurs) au lieu de listes codées en dur.
///
/// Les référentiels changent rarement : ils sont conservés sur l'appareil
/// ([_ttl]) et rafraîchis en arrière-plan quand ils sont périmés.
class CoswinReferentialService {
  CoswinReferentialService(this._api);

  final ApiService _api;

  static const String _prefsKey = 'coswin_ot_referentials_v2';
  static const String _prefsDateKey = 'coswin_ot_referentials_v2_at';
  static const Duration _ttl = Duration(hours: 24);
  static const String _inactiveEntity = 'INACTIF';

  /// Requête "toutes les lignes" : Coswin exige un filtre, on exclut une valeur inexistante.
  static const Map<String, dynamic> _allRowsQuery = {
    'usePagination': 'true',
    'filterOperator': 'different',
    'filterOperand1': 'ZZZZ_DUMMY',
  };

  OTReferentials? _memory;
  Future<OTReferentials>? _inFlight;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Référentiels disponibles le plus vite possible : mémoire, puis appareil, puis Coswin.
  Future<OTReferentials> load() async {
    final memory = _memory;
    if (memory != null) return memory;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final cached = OTReferentials.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (!_isComplete(cached)) return await refresh();
        _apply(cached);
        final savedAt = DateTime.tryParse(prefs.getString(_prefsDateKey) ?? '');
        if (savedAt == null || DateTime.now().difference(savedAt) > _ttl) {
          unawaited(refresh());
        }
        return cached;
      } catch (e) {
        _log('⚠️ Cache référentiels illisible, rechargement depuis Coswin: $e');
      }
    }
    return refresh();
  }

  /// Recharge depuis Coswin (un seul chargement à la fois).
  Future<OTReferentials> refresh() {
    return _inFlight ??= _fetchAndStore().whenComplete(() => _inFlight = null);
  }

  /// Toutes les listes indispensables aux formulaires OT sont présentes.
  static bool _isComplete(OTReferentials refs) =>
      refs.jobTypes.isNotEmpty &&
      refs.jobClasses.isNotEmpty &&
      refs.statuses.isNotEmpty &&
      refs.supervisors.isNotEmpty;

  void _apply(OTReferentials refs) {
    _memory = refs;
    if (refs.statusSystem.isNotEmpty) OTStatus.register(refs.statusSystem);
  }

  Future<OTReferentials> _fetchAndStore() async {
    final results = await Future.wait([
      _fetchAll('/jobs/types'),
      _fetchAll('/jobs/classes'),
      _fetchAll('/priorities'),
      _fetchAll('/workorders/userstatuses'),
      _fetchAll('/supervisors'),
    ]);
    final previous = _memory ?? OTReferentials.empty;
    final [jobTypes, jobClasses, priorities, statuses, supervisors] = results;

    final fetched = OTReferentials(
      jobTypes: jobTypes.map((r) => RefItem(_s(r['mdjtCode']), _s(r['mdjtDescription']))).toList(),
      jobClasses: jobClasses.map((r) => RefItem(_s(r['mdclCode']), _s(r['mdclDescription']))).toList(),
      priorities: priorities
          .map((r) => RefItem(_s(r['plprCode']), _s(r['plprDescription']), entity: _s(r['plprEntity'])))
          .toList(),
      statuses: statuses.map((r) => RefItem(_s(r['mdusCode']), _s(r['mdusDescription']))).toList(),
      statusSystem: {
        for (final r in statuses)
          if (_s(r['mdusCode']).isNotEmpty && r['mdusSystemStatus'] is num)
            _s(r['mdusCode']): (r['mdusSystemStatus'] as num).toInt(),
      },
      supervisors: supervisors
          .map((r) => RefItem(_s(r['resvCode']), _s(r['resvDescription']), entity: _s(r['resvEntity'])))
          .where((e) => e.entity.toUpperCase() != _inactiveEntity)
          .toList()
        ..sort((a, b) => a.description.compareTo(b.description)),
    );

    // Une liste en échec reprend sa dernière version connue plutôt que de devenir vide.
    List<RefItem> keep(List<RefItem> fresh, List<RefItem> old) => fresh.isNotEmpty ? fresh : old;
    final refs = OTReferentials(
      jobTypes: keep(fetched.jobTypes, previous.jobTypes),
      jobClasses: keep(fetched.jobClasses, previous.jobClasses),
      priorities: keep(fetched.priorities, previous.priorities),
      statuses: keep(fetched.statuses, previous.statuses),
      supervisors: keep(fetched.supervisors, previous.supervisors),
      statusSystem: fetched.statusSystem.isNotEmpty ? fetched.statusSystem : previous.statusSystem,
    );
    _apply(refs);

    // Cache incomplet : rien n'est sauvegardé, le prochain accès réessaiera Coswin.
    if (!_isComplete(refs)) {
      _log('⚠️ Référentiels Coswin incomplets, nouvel essai au prochain accès');
      _memory = null;
      return refs;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(refs.toJson()));
      await prefs.setString(_prefsDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      _log('⚠️ Impossible de sauvegarder les référentiels: $e');
    }
    _log('✅ Référentiels Coswin chargés: ${refs.jobTypes.length} types, ${refs.jobClasses.length} classes, '
        '${refs.statuses.length} statuts, ${refs.supervisors.length} superviseurs');
    return refs;
  }

  static String _s(dynamic v) => v?.toString().trim() ?? '';

  /// Toutes les lignes d'un référentiel, en suivant la pagination Coswin (`/nextPage`).
  /// Une liste vide est renvoyée si Coswin est injoignable.
  Future<List<Map<String, dynamic>>> _fetchAll(String path) async {
    final rows = <Map<String, dynamic>>[];
    try {
      var response = await _api.getCoswin(path, queryParameters: Map.of(_allRowsQuery));
      while (true) {
        rows.addAll(_rowsOf(response));
        final context = response is Map ? response['paginationContext'] : null;
        final more = response is Map && response['moreDataAvailable'] == true;
        if (!more || context == null) break;
        response = await _api.getCoswin('$path/nextPage', queryParameters: {'paginationContext': context});
      }
    } catch (e) {
      // Liste partielle = liste inutilisable : on la considère comme indisponible.
      _log('⚠️ Référentiel Coswin $path indisponible: $e');
      return const [];
    }
    return rows;
  }

  /// Extrait la première liste de `response.list` (le nom de la clé varie selon l'endpoint).
  static List<Map<String, dynamic>> _rowsOf(dynamic response) {
    if (response is Map && response['list'] is Map) {
      for (final value in (response['list'] as Map).values) {
        if (value is List) return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}
