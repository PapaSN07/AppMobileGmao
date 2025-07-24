class Famille {
  String? id;
  String nom;
  String? description;

  Famille({this.id, required this.nom, this.description});

  Famille.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nom = json['nom'],
      description = json['description'];

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'description': description};
  }

  @override
  String toString() {
    return 'Famille(id: $id, nom: $nom, description: $description)';
  }
}
