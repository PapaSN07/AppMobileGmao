class AttributValue {
  final String nom;
  final String? valeurs;

  AttributValue({
    required this.nom,
    this.valeurs,
  });

  AttributValue.fromJson(Map<String, dynamic> json)
      : nom = json['nom'],
        valeurs = json['valeurs'];

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'valeurs': valeurs,
    };
  }

  @override
  String toString() {
    return 'AttributValue(nom: $nom, valeurs: $valeurs)';
  }
}
