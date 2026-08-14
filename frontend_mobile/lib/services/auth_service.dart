import 'dart:async';
import 'dart:io';

import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final ApiService apiClient;

  static const String __prefixURI = '/api/v1/auth';

  AuthService({ApiService? apiClient}) : apiClient = apiClient ?? ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await apiClient.post(
        '$__prefixURI/login',
        data: {'username': username, 'password': password},
      );

      // ✅ Cas succès
      if (response != null && response['success'] == true) {
        if (kDebugMode) {
          print('Authentification réussie pour $username');
        }

        final user = User.fromJson(response['data']);
        await HiveService.cacheCurrentUser(user);

        // ✅ Sauvegarder les tokens JWT
        final accessToken = response['access_token'];
        final refreshToken = response['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          await HiveService.saveTokens(accessToken, refreshToken);

          // Configurer le token dans ApiService
          apiClient.setAuthToken(accessToken);

          if (kDebugMode) {
            print('✅ Tokens JWT sauvegardés');
          }
        }

        return {
          'success': response['success'],
          'data': user,
          'message': response['message'],
        };
      }

      // ✅ Cas échec authentification (mauvais identifiants)
      if (response != null && response['success'] == false) {
        return _failureResponse(
          response['message'] ??
              "Nom d'utilisateur ou mot de passe incorrect",
        );
      }

      // ✅ Cas backend répond mais erreur connue (ex: FastAPI retourne detail)
      if (response != null && response['detail'] != null) {
        final detailMessage = response['detail'] is String
            ? response['detail']
            : (response['detail']['message'] ?? "Erreur d'authentification");
        return _failureResponse(detailMessage);
      }

      // Cas inconnu
      return _failureResponse("Erreur inconnue lors de la connexion");
    } on ApiException catch (e) {
      // ✅ Si erreur 401 ou 403 => mauvais identifiants
      if (e.statusCode == 401 || e.statusCode == 403) {
        return _failureResponse("Nom d'utilisateur ou mot de passe incorrect");
      }
      // ✅ Si erreur 400 avec message d'authentification
      if (e.statusCode == 400 && e.message.contains("authentification")) {
        return _failureResponse("Nom d'utilisateur ou mot de passe incorrect");
      }

      // ✅ Erreurs serveur (500, 502, 504) => ne pas passer en fallback hors-ligne
      if (e.statusCode != null && e.statusCode! >= 500 && e.statusCode != 503) {
        if (e.message.contains("authentification")) {
          return _failureResponse("Nom d'utilisateur ou mot de passe incorrect");
        }
        return _failureResponse("Erreur serveur (${e.statusCode}). Veuillez réessayer plus tard.");
      }

      // ✅ Si erreur réseau ou service indisponible (0, null, 503) => mode hors-ligne
      if (e.statusCode == null || e.statusCode == 0 || e.statusCode == 503) {
        return _offlineLoginFallback(username, password);
      }

      return _failureResponse("Erreur serveur : ${e.message}");
    } on SocketException {
      return _offlineLoginFallback(username, password);
    } on TimeoutException {
      return _offlineLoginFallback(username, password);
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Erreur inattendue durant login: $e');
      }
      return _failureResponse("Erreur lors de la connexion");
    }
  }

  Map<String, dynamic> _failureResponse(String message) {
    return {
      'success': false,
      'message': message,
    };
  }

  Map<String, dynamic> _offlineLoginFallback(String username, String password) {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      return _failureResponse(
        "Veuillez saisir un nom d'utilisateur et un mot de passe.",
      );
    }

    // Récupérer l'utilisateur stocké lors d'une précédente connexion en ligne réussie
    final User? cachedUser = HiveService.getCurrentUser();

    if (cachedUser != null &&
        cachedUser.username.toLowerCase() == cleanUsername.toLowerCase()) {
      if (kDebugMode) {
        print('✅ Connexion hors-ligne réussie pour ${cachedUser.username}');
      }
      return {
        'success': true,
        'data': cachedUser,
        'message': 'Connexion réussie (mode hors-ligne)',
      };
    }

    return _failureResponse(
      "Mode hors-ligne : Cet utilisateur n'est pas enregistré sur cet appareil.",
    );
  }

  Future<void> logout(String username) async {
    try {
      final response = await apiClient.post(
        '$__prefixURI/logout',
        data: {'username': username},
      );

      // ✅ NOUVEAU: Supprimer les tokens
      await HiveService.clearTokens();
      apiClient.clearAuthToken();

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

  // ✅ NOUVEAU: Rafraîchir le token JWT
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await HiveService.getRefreshToken();

      if (refreshToken == null) {
        if (kDebugMode) {
          print('❌ Aucun refresh token disponible');
        }
        return false;
      }

      final response = await apiClient.post(
        '$__prefixURI/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response != null && response['access_token'] != null) {
        final newAccessToken = response['access_token'];
        await HiveService.saveAccessToken(newAccessToken);
        apiClient.setAuthToken(newAccessToken);

        if (kDebugMode) {
          print('✅ Token JWT rafraîchi avec succès');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du rafraîchissement du token: $e');
      }
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await apiClient.patch(
        '$__prefixURI/profile',
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
