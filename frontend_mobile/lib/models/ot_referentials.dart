/// Élément de référentiel Coswin (code + libellé).
class RefItem {
  final String code;
  final String description;

  /// Entité Coswin propriétaire (superviseurs, priorités), vide sinon.
  final String entity;

  const RefItem(this.code, this.description, {this.entity = ''});

  factory RefItem.fromJson(Map<String, dynamic> json) => RefItem(
        json['code']?.toString() ?? '',
        json['description']?.toString() ?? '',
        entity: json['entity']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        if (entity.isNotEmpty) 'entity': entity,
      };

  /// Libellé affiché : "DESCRIPTION (CODE)".
  String get label => description.isEmpty || description == code ? code : '$description ($code)';
}

/// Article du stock Coswin (référentiel /items).
class StockItem {
  final String code;
  final String description;
  final String unit;

  const StockItem(this.code, this.description, {this.unit = ''});

  /// Libellé affiché : "DESCRIPTION (UNITÉ)".
  String get label => unit.isEmpty ? description : '$description ($unit)';
}

/// Référentiels OT officiels chargés depuis Coswin.
class OTReferentials {
  final List<RefItem> jobTypes;
  final List<RefItem> jobClasses;
  final List<RefItem> priorities;
  final List<RefItem> statuses;
  final List<RefItem> supervisors;

  /// Code statut → statut système Coswin (0 créé, 1 en cours, 2 terminé, 3 archivable, 4 annulé).
  final Map<String, int> statusSystem;

  const OTReferentials({
    this.jobTypes = const [],
    this.jobClasses = const [],
    this.priorities = const [],
    this.statuses = const [],
    this.supervisors = const [],
    this.statusSystem = const {},
  });

  static const OTReferentials empty = OTReferentials();

  bool get isEmpty =>
      jobTypes.isEmpty && jobClasses.isEmpty && priorities.isEmpty && statuses.isEmpty && supervisors.isEmpty;

  static Set<String> codesOf(List<RefItem> items) => items.map((e) => e.code).toSet();

  static Map<String, String> toLabelMap(List<RefItem> items) => {for (final e in items) e.code: e.label};

  static List<RefItem> _list(dynamic raw) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(RefItem.fromJson).where((e) => e.code.isNotEmpty).toList()
      : const [];

  factory OTReferentials.fromJson(Map<String, dynamic> json) => OTReferentials(
        jobTypes: _list(json['jobTypes']),
        jobClasses: _list(json['jobClasses']),
        priorities: _list(json['priorities']),
        statuses: _list(json['statuses']),
        supervisors: _list(json['supervisors']),
        statusSystem: (json['statusSystem'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'jobTypes': jobTypes.map((e) => e.toJson()).toList(),
        'jobClasses': jobClasses.map((e) => e.toJson()).toList(),
        'priorities': priorities.map((e) => e.toJson()).toList(),
        'statuses': statuses.map((e) => e.toJson()).toList(),
        'supervisors': supervisors.map((e) => e.toJson()).toList(),
        'statusSystem': statusSystem,
      };
}
