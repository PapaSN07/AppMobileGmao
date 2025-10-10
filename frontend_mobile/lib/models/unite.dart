import 'package:hive/hive.dart';

part 'unite.g.dart';

@HiveType(typeId: 6)
class Unite extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String entity;

  Unite({
    required this.id,
    required this.code,
    required this.description,
    required this.entity,
  });

  factory Unite.fromJson(Map<String, dynamic> json) {
    return Unite(
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
    return 'Unite{id: $id, code: $code, description: $description, entity: $entity}';
  }
}