import 'package:hive/hive.dart';

part 'equipment.g.dart';

@HiveType(typeId: 0)
class Equipment extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? codeParent;

  @HiveField(2)
  String? feeder;

  @HiveField(3)
  String? feederDescription;

  @HiveField(4)
  String code;

  @HiveField(5)
  String famille;

  @HiveField(6)
  String zone;

  @HiveField(7)
  String entity;

  @HiveField(8)
  String unite;

  @HiveField(9)
  String centreCharge;

  @HiveField(10)
  String description;

  @HiveField(11)
  String longitude;

  @HiveField(12)
  String latitude;

  @HiveField(13)
  List<AttributeValue> attributs;

  @HiveField(14)
  DateTime cachedAt;

  @HiveField(15)
  bool isSync;

  Equipment({
    this.id,
    this.codeParent,
    this.feeder,
    this.feederDescription,
    required this.code,
    required this.famille,
    required this.zone,
    required this.entity,
    required this.unite,
    required this.centreCharge,
    required this.description,
    required this.longitude,
    required this.latitude,
    this.attributs = const [],
    DateTime? cachedAt,
    this.isSync = false,
  }) : cachedAt = cachedAt ?? DateTime.now();

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      codeParent: json['codeParent'] ?? '',
      feeder: json['feeder'] ?? '',
      feederDescription: json['feederDescription'] ?? '',
      code: json['code'] ?? '',
      famille: json['famille'] ?? '',
      zone: json['zone'] ?? '',
      entity: json['entity'] ?? '',
      unite: json['unite'] ?? '',
      centreCharge: json['centreCharge'] ?? '',
      description: json['description'] ?? '',
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      attributs:
          (json['attributs'] != null && json['attributs'] is List<dynamic>)
              ? (json['attributs'] as List<dynamic>)
                  .map((e) => AttributeValue.fromJson(e))
                  .toList()
              : [], // Retourne une liste vide si `attributs` est null
      cachedAt:
          json['cached_at'] != null
              ? DateTime.parse(json['cached_at'])
              : DateTime.now(),
      isSync: json['is_sync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code_parent': codeParent,
      'feeder': feeder,
      'feeder_description': feederDescription,
      'code': code,
      'famille': famille,
      'zone': zone,
      'entity': entity,
      'unite': unite,
      'centre_charge': centreCharge,
      'description': description,
      'longitude': longitude,
      'latitude': latitude,
      'attributs': attributs.map((e) => e.toJson()).toList(),
      'cached_at': cachedAt.toIso8601String(),
      'is_sync': isSync,
    };
  }

  @override
  String toString() {
    return 'Equipment{id: $id, codeParent: $codeParent, feeder: $feeder, feederDescription: $feederDescription, code: $code, famille: $famille, zone: $zone, entity: $entity, unite: $unite, centreCharge: $centreCharge, description: $description, longitude: $longitude, latitude: $latitude, attributs: $attributs, cachedAt: $cachedAt, isSync: $isSync}';
  }
}

@HiveType(typeId: 1)
class AttributeValue extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? value;

  @HiveField(2)
  String? type;

  AttributeValue({this.name, this.value, this.type});

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      name: json['name'] as String?,
      value: json['value'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'type': type};
  }

  @override
  String toString() {
    return 'AttributeValue{name: $name, value: $value, type: $type}';
  }
}
