import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // URL de base adaptée selon la plateforme
  late String baseUrl;

  // Timeout pour les requêtes HTTP
  static const Duration timeout = Duration(seconds: 30);

  // Port par défaut de JSON Server
  static const int defaultPort = 3000;

  // Adresse IP de l'ordinateur pour les appareils iOS physiques
  static const String _macIpAddress = '169.254.208.98';

  ApiService() {
    _initializeBaseUrl();
  }

  /// Initialise l'URL de base selon la plateforme
  void _initializeBaseUrl() {
    if (kIsWeb) {
      // Pour le web
      baseUrl = 'http://localhost:$defaultPort';
    } else if (Platform.isAndroid) {
      // Pour Android (émulateur)
      baseUrl = 'http://10.0.2.2:$defaultPort';
    } else if (Platform.isIOS) {
      // Détecter si on est sur simulateur ou appareil physique
      if (_isSimulator()) {
        baseUrl = 'http://localhost:$defaultPort';
      } else {
        // Appareil physique iOS
        baseUrl = 'http://$_macIpAddress:$defaultPort';
      }
    } else {
      // Fallback pour autres plateformes
      baseUrl = 'http://localhost:$defaultPort';
    }

    if (kDebugMode) {
      print(
        '🌐 Base URL configurée: $baseUrl (Plateforme: ${_getPlatformName()})',
      );
    }
  }

  // Méthode pour détecter si on est sur simulateur
  static bool _isSimulator() {
    // Cette méthode n'est pas parfaite, mais fonctionne dans la plupart des cas
    return Platform.environment['SIMULATOR_DEVICE_NAME'] != null;
  }

  /// Retourne le nom de la plateforme actuelle
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Inconnue';
  }

  /// Permet de changer le port manuellement si nécessaire
  void setPort(int port) {
    if (kIsWeb) {
      baseUrl = 'http://localhost:$port';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:$port';
    } else if (Platform.isIOS) {
      baseUrl = 'http://localhost:$port';
    } else {
      baseUrl = 'http://localhost:$port';
    }

    if (kDebugMode) {
      print('🔄 Base URL mise à jour: $baseUrl');
    }
  }

  /// Permet de définir une URL personnalisée (pour production)
  void setCustomBaseUrl(String url) {
    baseUrl = url;
    if (kDebugMode) {
      print('🔧 URL personnalisée définie: $baseUrl');
    }
  }

  Future<void> init() async {
    // Test de connectivité au démarrage
    await _testConnection();
  }

  /// Teste la connexion au serveur
  Future<bool> _testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Connexion au serveur réussie');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Impossible de se connecter au serveur: $e');
        print(
          '💡 Assurez-vous que JSON Server est démarré sur le port $defaultPort',
        );
      }
    }
    return false;
  }

  /// Méthode pour obtenir les en-têtes de la requête
  Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Ajouter le User-Agent pour identifier la plateforme
    headers['User-Agent'] = 'Flutter-${_getPlatformName()}';

    return headers;
  }

  /// Méthode pour traiter la réponse de l'API
  Future<dynamic> _processResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      throw Exception(
        'Erreur de l\'API: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();

    // Nettoie l'endpoint pour éviter les problèmes de double slash
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    try {
      final url = '$baseUrl/$endpoint';
      if (kDebugMode) {
        print('🔍 GET: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            timeout,
            onTimeout:
                () =>
                    throw Exception(
                      'Délai d\'attente dépassé pour la requête GET $endpoint',
                    ),
          );

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur GET: $e');
        _printConnectionHelp();
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();

    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    try {
      final url = '$baseUrl/$endpoint';
      if (kDebugMode) {
        print('📤 POST: $url');
        print('📦 Données: ${jsonEncode(data)}');
      }

      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(data))
          .timeout(
            timeout,
            onTimeout: () => throw Exception('Délai d\'attente dépassé'),
          );

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur POST: $e');
        _printConnectionHelp();
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();

    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    try {
      final url = '$baseUrl/$endpoint';
      if (kDebugMode) {
        print('🔄 PUT: $url');
        print('📦 Données: ${jsonEncode(data)}');
      }

      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(data))
          .timeout(
            timeout,
            onTimeout: () => throw Exception('Délai d\'attente dépassé'),
          );

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur PUT: $e');
        _printConnectionHelp();
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();

    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    try {
      final url = '$baseUrl/$endpoint';
      if (kDebugMode) {
        print('🗑️ DELETE: $url');
      }

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(
            timeout,
            onTimeout: () => throw Exception('Délai d\'attente dépassé'),
          );

      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur DELETE: $e');
        _printConnectionHelp();
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Affiche des conseils de connexion en cas d'erreur
  void _printConnectionHelp() {
    if (kDebugMode) {
      print('');
      print('🛠️  AIDE À LA CONNEXION:');
      print('📱 Plateforme détectée: ${_getPlatformName()}');
      print('🌐 URL utilisée: $baseUrl');
      print('');
      print('📋 Instructions pour démarrer JSON Server:');
      print('   json-server --watch db.json --port $defaultPort');
      print('');
      if (Platform.isAndroid) {
        print(
          '🤖 Pour Android: Utilisation de 10.0.2.2 (bridge réseau émulateur)',
        );
      } else if (Platform.isIOS) {
        print('🍎 Pour iOS: Utilisation de localhost (simulateur)');
      }
      print('');
    }
  }
}
