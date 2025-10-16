import 'package:hive/hive.dart';

part 'attribute_value.g.dart';

@HiveType(typeId: 1)
class AttributeValue {
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? value;

  AttributeValue({this.id, this.value});

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: json['id']?.toString(),
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }

  @override
  String toString() {
    return 'AttributValue{id: $id, value: $value}';
  }
}
