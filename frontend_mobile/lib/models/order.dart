import 'package:flutter/widgets.dart';

class Order {
  final String id;
  final IconData icon;
  final String code;
  final String famille;
  final String zone;
  final String entity;
  final String unite;
  final String centre;
  final String description;
  final String? status; // ✅ AJOUTÉ: Statut/État de l'OT
  final double? completionRate; // ✅ AJOUTÉ: Taux de réalisation de l'OT

  Order({
    required this.id,
    required this.icon,
    required this.code,
    required this.famille,
    required this.zone,
    required this.entity,
    required this.unite,
    required this.centre,
    required this.description,
    this.status, // ✅ AJOUTÉ
    this.completionRate, // ✅ AJOUTÉ
  });

  // ✅ AJOUTÉ: Formater le statut avec sa signification complète
  static String formatStatus(String statusAbbr, String? fullDescription) {
    final abbr = statusAbbr.trim().toUpperCase();
    if (fullDescription != null && fullDescription.trim().isNotEmpty) {
      return '${fullDescription.trim().toUpperCase()} ($abbr)';
    }
    switch (abbr) {
      case 'CR':
        return 'CRÉÉ (CR)';
      case 'OUV':
        return 'OUVERT (OUV)';
      case 'EC':
        return 'EN COURS (EC)';
      case 'CL':
        return 'CLÔTURÉ (CL)';
      case 'TE':
        return 'TERMINÉ (TE)';
      case 'SUSP':
        return 'SUSPENDU (SUSP)';
      default:
        return abbr;
    }
  }
}
