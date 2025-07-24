class Zone {
  String? id;
  String nom;
  String region;
  String responsable;

  Zone({
    this.id,
    required this.nom,
    required this.region,
    required this.responsable,
  });

  Zone.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nom = json['nom'],
      region = json['region'],
      responsable = json['responsable'];

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'region': region, 'responsable': responsable};
  }

  @override
  String toString() {
    return 'Zone(id: $id, nom: $nom, region: $region, responsable: $responsable)';
  }
}
