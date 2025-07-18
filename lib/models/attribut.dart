class Attribut {
  final String nom;
  final String valeur;

  Attribut({required this.nom, required this.valeur});

  Attribut.fromJson(Map<String, dynamic> json)
    : nom = json['nom'],
      valeur = json['valeur'];

  Map<String, dynamic> toJson() {
    return {'nom': nom, 'valeur': valeur};
  }

  @override
  String toString() {
    return 'Attribut(nom: $nom, valeur: $valeur)';
  }
}
