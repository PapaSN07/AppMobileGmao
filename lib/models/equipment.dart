import 'package:appmobilegmao/models/attribut_value.dart';

class Equipment {
  String? id;
  String? codeParent;
  String? feeder;
  String? feederDescription;
  String code;
  String famille;
  String zone;
  String entity;
  String unite;
  String centreCharge;
  String description;
  String longitude;
  String latitude;
  List<AttributValue> attributs;

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
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id']?.toString(),
      codeParent: json['codeParent'],
      feeder: json['feeder'],
      feederDescription: json['feederDescription'],
      code: json['code'] ?? '',
      famille: json['famille'] ?? '',
      zone: json['zone'] ?? '',
      entity: json['entity'] ?? '',
      unite: json['unite'] ?? '',
      centreCharge: json['centreCharge'] ?? '',
      description: json['description'] ?? '',
      longitude: json['longitude']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      attributs:
          (json['attributs'] as List?)
              ?.map((attr) => AttributValue.fromJson(attr))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeParent': codeParent,
      'feeder': feeder,
      'feederDescription': feederDescription,
      'code': code,
      'famille': famille,
      'zone': zone,
      'entity': entity,
      'unite': unite,
      'centreCharge': centreCharge,
      'description': description,
      'longitude': longitude,
      'latitude': latitude,
      'attributs': attributs.map((attr) => attr.toJson()).toList(),
    };
  }
}
