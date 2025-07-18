import 'package:appmobilegmao/models/attribut_value.dart';

class Attribut {
  final String nom;
  final List<AttributValue>? valeurs;

  Attribut({required this.nom, this.valeurs = const []});

  Attribut.fromJson(Map<String, dynamic> json)
    : nom = json['nom'],
      valeurs =
          (json['valeurs'] as List?)
              ?.map((item) => AttributValue.fromJson(item))
              .toList();

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'valeurs': valeurs?.map((value) => value.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Attribut(nom: $nom, valeurs: $valeurs)';
  }
}
