import 'package:appmobilegmao/models/ot_referentials.dart';
import 'package:appmobilegmao/models/ot_status.dart';

/// Règles de validation des payloads OT imposées par Coswin Senelec.
///
/// Les valeurs sont contrôlées contre les référentiels réels de Coswin
/// ([OTReferentials]). Si ceux-ci ne sont pas encore chargés, la valeur est
/// envoyée telle quelle : c'est alors le repli [withoutRejectedFields] qui
/// retire un champ refusé par Coswin.
///
/// Isolées du service réseau (SRP) pour être réutilisées en création et en
/// mise à jour, et testables sans appel HTTP.
class OTPayloadRules {
  OTPayloadRules._();

  static const int maxJobLength = 15;
  static const String defaultJob = 'Intervention OT';
  static const String defaultJobClass = 'POSTE';
  static const String defaultPriority = 'NORMALE';
  static const String systemSupervisor = 'supervisor';

  static const Set<String> _priorityAliases = {'NORMALE', 'NORMAL', '2', 'MOYEN'};

  /// Correspondance message d'erreur Coswin → champ à retirer pour une tentative allégée.
  static const Map<String, List<String>> rejectableFields = {
    'wowoPriority': ['priority'],
    'wowoJobType': ['job type', 'jobtype'],
    'wowoJobClass': ['job class', 'jobclass'],
    'wowoUserStatus': ['user status', 'userstatus'],
    'wowoSupervisor': ['supervisor'],
  };

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static String truncateJob(String job) =>
      job.length > maxJobLength ? job.substring(0, maxJobLength) : job;

  static void _setJob(Map<String, dynamic> payload, String job) {
    payload['wowoJob'] = job;
    payload['mdjbDescription'] = job;
    payload['jobDescription'] = job;
  }

  /// Code accepté s'il figure dans [items], ou si le référentiel n'est pas chargé.
  static String? _codeIn(List<RefItem> items, String code) {
    if (code.isEmpty) return null;
    if (items.isEmpty) return code;
    final upper = code.toUpperCase();
    for (final item in items) {
      if (item.code.toUpperCase() == upper) return item.code;
    }
    return null;
  }

  static String? _priority(OTReferentials refs, String raw) {
    final code = _codeIn(refs.priorities, raw.toUpperCase());
    if (code != null) return code;
    return _priorityAliases.contains(raw.toUpperCase())
        ? _codeIn(refs.priorities, defaultPriority)
        : null;
  }

  static bool _isValidSupervisor(OTReferentials refs, String sup) {
    if (sup.toLowerCase() == systemSupervisor) return true;
    if (refs.supervisors.isNotEmpty) return _codeIn(refs.supervisors, sup) != null;
    return RegExp(r'^\d+$').hasMatch(sup);
  }

  /// Payload de création : champs obligatoires complétés par des valeurs par défaut.
  static Map<String, dynamic> forCreate(Map<String, dynamic> data, [OTReferentials refs = OTReferentials.empty]) {
    final payload = Map<String, dynamic>.from(data);

    final job = _str(payload['wowoJob']);
    _setJob(payload, truncateJob(job.isEmpty ? defaultJob : job));

    final jobClass = _codeIn(refs.jobClasses, _str(payload['wowoJobClass']).toUpperCase()) ??
        _codeIn(refs.jobClasses, defaultJobClass);
    _setOrRemove(payload, 'wowoJobClass', jobClass);

    if (payload.containsKey('wowoJobType')) {
      _setOrRemove(payload, 'wowoJobType', _codeIn(refs.jobTypes, _str(payload['wowoJobType']).toUpperCase()));
    }

    if (_str(payload['wowoScheduleDate']).isEmpty) {
      payload['wowoScheduleDate'] = DateTime.now().toUtc().toIso8601String();
    }
    return payload;
  }

  /// Payload de mise à jour : seuls les champs présents sont validés,
  /// les valeurs refusées par Coswin sont retirées plutôt qu'envoyées.
  static Map<String, dynamic> forUpdate(Map<String, dynamic> data, [OTReferentials refs = OTReferentials.empty]) {
    final payload = Map<String, dynamic>.from(data);

    if (payload.containsKey('wowoJob')) {
      final job = _str(payload['wowoJob']);
      if (job.isNotEmpty) _setJob(payload, truncateJob(job));
    }

    if (payload.containsKey('wowoJobClass')) {
      _setOrRemove(payload, 'wowoJobClass', _codeIn(refs.jobClasses, _str(payload['wowoJobClass']).toUpperCase()));
    }

    if (payload.containsKey('wowoUserStatus')) {
      _setOrRemove(payload, 'wowoUserStatus', OTStatus.normalize(_str(payload['wowoUserStatus'])));
    }

    if (payload.containsKey('wowoPriority')) {
      _setOrRemove(payload, 'wowoPriority', _priority(refs, _str(payload['wowoPriority'])));
    }

    if (payload.containsKey('wowoJobType')) {
      _setOrRemove(payload, 'wowoJobType', _codeIn(refs.jobTypes, _str(payload['wowoJobType']).toUpperCase()));
    }

    if (payload.containsKey('wowoSupervisor')) {
      final sup = _str(payload['wowoSupervisor']);
      if (!_isValidSupervisor(refs, sup)) payload['wowoSupervisor'] = systemSupervisor;
    }

    // Le taux de réalisation est calculé côté serveur Coswin.
    payload.remove('wowoCompletionRate');
    return payload;
  }

