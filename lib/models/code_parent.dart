import 'package:appmobilegmao/enums/statut.dart';

class CodeParent {
  String? id;
  String code;
  String? description;
  String? zone;
  String type;
  String niveau;
  Statut statut;

  CodeParent({
    this.id,
    required this.code,
    this.description,
    this.zone,
    required this.type,
    required this.niveau,
    required this.statut,
  });

  CodeParent.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      code = json['code'],
      description = json['description'],
      zone = json['zone'],
      type = json['type'],
      niveau = json['niveau'],
      statut = Statut.values.firstWhere(
        (e) => e.toString() == 'Statut.${json['statut']}',
        orElse: () => Statut.Inactif,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'zone': zone,
      'type': type,
      'niveau': niveau,
      'statut': statut.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'CodeParent{id: $id, code: $code, description: $description, zone: $zone, type: $type, niveau: $niveau, statut: $statut}';
  }
}
