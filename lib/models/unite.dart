import 'package:appmobilegmao/enums/statut.dart';
import 'package:appmobilegmao/enums/type_unite.dart';
import 'package:appmobilegmao/models/entity.dart';

class Unite {
  String? id;
  String code;
  String description;
  TypeUnite type;
  Entity entity;
  String? responsable;
  String? telephone;
  List<String> equipementsTypes;
  Statut statut;

  Unite({
    this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.entity,
    this.responsable,
    this.telephone,
    required this.equipementsTypes,
    required this.statut,
  });

  factory Unite.fromJson(Map<String, dynamic> json) {
    return Unite(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      type: TypeUnite.values[json['type']],
      entity: Entity.fromJson(json['entity']),
      responsable: json['responsable'],
      telephone: json['telephone'],
      equipementsTypes: List<String>.from(json['equipementsTypes']),
      statut: Statut.values[json['statut']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'type': type.index,
      'entity': entity.toJson(),
      'responsable': responsable,
      'telephone': telephone,
      'equipementsTypes': equipementsTypes,
      'statut': statut.index,
    };
  }

  @override
  String toString() {
    return 'Unite(id: $id, code: $code, description: $description, type: $type, entity: $entity, responsable: $responsable, telephone: $telephone, equipementsTypes: $equipementsTypes, statut: $statut)';
  }
}
