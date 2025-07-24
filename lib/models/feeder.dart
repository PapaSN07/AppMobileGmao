import 'package:appmobilegmao/enums/statut.dart';

class Feeder {
  String? id;
  String code;
  String nom;
  String? description;
  String? codeParent;
  String zone;
  String tension;
  String longueur;
  String type;
  Statut statut;


  Feeder({
    this.id,
    required this.code,
    required this.nom,
    this.description,
    this.codeParent,
    required this.zone,
    required this.tension,
    required this.longueur,
    required this.type,
    required this.statut,
  });

  Feeder.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        code = json['code'],
        nom = json['nom'],
        description = json['description'],
        codeParent = json['codeParent'],
        zone = json['zone'],
        tension = json['tension'],
        longueur = json['longueur'],
        type = json['type'],
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
      'codeParent': codeParent,
      'zone': zone,
      'tension': tension,
      'longueur': longueur,
      'type': type,
      'statut': statut.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'Feeder{id: $id, code: $code, nom: $nom, description: $description, codeParent: $codeParent, zone: $zone, tension: $tension, longueur: $longueur, type: $type, statut: $statut}';
  }
}
