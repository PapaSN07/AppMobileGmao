class User {
  final String? id;
  final String? nom;
  final String email;
  final String password;

  User({this.id, this.nom, required this.email, required this.password});

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nom = json['nom'],
      email = json['email'],
      password = json['password'];

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'email': email, 'password': password};
  }

  @override
  String toString() {
    return 'User(id: $id, nom: $nom, email: $email, password: $password)';
  }
}
