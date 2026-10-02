import 'package:appmobilegmao/services/pending_ot_queue.dart';

/// L'OT a été modifié dans Coswin depuis la saisie hors ligne.
class OtConflictException implements Exception {
  const OtConflictException(this.conflicts);

  final List<FieldConflict> conflicts;

  @override
  String toString() => 'L\'OT a été modifié dans Coswin entre-temps '
      '(${conflicts.map((c) => c.field).join(', ')}).';
}

/// Détection des conflits d'une modification d'OT faite sans réseau.
class OtConflict {
  /// Valeurs Coswin, au moment de la saisie, des champs que l'agent modifie.
  static Map<String, dynamic> baselineFor(Map<String, dynamic> wanted, Map<String, dynamic>? coswinOt) {
    if (coswinOt == null) return const {};
    return {
      for (final field in wanted.keys)
        if (coswinOt.containsKey(field)) field: coswinOt[field],
    };
  }

  /// Champs changés dans Coswin par quelqu'un d'autre depuis la saisie :
  /// la valeur actuelle diffère de celle d'origine **et** de celle voulue par l'agent.
  static List<FieldConflict> detect({
    required Map<String, dynamic> baseline,
    required Map<String, dynamic> wanted,
    required Map<String, dynamic> current,
  }) {
    return [
      for (final field in baseline.keys)
        if (_text(current[field]) != _text(baseline[field]) && _text(current[field]) != _text(wanted[field]))
          FieldConflict(field, coswin: _text(current[field]), mine: _text(wanted[field])),
    ];
  }

  static String _text(dynamic value) => (value ?? '').toString().trim();
}
