class AttributValue {
  String? name;
  String? value;
  String? type;

  AttributValue({this.name, this.value, this.type});

  factory AttributValue.fromJson(Map<String, dynamic> json) {
    return AttributValue(
      name: json['name'],
      value: json['value'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value, 'type': type};
  }
}