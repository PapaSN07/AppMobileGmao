import 'dart:async';
import 'dart:io';

import 'package:appmobilegmao/models/user.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/connectivity_service.dart';
import 'package:appmobilegmao/services/offline_credentials.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final ApiService apiClient;
  final OfflineCredentials _offline;
  final Future<bool> Function() _hasNetwork;

  static const String __prefixURI = '/api/v1/auth';

  AuthService({ApiService? apiClient, OfflineCredentials? offline, Future<bool> Function()? hasNetwork})
      : apiClient = apiClient ?? ApiService(),
        _offline = offline ?? OfflineCredentials(),
        _hasNetwork = hasNetwork ?? ConnectivityService().isConnected;

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Téléphone sans réseau : vérification immédiate sur le téléphone, sans attendre le délai du serveur
    if (!await _networkAvailable()) {
      return _offlineOrFailure(username, password, "Pas de connexion internet.");
    }
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
        // Permet une connexion hors ligne ultérieure sur ce téléphone (empreinte, pas le mot de passe)
        await _offline.remember(username, password, user.toJson());

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
      // Requête bloquée par le pare-feu : serveur injoignable, pas un mauvais mot de passe
      if (e.firewallBlocked) {
        return _offlineOrFailure(username, password, e.message);
      }
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

      // ✅ Si erreur réseau ou service indisponible (0, null, 503)
      if (e.statusCode == null || e.statusCode == 0 || e.statusCode == 503) {
        return _offlineOrFailure(
          username,
          password,
          e.message.isNotEmpty ? e.message : "Impossible de joindre le serveur Senelec. Vérifiez votre connexion internet.",
        );
      }

      return _failureResponse("Erreur serveur : ${e.message}");
    } on SocketException {
      return _offlineOrFailure(username, password, "Impossible de joindre le serveur. Vérifiez votre connexion internet.");
    } on TimeoutException {
      return _offlineOrFailure(username, password, "Le serveur met trop de temps à répondre. Veuillez réessayer.");
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Erreur inattendue durant login: $e');
      }
      return _failureResponse("Erreur lors de la connexion");
    }
  }

  /// Serveur injoignable : connexion hors ligne si ce téléphone a déjà connecté cet utilisateur
  /// avec ce mot de passe ; sinon, le message d'erreur réseau.
  Future<Map<String, dynamic>> _offlineOrFailure(String username, String password, String networkMessage) async {
    try {
      final userJson = await _offline.verify(username, password);
      if (userJson == null) {
        return _failureResponse(
          '$networkMessage\nSans réseau, il faut le même mot de passe que lors de la dernière connexion '
          'en ligne sur ce téléphone (avec cette version de l\'application).',
        );
      }
      final user = User.fromJson(userJson);
      await HiveService.cacheCurrentUser(user);
      return {
        'success': true,
        'offline': true,
        'data': user,
        'message': 'Connexion hors ligne',
      };
    } catch (e) {
      if (kDebugMode) print('❌ AuthService: connexion hors ligne impossible: $e');
      return _failureResponse('$networkMessage\nLa connexion hors ligne a échoué sur ce téléphone.');
    }
  }

  Future<bool> _networkAvailable() async {
    try {
      return await _hasNetwork();
    } catch (_) {
      return true; // En cas de doute, on tente le serveur
    }
  }

  Map<String, dynamic> _failureResponse(String message) {
    return {
      'success': false,
      'message': message,
    };
  }

  Future<void> logout(String username) async {
    try {
      final response = await apiClient.post(
        '$__prefixURI/logout',
        data: {'username': username},
      ).whenComplete(() async {
        // Même sans réseau, les jetons sont effacés : sinon l'application se rouvrirait connectée
        await HiveService.clearTokens();
        apiClient.clearAuthToken();
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
