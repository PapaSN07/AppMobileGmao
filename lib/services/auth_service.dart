import 'package:appmobilegmao/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ApiService {
  Future<void> login(String username, String password) async {
    final response = await post('/auth/login', {
      'username': username,
      'password': password,
    });

    // Traiter la réponse de connexion
    if (response != null && response['token'] != null) {
      // Stocker le token d'authentification
      if (kDebugMode) {
        print('Authentification réussie pour $username');
      }
    } else {
      if (kDebugMode) {
        print('Échec de l\'authentification pour $username');
      }
    }
  }
}