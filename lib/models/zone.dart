import 'package:hive_flutter/hive_flutter.dart';

part 'zone.g.dart'; // Génération automatique des fichiers Hive

@HiveType(typeId: 8)
class Zone extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String entity;

  Zone({
    required this.id,
    required this.code,
    required this.description,
    required this.entity,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
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
    return 'Zone{id: $id, code: $code, description: $description, entity: $entity}';
  }
}