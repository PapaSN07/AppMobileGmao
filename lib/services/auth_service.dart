import 'package:appmobilegmao/models/user_hive.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ApiService {
  final ApiService apiClient;

  AuthService({ApiService? apiClient}) : apiClient = apiClient ?? ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await apiClient.post('/api/v1/auth/login', data:  {
      'username': username,
      'password': password,
    });

    // Traiter la réponse de connexion
    if (response != null) {
      // Stocker le token d'authentification
      if (kDebugMode) {
        print('Authentification réussie pour $username');
      }
      return {
        'success': true,
        'data': UserHive.fromJson(response['data']),
        'message': 'Connexion réussie',
      };
    } else {
      if (kDebugMode) {
        print('Échec de l\'authentification pour $username');
      }
      return {
        'success': false,
        'message': 'Échec de la connexion',
      };
    }
  }

  Future<void> logout(String username) async {
    try {
      final response = await apiClient.post('/api/v1/auth/logout', data: {
        'username': username,
      });
      if (response != null && response['status'] == 'success') {
        if (kDebugMode) {
          print('Déconnexion réussie pour $username');
        }
      } else {
        if (kDebugMode) {
          print('Échec de la déconnexion pour $username');
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
      final response = await apiClient.patch('/api/v1/auth/profile', data: profileData);
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

  /// Vérifier si l'utilisateur est connecté
  bool isLoggedIn() {
    // Vérifier si un utilisateur est présent dans le cache
    final UserHive? cachedUser = HiveService.getCurrentUser();
    return cachedUser != null;
  }
}
