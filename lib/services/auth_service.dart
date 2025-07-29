import 'package:appmobilegmao/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ApiService {
  final ApiService apiClient;

  AuthService({ApiService? apiClient}) : apiClient = apiClient ?? ApiService();

  Future<void> login(String username, String password) async {
    final response = await apiClient.post('/auth/login', data:  {
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

  Future<void> logout() async {
    try {
      final response = await apiClient.post('/auth/logout');
      if (response != null && response['success'] == true) {
        if (kDebugMode) {
          print('Déconnexion réussie');
        }
      } else {
        if (kDebugMode) {
          print('Échec de la déconnexion');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion : $e');
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await apiClient.patch('/auth/profile', data: profileData);
      if (response != null && response['success'] == true) {
        if (kDebugMode) {
          print('Profil mis à jour avec succès');
        }
      } else {
        if (kDebugMode) {
          print('Échec de la mise à jour du profil');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du profil : $e');
      }
    }
  }
}
