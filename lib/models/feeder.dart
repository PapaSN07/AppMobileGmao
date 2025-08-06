import 'package:hive/hive.dart';

part 'feeder.g.dart';

@HiveType(typeId: 7)
class Feeder extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String entity;

  Feeder({
    required this.id,
    required this.code,
    required this.description,
    required this.entity,
  });

  factory Feeder.fromJson(Map<String, dynamic> json) {
    return Feeder(
      id: json['id'] ?? '',
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
    return 'Feeder{id: $id, code: $code, description: $description, entity: $entity}';
  }
}