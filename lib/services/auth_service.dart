import 'dart:io';

import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiService apiClient;

  AuthService({ApiService? apiClient}) : apiClient = apiClient ?? ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await apiClient.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      );

      // ✅ Cas succès
      if (response != null && response['success'] == true) {
        if (kDebugMode) {
          print('Authentification réussie pour $username');
        }
        return {
          'success': response['success'],
          'data': User.fromJson(response['data']),
          'message': response['message'],
        };
      }

      // ✅ Cas échec authentification (mauvais identifiants)
      if (response != null && response['success'] == false) {
        return {
          'success': false,
          'message':
              response['message'] ??
              "Nom d'utilisateur ou mot de passe incorrect",
        };
      }

      // ✅ Cas backend répond mais erreur connue (ex: FastAPI retourne detail)
      if (response != null && response['detail'] != null) {
        return {'success': false, 'message': response['detail']};
      }

      // Cas inconnu
      return {
        'success': false,
        'message': "Erreur inconnue lors de la connexion",
      };
    } on ApiException catch (e) {
      // ✅ Si erreur 401 ou 403 => mauvais identifiants
      if (e.statusCode == 401 || e.statusCode == 403) {
        return {
          'success': false,
          'message': "Nom d'utilisateur ou mot de passe incorrect",
        };
      }
      // ✅ Si erreur 400 avec message d'authentification
      if (e.statusCode == 400 && e.message.contains("authentification")) {
        return {
          'success': false,
          'message': "Nom d'utilisateur ou mot de passe incorrect",
        };
      }
      // ✅ Si erreur 500 avec message d'authentification
      if (e.statusCode == 500 && e.message.contains("authentification")) {
        return {
          'success': false,
          'message': "Nom d'utilisateur ou mot de passe incorrect",
        };
      }
      // Sinon, vraie erreur serveur
      return {'success': false, 'message': "Erreur serveur : ${e.message}"};
    } on SocketException {
      return {
        'success': false,
        'message':
            "Connexion impossible au serveur. Vérifiez votre connexion internet ou que le serveur est démarré.",
      };
    } catch (e) {
      return {
        'success': false,
        'message': "Erreur inattendue : ${e.toString()}",
      };
    }
  }

  Future<void> logout(String username) async {
    try {
      final response = await apiClient.post(
        '/api/v1/auth/logout',
        data: {'username': username},
      );
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
      final response = await apiClient.patch(
        '/api/v1/auth/profile',
        data: profileData,
      );
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
    final User? cachedUser = HiveService.getCurrentUser();
    return cachedUser != null;
  }
}
