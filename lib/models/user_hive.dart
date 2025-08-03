import 'package:hive/hive.dart';

part 'user_hive.g.dart';

@HiveType(typeId: 3)
class UserHive extends HiveObject {
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

  UserHive({
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

  factory UserHive.fromJson(Map<String, dynamic> json) {
    return UserHive(
      id: json['id'] as String,
      code: json['code'] as String?,
      username: json['username'] as String,
      password: json['password'] ?? '',
      email: json['email'] as String,
      entity: json['entity'] as String,
      group: json['group'] as String?,
      urlImage: json['urlImage'] as String?,
      isAbsent: json['isAbsent'] as String?,
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
