import 'package:hive/hive.dart';

part 'centre_charge.g.dart';

@HiveType(typeId: 5)
class CentreCharge extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String entity;

  CentreCharge({
    required this.id,
    required this.code,
    required this.description,
    required this.entity,
  });

  factory CentreCharge.fromJson(Map<String, dynamic> json) {
    return CentreCharge(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      entity: json['entity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'entity': entity,
    };
  }

  @override
  String toString() {
    return 'CentreCharge{id: $id, code: $code, description: $description, entity: $entity}';
  }
}