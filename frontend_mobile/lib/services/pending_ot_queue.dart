import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Écritures (OT, et ajout d'équipement) qui peuvent être faites sans réseau puis envoyées plus tard.
enum PendingOtKind {
  createOT('Création de l\'OT'),
  updateOT('Modification de l\'OT'),
  createOperation('Opération ajoutée'),
  updateOperation('Opération modifiée'),
  createDocument('Compte-rendu ajouté'),
  updateDocument('Compte-rendu modifié'),
  createWorkforce('Intervenant affecté'),
  updateWorkforce('Intervenant modifié'),
  deleteWorkforce('Intervenant retiré'),
  addComment('Commentaire ajouté'),
  createPart('Pièce ajoutée'),
  updatePart('Pièce modifiée'),
  updateAttribute('Attribut modifié'),
  createFacilityUsed('Moyen ajouté'),
  createServiceUsed('Service ajouté'),

  /// Nouvel équipement (proposition à valider sur le web) ; « otCode » porte alors son code.
  createEquipment('Équipement ajouté');

  const PendingOtKind(this.label);

  final String label;
}

enum PendingStatus {
  /// Attend le réseau.
  pending,

  /// L'OT a été modifié dans Coswin entre-temps : l'agent doit choisir.
  conflict,

  /// Coswin a refusé l'envoi : l'agent peut réessayer ou abandonner.
  failed,
}

/// Écart entre la valeur de Coswin et celle saisie par l'agent pour un champ.
class FieldConflict {
  const FieldConflict(this.field, {required this.coswin, required this.mine});

  final String field;
  final String coswin;
  final String mine;

  Map<String, dynamic> toJson() => {'field': field, 'coswin': coswin, 'mine': mine};

  factory FieldConflict.fromJson(Map<String, dynamic> json) => FieldConflict(
        json['field']?.toString() ?? '',
        coswin: json['coswin']?.toString() ?? '',
        mine: json['mine']?.toString() ?? '',
      );
}

/// Une écriture d'OT enregistrée sur le téléphone, en attente d'envoi.
class PendingOtAction {
  PendingOtAction({
    required this.id,
    required this.kind,
    required this.otCode,
    this.pk,
    required this.data,
    this.baseline = const {},
    required this.username,
    required this.createdAt,
    this.status = PendingStatus.pending,
    this.lastError,
    this.conflicts = const [],
    this.force = false,
  });

  final String id;
  final PendingOtKind kind;

  /// Code de l'OT ; négatif tant que l'OT créé hors ligne n'existe pas dans Coswin.
  String otCode;
  final int? pk;
  final Map<String, dynamic> data;

  /// Valeurs Coswin des champs modifiés au moment de la saisie (détection des conflits).
  final Map<String, dynamic> baseline;
  final String username;
  final DateTime createdAt;
  PendingStatus status;
  String? lastError;
  List<FieldConflict> conflicts;

  /// L'agent a choisi d'envoyer sa version malgré le conflit.
  bool force;

  bool get isNewOt => PendingOtQueue.isTemporaryCode(otCode);

  String get description => kind == PendingOtKind.createEquipment
      ? '${kind.label} · $otCode'
      : isNewOt
      ? '${kind.label} · nouvel OT${kind == PendingOtKind.createOT ? '' : ' (pas encore créé)'}'
      : '${kind.label} · OT $otCode';

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'otCode': otCode,
        'pk': pk,
        'data': data,
        'baseline': baseline,
        'username': username,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'lastError': lastError,
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
        'force': force,
      };

  static PendingOtAction? fromJson(Map<String, dynamic> json) {
    final kind = PendingOtKind.values.asNameMap()[json['kind']];
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (kind == null || createdAt == null) return null;
    return PendingOtAction(
      id: json['id'].toString(),
      kind: kind,
      otCode: json['otCode'].toString(),
      pk: json['pk'] is int ? json['pk'] as int : int.tryParse(json['pk']?.toString() ?? ''),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      baseline: Map<String, dynamic>.from(json['baseline'] as Map? ?? const {}),
      username: json['username']?.toString() ?? '',
      createdAt: createdAt,
      status: PendingStatus.values.asNameMap()[json['status']] ?? PendingStatus.pending,
      lastError: json['lastError']?.toString(),
      conflicts: (json['conflicts'] as List? ?? const [])
          .whereType<Map>()
          .map((c) => FieldConflict.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      force: json['force'] == true,
    );
  }
}

/// File des écritures d'OT faites sans réseau, gardée sur le téléphone et
/// envoyée dans l'ordre de saisie au retour du réseau (voir OtSyncService).
class PendingOtQueue {
  static const String _boxName = 'pending_ot_actions';

  static Box<String>? _box;
  static int _lastId = 0;

  /// Toutes les actions en attente, dans l'ordre de saisie (compteur, badges, écran des envois).
  static final ValueNotifier<List<PendingOtAction>> actions = ValueNotifier(const []);

  /// Ouvre la file (à appeler après l'initialisation de Hive).
  static Future<void> load() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _publish();
    } catch (e) {
      if (kDebugMode) debugPrint('PendingOtQueue: ouverture impossible: $e');
    }
  }

  static bool isTemporaryCode(String otCode) => (int.tryParse(otCode) ?? 0) < 0;

  /// Code provisoire (négatif) d'un OT créé sans réseau.
  static int newTemporaryCode() => -(_nextId() % 1000000000);

  /// Identifiant croissant : l'ordre des clés est l'ordre de saisie.
  static int _nextId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastId = now > _lastId ? now : _lastId + 1;
    return _lastId;
  }

  static Future<PendingOtAction> enqueue(
    PendingOtKind kind,
    String otCode, {
    int? pk,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> baseline = const {},
    required String username,
  }) async {
    final action = PendingOtAction(
      id: _nextId().toString().padLeft(20, '0'),
      kind: kind,
      otCode: otCode,
      pk: pk,
      data: jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
      baseline: jsonDecode(jsonEncode(baseline)) as Map<String, dynamic>,
      username: username,
      createdAt: DateTime.now(),
    );
    await save(action);
    return action;
  }

  static Future<void> save(PendingOtAction action) async {
    await _box?.put(action.id, jsonEncode(action.toJson()));
    _publish();
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
    _publish();
  }

  static PendingOtAction? byId(String id) {
    final raw = _box?.get(id);
    return raw == null ? null : PendingOtAction.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// L'OT créé hors ligne existe maintenant dans Coswin : ses actions suivantes visent son vrai code.
  static Future<void> replaceCode(String temporary, String real) async {
    for (final action in all().where((a) => a.otCode == temporary)) {
      action.otCode = real;
      await _box?.put(action.id, jsonEncode(action.toJson()));
    }
    _publish();
  }

  static List<PendingOtAction> all() {
    final box = _box;
    if (box == null) return const [];
    final keys = box.keys.map((k) => k.toString()).toList()..sort();
    return keys.map(byId).whereType<PendingOtAction>().toList();
  }

  static List<PendingOtAction> forUser(String username) =>
      all().where((a) => a.username == username).toList();

  static bool hasPendingFor(String otCode) => actions.value.any((a) => a.otCode == otCode);

  static void _publish() => actions.value = all();
}
