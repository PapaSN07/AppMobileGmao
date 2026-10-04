import 'package:appmobilegmao/services/pending_ot_queue.dart';

/// L'OT a été modifié dans Coswin depuis la saisie hors ligne.
class OtConflictException implements Exception {
  const OtConflictException(this.conflicts);

  final List<FieldConflict> conflicts;

  @override
  String toString() => 'L\'OT a été modifié dans Coswin entre-temps '
      '(${conflicts.map((c) => c.field).join(', ')}).';
}

/// Détection des conflits d'une modification d'OT (avec ou sans réseau).
class OtConflict {
  /// Libellés Senelec des champs d'OT (affichage des conflits).
  static const Map<String, String> fieldLabels = {
    'wowoJob': 'Intervention',
    'wowoJobType': 'Type d\'intervention',
    'wowoJobClass': 'Classe d\'intervention',
    'wowoCostcentre': 'Centre de responsabilité',
    'wowoEquipment': 'Équipement',
    'wowoSupervisor': 'Superviseur',
    'wowoUserStatus': 'Statut',
    'wowoPriority': 'Priorité',
    'wowoZone': 'Zone',
    'wowoRequestEntity': 'Entité',
    'wowoCompletionRate': 'Taux de réalisation',
    'wowoLongString2': 'Taux de réalisation',
    'wowoFeedbackNote': 'Commentaire',
  };

  static String labelOf(String field) => fieldLabels[field] ?? field;

  /// Champs que l'agent a réellement changés depuis l'ouverture de l'écran : seuls ceux-là
  /// partent à Coswin, pour ne pas réécrire avec d'anciennes valeurs ce qu'un autre a changé.
  static Map<String, dynamic> changedFields(Map<String, dynamic> initial, Map<String, dynamic> current) {
    return {
      for (final entry in current.entries)
        if (entry.key != 'wowoCode' && _text(entry.value) != _text(initial[entry.key])) entry.key: entry.value,
    };
  }

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
