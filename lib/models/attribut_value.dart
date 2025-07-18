class AttributValue {
  String? id;
  String code;
  String? description;

  AttributValue({
    this.id,
    required this.code,
    this.description,
  });

  AttributValue.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        code = json['code'],
        description = json['description'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'AttributValue(id: $id, code: $code, description: $description)';
  }
}
