import 'package:hive/hive.dart';

part 'equipment_attribute.g.dart';

@HiveType(typeId: 9)
class EquipmentAttribute extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? specification;

  @HiveField(2)
  String? index;

  @HiveField(3)
  String? name;

  @HiveField(4)
  String? value;

  EquipmentAttribute({
    this.id,
    this.specification,
    this.index,
    this.name,
    this.value,
  });

  factory EquipmentAttribute.fromJson(Map<String, dynamic> json) {
    return EquipmentAttribute(
      id: json['id']?.toString(),
      specification: json['specification']?.toString(),
      index: json['index']?.toString(),
      name: json['name']?.toString(),
      value: json['value']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specification': specification,
      'index': index,
      'name': name,
      'value': value,
    };
  }

  /// Helper pour vérifier si l'attribut a une valeur
  bool hasValue() {
    return value != null && value!.trim().isNotEmpty;
  }

  /// Helper pour obtenir l'index numérique
  int get numericIndex {
    return int.tryParse(index ?? '0') ?? 0;
  }

  @override
  String toString() {
    return 'EquipmentAttribute{id: $id, name: $name, value: $value, index: $index}';
  }
}
