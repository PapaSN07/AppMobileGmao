/// Source unique de vérité pour les statuts d'OT Coswin Senelec.
///
/// Les statuts réels sont chargés depuis Coswin (`/workorders/userstatuses`)
/// via [register] : chaque statut porte un « statut système »
/// (0 = créé, 1 = en cours, 2 = terminé, 3 = archivable, 4 = annulé).
/// Tant que Coswin n'a pas répondu, des valeurs de repli sont utilisées.
class OTStatus {
  OTStatus._();

  static const String created = 'CR';
  static const String inProgress = 'EC';
  static const String finished = 'TE';
  static const String closed = 'CL';
  static const String archived = 'AY';

  /// Statut système Coswin à partir duquel un OT est considéré comme fermé.
  static const int _firstClosedSystemStatus = 2;

  /// Code → statut système, chargé depuis Coswin.
  static Map<String, int> _systemStatusByCode = {};

  // ---- Valeurs de repli (avant chargement du référentiel Coswin) ----
  static const Set<String> _fallbackValidCodes = {
    created, inProgress, 'SU', finished, closed, archived, 'AZ',
  };
  static const Set<String> _fallbackClosed = {
    finished, closed, archived, 'AZ', 'AE', 'RT', 'AV',
    'CLOSE', 'CLOSED', 'TERMINE', 'TERMINEE', 'TERMINATED', 'FINI', 'FINISHED', 'ARCHIVABLE',
  };

  /// Codes acceptés par Coswin pour `woefUserStatus` (comptes-rendus).
  static const Set<String> feedbackCodes = {created, inProgress, finished, closed};

  /// Synonymes saisis/reçus → code Coswin officiel.
  static const Map<String, String> _synonyms = {
    'F': finished, 'FAIT': finished, 'FINI': finished, 'TERMINE': finished,
    'FINISHED': finished,
    'CLOTURE': closed, 'CLOSE': closed, 'CLOSED': closed,
    'EN COURS': inProgress, 'ENCOURS': inProgress,
    'OUV': created, 'OUVERT': created,
  };

  /// Taux de réalisation implicite par statut système.
  static const Map<int, double> _completionBySystemStatus = {0: 0.0, 1: 50.0, 2: 100.0};

  /// Enregistre le référentiel Coswin (code → statut système).
  static void register(Map<String, int> systemStatusByCode) {
    _systemStatusByCode = {
      for (final e in systemStatusByCode.entries) _clean(e.key): e.value,
    };
  }

  static bool get isLoaded => _systemStatusByCode.isNotEmpty;

  static String _clean(String? status) => (status ?? '').trim().toUpperCase();

  static Set<String> get validCodes =>
      isLoaded ? _systemStatusByCode.keys.toSet() : _fallbackValidCodes;

  static int? _systemStatus(String code) {
    if (isLoaded) return _systemStatusByCode[code];
    if (code == created) return 0;
    if (code == inProgress || code == 'SU') return 1;
    return _fallbackClosed.contains(code) ? _firstClosedSystemStatus : null;
  }

  /// Retourne le code Coswin officiel, ou null si le statut est inconnu.
  static String? normalize(String? status) {
    final s = _clean(status);
    if (validCodes.contains(s)) return s;
    final synonym = _synonyms[s];
    return synonym != null && validCodes.contains(synonym) ? synonym : null;
  }

  static bool isClosed(String? status) {
    final s = _clean(status);
    final system = _systemStatus(s);
    if (system != null) return system >= _firstClosedSystemStatus;
    return _fallbackClosed.contains(s);
  }

  /// Un OT est modifiable tant qu'il n'est ni terminé, ni archivé, ni annulé.
  static bool isEditable(String? status) {
    final s = _clean(status);
    final system = _systemStatus(s);
    return system != null && system < _firstClosedSystemStatus;
  }

  static double? completionRate(String? status) {
    final code = normalize(status);
    if (code == null) return null;
    final system = _systemStatus(code);
    if (system == null) return null;
    return _completionBySystemStatus[system.clamp(0, _firstClosedSystemStatus)];
  }
}
