class Attribut {
  String? id;
  String code;
  String? description;

  Attribut({
    this.id,
    required this.code,
    this.description,
  });

  Attribut.fromJson(Map<String, dynamic> json)
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
    return 'Attribut(id: $id, code: $code, description: $description)';
  }
}
