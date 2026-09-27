import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Résultat d'un sondage Coswin `/workorders` entre deux codes :
/// les codes du premier lot (ordre croissant) et s'il en reste après.
class CodeProbe {
  final List<int> codes;
  final bool hasMore;
  const CodeProbe(this.codes, this.hasMore);

  bool get isEmpty => codes.isEmpty;
  int get maxCode => codes.reduce(max);
  int get minCode => codes.reduce(min);
}

typedef CodeProbeFn = Future<CodeProbe> Function(int from, int to);

/// Localise les bornes des codes OT d'une année.
///
/// Coswin ne sait pas trier : il renvoie toujours les OT par code croissant.
/// Comme les codes sont séquentiels (AAAA + n° d'ordre), on retrouve le plus
/// récent par sondages parallèles puis on le mémorise sur l'appareil ; les
/// fois suivantes un seul sondage suffit en général.
class OTCodeLocator {
  OTCodeLocator(this._probe, {this.parallelProbes = 6});

  final CodeProbeFn _probe;

  /// Nombre de sondages lancés en parallèle à chaque tour de recherche.
  final int parallelProbes;

  /// En dessous de cet écart, un seul sondage (≤ 50 OT) donne la réponse.
  static const int _pageSize = 50;

  final Map<String, int?> _memory = {};

  static int yearStart(int year) => year * 1000000;
  static int yearEnd(int year) => year * 1000000 + 999999;

  Future<int?> _readPref(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      return _memory[key] = prefs.getInt(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePref(String key, int value) async {
    _memory[key] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  /// Premier code OT de l'année, ou null si l'année n'a aucun OT.
  Future<int?> firstCode(int year) async {
    final key = 'ot_first_code_$year';
    final saved = await _readPref(key);
    if (saved != null) return saved;

    final probe = await _probe(yearStart(year), yearEnd(year));
    if (probe.isEmpty) return null;
    await _writePref(key, probe.minCode);
    return probe.minCode;
  }

  /// Code OT le plus récent de l'année, ou null si l'année n'a aucun OT.
  Future<int?> latestCode(int year) async {
    final key = 'ot_latest_code_$year';
    final hint = await _readPref(key);
    // Une année écoulée ne reçoit plus de nouveaux OT : la valeur mémorisée est définitive.
    if (hint != null && year < DateTime.now().year) return hint;

    final first = await firstCode(year);
    if (first == null) return null;

    final latest = await _search(year, first, hint);
    await _writePref(key, latest);
    return latest;
  }

  /// Recherche du plus grand code : [lo] est toujours un code tel que
  /// `[lo, fin d'année]` contient des OT, [hi] une borne au-delà du dernier OT.
  Future<int> _search(int year, int first, int? hint) async {
    final end = yearEnd(year);
    var lo = first;
    var hi = end + 1;

    if (hint != null && hint >= first) {
      final probe = await _probe(hint, end);
      if (!probe.isEmpty && !probe.hasMore) return probe.maxCode;
      if (probe.isEmpty) {
        hi = hint;
      } else {
        lo = hint;
      }
    }

    var firstRound = true;
    while (hi - lo > _pageSize) {
      final geometric = firstRound ? _geometricPoints(lo, hi) : const <int>[];
      final points = geometric.isNotEmpty ? geometric : _evenPoints(lo, hi);
      firstRound = false;
      final probes = await Future.wait(points.map((p) => _probe(p, end)));

      for (var i = 0; i < points.length; i++) {
        final probe = probes[i];
        if (probe.isEmpty) {
          hi = min(hi, points[i]);
        } else if (!probe.hasMore) {
          return probe.maxCode;
        } else {
          lo = max(lo, points[i]);
        }
      }
    }

    final last = await _probe(lo, end);
    return last.isEmpty ? lo : last.maxCode;
  }

  /// Premier tour : écarts croissants (64, 256, 1024…) pour trouver vite un
  /// petit comme un grand nombre de nouveaux OT depuis le dernier passage.
  List<int> _geometricPoints(int lo, int hi) => [
        for (var i = 0; i < parallelProbes; i++) lo + 64 * pow(4, i).toInt(),
      ].where((p) => p < hi).toList();

  /// Tours suivants : découpage régulier de l'intervalle restant.
  List<int> _evenPoints(int lo, int hi) {
    final step = (hi - lo) / (parallelProbes + 1);
    return [
      for (var i = 1; i <= parallelProbes; i++) lo + (step * i).round(),
    ].where((p) => p > lo && p < hi).toSet().toList()
      ..sort();
  }
}