  // ---------------- Formats de requête Coswin ----------------

  /// Champs modifiables par `PUT /workorders/{code}/update0` (schéma Workorder0View).
  /// `wowoJob`, la zone et l'entité demandeuse ne sont pas modifiables par l'API Coswin.
  static const Set<String> updatableFields = {
    'wowoEquipment', 'wowoJobType', 'wowoJobClass', 'wowoPriority', 'wowoActionEntity',
    'wowoScheduleDate', 'wowoSupervisor', 'wowoCostcentre', 'wowoTargetDate',
    'wowoStartDate', 'wowoEndDate', 'wowoFeedbackNote',
  };

  /// Champs de l'en-tête de création (schéma WorkOrderExtraViewworkordercreatesimple0).
  static const Set<String> _createExtraFields = {
    'wowoEquipment', 'wowoJob', 'wowoJobType', 'wowoJobClass', 'wowoPriority',
    'wowoActionEntity', 'wowoCostcentre',
  };

  /// Commentaire joint aux changements de statut (obligatoire pour certains statuts Coswin).
  static const String statusChangeComment = "Statut modifié depuis l'application mobile GMAO";

  static Map<String, dynamic> _pick(Map<String, dynamic> payload, Set<String> keys) => {
        for (final k in keys)
          if (_str(payload[k]).isNotEmpty) k: payload[k],
      };

  static Map<String, dynamic> _statusEntry(String status) => {
        'wowoUserStatus': status,
        'wowoStatusComments': statusChangeComment,
        'wowoStatusDate': DateTime.now().toUtc().toIso8601String(),
      };

  /// Corps de `PUT /workorders/{code}/update0`. Le statut n'est envoyé que s'il change.
  static Map<String, dynamic> update0Body(Map<String, dynamic> payload, {String? newStatus}) => {
        'workorder0View': _pick(payload, updatableFields),
        'woUserStatusUpdate0List': {
          'woUserStatusUpdate0': [if (newStatus != null) _statusEntry(newStatus)],
        },
      };

  /// Corps de `POST /workorders/createSimple0`.
  static Map<String, dynamic> createSimple0Body(Map<String, dynamic> payload) {
    final extra = _pick(payload, _createExtraFields);
    // L'application saisit l'entité comme entité demandeuse ; Coswin la reçoit comme entité réalisatrice.
    if (!extra.containsKey('wowoActionEntity') && _str(payload['wowoRequestEntity']).isNotEmpty) {
      extra['wowoActionEntity'] = payload['wowoRequestEntity'];
    }
    if (_str(payload['wowoJob']).isNotEmpty) extra['wowoJobDescription'] = payload['wowoJob'];

    final missing = ['wowoEquipment', 'wowoJobType'].where((k) => !extra.containsKey(k)).toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('Champs obligatoires pour créer un OT dans Coswin : ${missing.join(', ')}');
    }

    final status = OTStatus.normalize(_str(payload['wowoUserStatus']));
    return {
      'workordercreatesimple0': {
        ..._pick(payload, {'wowoScheduleDate', 'wowoSupervisor', 'wowoTargetDate', 'wowoStartDate', 'wowoEndDate'}),
        'workOrderExtraViewworkordercreatesimple0': extra,
      },
      'woUserStatusCreatesimple0List': {
        'woUserStatusCreatesimple0': [if (status != null) _statusEntry(status)],
      },
    };
  }

  /// Retourne une copie du payload sans les champs mis en cause par [error],
  /// ou null si l'erreur ne concerne aucun champ référentiel connu.
  static Map<String, dynamic>? withoutRejectedFields(Map<String, dynamic> payload, Object error) {
    final errLower = error.toString().toLowerCase();
    final rejected = rejectableFields.entries
        .where((e) => e.value.any(errLower.contains))
        .map((e) => e.key)
        .toList();
    if (rejected.isEmpty) return null;
    return Map<String, dynamic>.from(payload)..removeWhere((k, _) => rejected.contains(k));
  }

  static void _setOrRemove(Map<String, dynamic> payload, String key, Object? value) {
    if (value == null) {
      payload.remove(key);
    } else {
      payload[key] = value;
    }
  }
}
