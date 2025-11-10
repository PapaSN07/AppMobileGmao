import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // ✅ AJOUTÉ
import 'dart:io'; // ✅ AJOUTÉ

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() {
    return statusCode != null && endpoint != null
        ? 'ApiException ($statusCode): $message [Endpoint: $endpoint]'
        : 'ApiException: $message';
  }
}

class ApiService {
  late final Dio _dio;
  late String baseUrl;
  String? _authToken;

  static const Duration _timeout = Duration(seconds: 60);
  static const Duration _receiveTimeout = Duration(minutes: 5); // ✅ AUGMENTÉ
  // static const int _defaultPort = 8000;
  // static const String _macIpAddress = '172.20.10.4';
  static const int _defaultPort = 9099;
  static const String _macIpAddress = 'domtec.senelec.sn';

  get macIpAddress => _macIpAddress;
  get defaultPort => _defaultPort;

  ApiService({int? port, String? customBaseUrl}) {
    baseUrl = customBaseUrl ?? _buildBaseUrl(port ?? _defaultPort);
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: Duration(minutes: 3), // ✅ AUGMENTÉ
        headers: {
          'Content-Type': 'application/json; charset=utf-8', // ✅ MODIFIÉ
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate', // ✅ AJOUTÉ
        },
        validateStatus: (status) => status != null && status < 500,
        // ✅ AJOUTÉ: Taille max de réponse
        maxRedirects: 5,
      ),
    );

    // ✅ NOUVEAU: Configuration avancée du client HTTP
    _configureHttpClient();
    _setupInterceptors();
    _loadAuthToken();
  }

  // ✅ NOUVEAU: Configurer le HttpClient pour gérer les gros payloads
  void _configureHttpClient() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // ✅ Augmenter les timeouts
      client.connectionTimeout = Duration(seconds: 60);
      client.idleTimeout = Duration(minutes: 5);

      // ✅ Accepter les certificats auto-signés (production seulement si nécessaire)
      client.badCertificateCallback = (cert, host, port) => true;

      // ✅ Activer la compression automatique
      client.autoUncompress = true;

      if (kDebugMode) {
        print('✅ ApiService: HttpClient configuré avec buffers augmentés');
      }

      return client;
    };
  }

  String _buildBaseUrl(int port) {
    if (kIsWeb) return 'http://localhost:$port';
    return 'https://$_macIpAddress:$port';
  }

  Future<void> _loadAuthToken() async {
    _authToken = await HiveService.getAccessToken();
    if (_authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_authToken';
      if (kDebugMode) print('✅ ApiService: token chargé');
    }
  }

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (kDebugMode) print('✅ ApiService: token défini');
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) print('🔓 ApiService: token supprimé');
  }

  void _setupInterceptors() {
    // ✅ MODIFIÉ: Logger moins verbeux en production
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: kDebugMode,
        responseBody: false, // ✅ Désactivé pour éviter logs trop gros
        requestHeader: kDebugMode,
        responseHeader: false,
        error: true,
        logPrint: (obj) {
          if (kDebugMode) print(obj);
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ✅ Recharger le token si nécessaire
          if (_authToken == null) {
            _authToken = await HiveService.getAccessToken();
            if (_authToken != null) {
              options.headers['Authorization'] = 'Bearer $_authToken';
            }
          }

          // ✅ NOUVEAU: Logger la taille de la requête
          if (kDebugMode && options.data != null) {
            final dataSize = options.data.toString().length;
            print(
              '📤 Taille requête: ${(dataSize / 1024).toStringAsFixed(2)} KB',
            );

            // ⚠️ Avertir si payload > 1MB
            if (dataSize > 1024 * 1024) {
              print(
                '⚠️ ATTENTION: Payload très volumineux (${(dataSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
              );
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // ✅ Détecter les réponses HTML au lieu de JSON
          if (response.statusCode == 200) {
            final contentType = response.headers.value('content-type');

            if (contentType != null && contentType.contains('text/html')) {
              final responseText = response.data?.toString() ?? '';

              if (responseText.contains('Request Rejected') ||
                  responseText.contains('<html>')) {
                if (kDebugMode) {
                  print('⚠️ ApiService: Réponse HTML détectée (WAF/Firewall)');
                }

                return handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    type: DioExceptionType.badResponse,
                    error:
                        'La requête a été bloquée par le pare-feu du serveur',
                  ),
                );
              }
            }
          }

          // ✅ NOUVEAU: Logger la taille de la réponse
          if (kDebugMode) {
            final responseSize = response.data?.toString().length ?? 0;
            print(
              '📥 Taille réponse: ${(responseSize / 1024).toStringAsFixed(2)} KB',
            );
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          // ✅ NOUVEAU: Retry automatique pour Connection reset
          if (error.type == DioExceptionType.connectionError ||
              error.error.toString().contains('Connection reset by peer')) {
            if (kDebugMode) {
              print(
                '🔄 ApiService: Connection reset détectée, tentative de retry...',
              );
            }

            try {
              // Attendre 2 secondes avant de réessayer
              await Future.delayed(Duration(seconds: 2));

              final response = await _dio.fetch(error.requestOptions);

              if (kDebugMode) {
                print('✅ ApiService: Retry réussi !');
              }

              return handler.resolve(response);
            } catch (retryError) {
              if (kDebugMode) {
                print('❌ ApiService: Retry échoué: $retryError');
              }
            }
          }

          // Gestion du refresh token pour 401
          final resp = error.response;
          if (resp?.statusCode == 401) {
            final refresh = await HiveService.getRefreshToken();
            if (refresh != null) {
              try {
                final r = await _dio.post(
                  '/api/v1/auth/refresh',
                  data: {'refresh_token': refresh},
                );
                final newToken = r.data?['access_token'];
                if (newToken != null) {
                  await HiveService.saveAccessToken(newToken);
                  setAuthToken(newToken);
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retry = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retry);
                }
              } catch (_) {
                await HiveService.clearAllCache();
                clearAuthToken();
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await _dio.get(endpoint, queryParameters: queryParameters);
      return r.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 POST $endpoint');
      }

      final r = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        print('✅ POST réussi: ${r.statusCode}');
      }

      return r.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Erreur POST: ${e.type}');
        print('📋 Message: ${e.message}');
      }
      throw _handleDioError(e, endpoint);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur inattendue: $e');
      }
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return r.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return r.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final r = await _dio.delete(endpoint, queryParameters: queryParameters);
      return r.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      throw ApiException('Erreur de connexion: $e', endpoint: endpoint);
    }
  }

  ApiException _handleDioError(DioException e, String endpoint) {
    String message;
    final status = e.response?.statusCode ?? 0;

    // ✅ NOUVEAU: Gestion spécifique de Connection reset
    if (e.type == DioExceptionType.connectionError ||
        e.error.toString().contains('Connection reset by peer')) {
      message =
          'La connexion a été fermée par le serveur. Cela peut être dû à:\n'
          '• Données trop volumineuses\n'
          '• Timeout serveur\n'
          '• Pare-feu bloquant la requête';

      if (kDebugMode) {
        print('🔍 Détails erreur: ${e.error}');
      }

      return ApiException(message, statusCode: 0, endpoint: endpoint);
    }

    // ✅ Gestion des réponses HTML
    if (e.type == DioExceptionType.badResponse && status == 200) {
      final contentType = e.response?.headers.value('content-type');
      if (contentType != null && contentType.contains('text/html')) {
        message = 'La requête a été bloquée par un pare-feu (WAF)';
        return ApiException(message, statusCode: 403, endpoint: endpoint);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connexion impossible - vérifiez le réseau';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Réponse trop lente du serveur (timeout)';
    } else if (e.type == DioExceptionType.sendTimeout) {
      message = 'Envoi des données trop lent (timeout)';
    } else if (e.type == DioExceptionType.badResponse) {
      if (status >= 500) {
        message = 'Erreur serveur ($status)';
      } else if (status == 404) {
        message = 'Ressource non trouvée (404)';
      } else if (status == 401) {
        message = 'Non autorisé (401)';
      } else if (status == 403) {
        message = 'Accès interdit (403)';
      } else {
        message = 'Erreur API ($status)';
      }
    } else {
      message = 'Erreur réseau: ${e.message}';
    }

    return ApiException(message, statusCode: status, endpoint: endpoint);
  }

  void setPort(int port) {
    baseUrl = _buildBaseUrl(port);
    _dio.options.baseUrl = baseUrl;
  }

  void setCustomBaseUrl(String url) {
    baseUrl = url;
    _dio.options.baseUrl = baseUrl;
  }

  Dio get dio => _dio;
  String get currentBaseUrl => baseUrl;
}
