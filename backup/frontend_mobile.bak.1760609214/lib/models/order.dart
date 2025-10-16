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
  });
}
