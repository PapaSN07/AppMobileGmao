import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? code;
  @HiveField(2)
  final String username;
  @HiveField(3)
  final String? password;
  @HiveField(4)
  final String email;
  @HiveField(5)
  final String entity;
  @HiveField(6)
  final String? group;
  @HiveField(7)
  final String? urlImage;
  @HiveField(8)
  final String? isAbsent;
  @HiveField(9)
  final String? role;

  User({
    required this.id,
    this.code,
    required this.username,
    this.password,
    required this.email,
    required this.entity,
    this.group,
    this.urlImage,
    this.isAbsent,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      entity: json['entity'] ?? '',
      group: json['group'] ?? '',
      urlImage: json['urlImage'] ?? '',
      isAbsent: json['isAbsent'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'username': username,
      'password': password,
      'email': email,
      'entity': entity,
      'group': group,
      'urlImage': urlImage,
      'isAbsent': isAbsent,
      'role': role,
    };
  }

  /// Formate le nom complet (Prénom + Nom) proprement
  String get displayName {
    if (username.isEmpty) return 'Utilisateur';
    final parts = username.split(RegExp(r'[.\s_-]+'));
    if (parts.length >= 2) {
      final prenom = _capitalize(parts.first);
      final nom = _capitalize(parts.sublist(1).join(' '));
      return '$prenom $nom';
    } else {
      return _capitalize(username);
    }
  }

  /// Formate le rôle de manière lisible
  String get displayRole {
    final r = (role ?? group ?? '').trim();
    if (r.isEmpty) return 'Utilisateur';
    final rUpper = r.toUpperCase();
    if (rUpper == 'ADMIN' || rUpper == 'SUPERVISOR') return 'Administrateur';
    if (rUpper == 'CONTREMAITRE' || rUpper.contains('CONT')) return 'Contremaître';
    if (rUpper == 'CHEF_UNITE' || rUpper.contains('CHEF')) return "Chef d'Unité";
    if (rUpper == 'USER') return 'Agent';
    return _capitalize(r.replaceAll('_', ' '));
  }

  /// Chaîne combinée Rôle & Entité pour l'affichage UI
  String get subtitleInfo {
    final r = displayRole;
    final e = entity.trim();
    if (e.isNotEmpty && e != 'SENELEC') {
      return '$r • $e';
    }
    return r;
  }

  static String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  String toString() {
    return 'User{id: $id, code: $code, username: $username, password: $password, email: $email, entity: $entity, group: $group, urlImage: $urlImage, isAbsent: $isAbsent, role: $role}';
  }
}
