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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      entity: json['entity'] ?? '',
      group: json['group'] ?? '',
      urlImage: json['urlImage'] ?? '',
      isAbsent: json['isAbsent'] ?? '',
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
    };
  }

  @override
  String toString() {
    return 'User{id: $id, code: $code, username: $username, password: $password, email: $email, entity: $entity, group: $group, urlImage: $urlImage, isAbsent: $isAbsent}';
  }
}
