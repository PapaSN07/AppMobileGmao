import 'package:hive/hive.dart';

part 'equipment_hive.g.dart';

@HiveType(typeId: 0)
class EquipmentHive extends HiveObject {
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
  List<AttributeValueHive> attributs;

  @HiveField(14)
  DateTime cachedAt;

  @HiveField(15)
  bool isSync;

  EquipmentHive({
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
}

@HiveType(typeId: 1)
class AttributeValueHive extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? value;

  @HiveField(2)
  String? type;

  AttributeValueHive({this.name, this.value, this.type});
}

@HiveType(typeId: 2)
class ReferenceDataHive extends HiveObject {
  @HiveField(0)
  List<String> zones;

  @HiveField(1)
  List<String> familles;

  @HiveField(2)
  List<String> entities;

  @HiveField(3)
  DateTime lastSync;

  @HiveField(4)
  String cacheVersion;

  ReferenceDataHive({
    required this.zones,
    required this.familles,
    required this.entities,
    DateTime? lastSync,
    this.cacheVersion = '1.0',
  }) : lastSync = lastSync ?? DateTime.now();
}
