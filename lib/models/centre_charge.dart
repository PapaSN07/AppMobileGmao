import 'package:appmobilegmao/enums/statut.dart';
import 'package:appmobilegmao/models/entity.dart';
import 'package:appmobilegmao/models/unite.dart';

class CentreCharge {
  String? id;
  String code;
  String nom;
  String? description;
  String? zone;
  Entity entity;
  Unite unite;
  String? adresse;
  String? responsable;
  String? telephone;
  String? capacite;
  Statut statut;

  CentreCharge({
    this.id,
    required this.code,
    required this.nom,
    this.description,
    this.zone,
    required this.entity,
    required this.unite,
    this.adresse,
    this.responsable,
    this.telephone,
    this.capacite,
    required this.statut,
  });

  CentreCharge.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      code = json['code'],
      nom = json['nom'],
      description = json['description'],
      zone = json['zone'],
      entity = Entity.fromJson(json['entity']),
      unite = Unite.fromJson(json['unite']),
      adresse = json['adresse'],
      responsable = json['responsable'],
      telephone = json['telephone'],
      capacite = json['capacite'],
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
      'zone': zone,
      'entity': entity.toJson(),
      'unite': unite.toJson(),
      'adresse': adresse,
      'responsable': responsable,
      'telephone': telephone,
      'capacite': capacite,
      'statut': statut.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'CentreCharge(id: $id, code: $code, nom: $nom, description: $description, zone: $zone, entity: $entity, unite: $unite, adresse: $adresse, responsable: $responsable, telephone: $telephone, capacite: $capacite, statut: $statut)';
  }
}
