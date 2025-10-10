import 'dart:io';

import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() {
    if (statusCode != null && endpoint != null) {
      return 'ApiException ($statusCode): $message [Endpoint: $endpoint]';
    }
    return 'ApiException: $message';
  }
}

/// Service API de base utilisant Dio pour toute l'application
class ApiService {
  late final Dio _dio;
  late String baseUrl;

  // ✅ NOUVEAU: Variable pour stocker le token
  String? _authToken;

  // Configuration par défaut
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
  static const int defaultPort = 8000;
  static const String _macIpAddress = '172.16.11.71';

  ApiService({int? port, String? customBaseUrl}) {
    if (customBaseUrl != null) {
      baseUrl = customBaseUrl;
    } else {
      _initializeBaseUrl(port ?? defaultPort);
    }
    _initializeDio();
    _loadAuthToken(); // ✅ NOUVEAU: Charger le token au démarrage
  }

  // ✅ NOUVEAU: Charger le token depuis Hive
  Future<void> _loadAuthToken() async {
    _authToken = await HiveService.getAccessToken();
    if (_authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_authToken';
      if (kDebugMode) {
        print('🔑 Token JWT chargé depuis le cache');
      }
    }
  }

  // ✅ NOUVEAU: Définir le token d'authentification
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (kDebugMode) {
      print('🔑 Token JWT configuré dans les headers');
    }
  }

  // ✅ NOUVEAU: Supprimer le token d'authentification
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) {
      print('🔓 Token JWT supprimé des headers');
    }
  }

  /// Initialise l'URL de base selon la plateforme
  void _initializeBaseUrl(int port) {
    if (kIsWeb) {
      baseUrl = 'http://localhost:$port';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://$_macIpAddress:$port';
      if (kDebugMode) {
        print('🤖 Android détecté - Utilisation IP Mac: $_macIpAddress');
      }
    } else if (Platform.isIOS) {
      if (_isSimulator()) {
        baseUrl = 'http://localhost:$port';
      } else {
        baseUrl = 'http://$_macIpAddress:$port';
      }
    } else {
      baseUrl = 'http://localhost:$port';
    }

    if (kDebugMode) {
      print(
        '🌐 ApiService - Base URL configurée: $baseUrl (Plateforme: ${_getPlatformName()})',
      );
    }
  }

  /// Initialise Dio avec la configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-${_getPlatformName()}',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    _setupInterceptors();

    if (kDebugMode) {
      print(
        '🔧 ApiService - Dio configuré avec baseUrl: ${_dio.options.baseUrl}',
      );
      print(
        '⏱️  Timeouts: Connect=${connectTimeout.inSeconds}s, Receive=${receiveTimeout.inSeconds}s',
      );
    }
  }

  /// Configure les intercepteurs Dio
  void _setupInterceptors() {
    // Intercepteur de logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          if (kDebugMode) {
            print('🌐 ApiService: $obj');
          }
        },
      ),
    );

    // ✅ NOUVEAU: Intercepteur pour gérer l'expiration du token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Charger le token si absent
          if (_authToken == null) {
            _authToken = await HiveService.getAccessToken();
            if (_authToken != null) {
              options.headers['Authorization'] = 'Bearer $_authToken';
            }
          }

          if (kDebugMode) {
            print('🔍 ApiService Request: ${options.method} ${options.uri}');
            print(
              '📡 Tentative de connexion à: ${options.baseUrl}${options.path}',
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '✅ ApiService Response: ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            print('❌ ApiService Error: ${error.message}');
            print('❌ Error Type: ${error.type}');
            print('❌ Request URL: ${error.requestOptions.uri}');
          }

          // ✅ NOUVEAU: Gérer l'expiration du token (401)
          if (error.response?.statusCode == 401) {
            if (kDebugMode) {
              print('🔄 Token expiré, tentative de rafraîchissement...');
            }

            // Tenter de rafraîchir le token
            final refreshToken = await HiveService.getRefreshToken();
            if (refreshToken != null) {
              try {
                final response = await _dio.post(
                  '/api/v1/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (response.data['access_token'] != null) {
                  final newToken = response.data['access_token'];
                  await HiveService.saveAccessToken(newToken);
                  setAuthToken(newToken);

                  // Rejouer la requête avec le nouveau token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Échec du rafraîchissement du token: $e');
                }
                // Rediriger vers login si le refresh échoue
                await HiveService.clearAllCache();
                clearAuthToken();
              }
            }
          }

          if (error.type == DioExceptionType.connectionTimeout) {
            _printNetworkDiagnostic();
          }

          handler.next(error);
        },
      ),
    );
  }

  // Méthode pour détecter si on est sur simulateur
  static bool _isSimulator() {
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

  /// NOUVEAU: Diagnostic réseau pour Android
  void _printNetworkDiagnostic() {
    if (kDebugMode) {
      print('');
      print('🔧 DIAGNOSTIC RÉSEAU ANDROID:');
      print('📱 IP utilisée: $_macIpAddress:$defaultPort');
      print('🌐 URL complète: $baseUrl');
      print('');
    }
  }

  /// Permet de changer le port manuellement si nécessaire
  void setPort(int port) {
    _initializeBaseUrl(port);
    _dio.options.baseUrl = baseUrl;
    if (kDebugMode) {
      print('🔄 ApiService - Base URL mise à jour: $baseUrl');
    }
  }

  /// Permet de définir une URL personnalisée (pour production)
  void setCustomBaseUrl(String url) {
    baseUrl = url;
    _dio.options.baseUrl = baseUrl;
    if (kDebugMode) {
      print('🔧 ApiService - URL personnalisée définie: $baseUrl');
    }
  }

  /// Teste la connexion au serveur - AMÉLIORÉ
  Future<bool> testConnection({String endpoint = '/health'}) async {
    try {
      if (kDebugMode) {
        print('🔍 Test de connexion vers: $baseUrl$endpoint');
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ ApiService - Connexion au serveur réussie');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ApiService - Impossible de se connecter au serveur: $e');
      }
    }
    return false;
  }

  /// Méthode GET
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  /// Méthode POST
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  /// Méthode PUT
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  /// Méthode PATCH
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  /// Méthode DELETE
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  /// Gestion centralisée des erreurs Dio
  ApiException _handleDioError(DioException e, String endpoint) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message =
            'Connexion impossible au serveur - Vérifiez votre réseau WiFi';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Réponse trop lente du serveur';
        break;
      case DioExceptionType.connectionError:
        message =
            'Erreur de connexion - Vérifiez que le serveur est accessible';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          message = 'Erreur serveur ($statusCode)';
        } else if (statusCode == 404) {
          message = 'Ressource non trouvée (404)';
        } else if (statusCode == 401) {
          message = 'Non autorisé - Token expiré ou invalide (401)';
        } else if (statusCode == 403) {
          message = 'Accès interdit (403)';
        } else {
          message = 'Erreur API ($statusCode)';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Requête annulée';
        break;
      default:
        message = 'Erreur réseau: ${e.message}';
    }

    return ApiException(
      message,
      statusCode: e.response?.statusCode,
      endpoint: endpoint,
    );
  }

  /// Getter pour accéder à l'instance Dio si nécessaire
  Dio get dio => _dio;

  /// Getter pour l'URL de base
  String get currentBaseUrl => baseUrl;
}
