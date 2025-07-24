import 'package:appmobilegmao/enums/statut.dart';

class Entity {
  String? id;
  String code;
  String nom;
  String? description;
  String? region;
  String? adresse;
  String? telephone;
  String? email;
  String? responsable;
  Statut statut;

  Entity({
    this.id,
    required this.code,
    required this.nom,
    this.description,
    this.region,
    this.adresse,
    this.telephone,
    this.email,
    this.responsable,
    required this.statut,
  });

  Entity.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      code = json['code'],
      nom = json['nom'],
      description = json['description'],
      region = json['region'],
      adresse = json['adresse'],
      telephone = json['telephone'],
      email = json['email'],
      responsable = json['responsable'],
      statut = Statut.values.firstWhere(
        (e) => e.toString() == 'Statut.${json['statut']}',
        orElse: () => Statut.Inactif,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'description': description,
      'region': region,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'responsable': responsable,
      'statut': statut.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'Entity(id: $id, code: $code, nom: $nom, description: $description, region: $region, adresse: $adresse, telephone: $telephone, email: $email, responsable: $responsable, statut: $statut)';
  }
}
