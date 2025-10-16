import 'package:hive/hive.dart';

part 'entity.g.dart';

@HiveType(typeId: 4)
class Entity extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String parentCategory;
  @HiveField(4)
  final String systemCategory;
  @HiveField(5)
  final String level;
  @HiveField(6)
  final String entity;

  Entity({
    required this.id,
    required this.code,
    required this.description,
    required this.parentCategory,
    required this.systemCategory,
    required this.level,
    required this.entity,
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      parentCategory: json['parent_category'] ?? '',
      systemCategory: json['system_category'] ?? '',
      level: json['level'] ?? '',
      entity: json['entity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'parent_category': parentCategory,
      'system_category': systemCategory,
      'level': level,
      'entity': entity,
    };
  }

  @override
  String toString() {
    return 'Entity{id: $id, code: $code, description: $description, parentCategory: $parentCategory, systemCategory: $systemCategory, level: $level, entity: $entity}';
  }
}