import 'package:appmobilegmao/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

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

  static const Duration _timeout = Duration(seconds: 30);
  static const int _productionPort = 9099;
  static const String _productionHost = 'domtec.senelec.sn';
  static const int _localDevPort = 8003;
  // IP de boucle locale de l'émulateur Android Studio vers le PC hôte (10.0.2.2)
  static const String _localDevHost = '10.0.2.2';

  String get macIpAddress => _resolveHost();
  int get defaultPort => _resolvePort();

  ApiService({int? port, String? customBaseUrl}) {
    final resolvedPort = port ?? _resolvePort();
    baseUrl = customBaseUrl ?? _buildBaseUrl(resolvedPort);
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _setupInterceptors();
    _loadAuthToken();
  }

  int _resolvePort() {
    return kReleaseMode ? _productionPort : _localDevPort;
  }

  String _resolveHost() {
    if (kReleaseMode) return _productionHost;
    if (kIsWeb) return 'localhost';

    if (defaultTargetPlatform == TargetPlatform.android) {
      // IP locale de la machine de dev pour le vrai téléphone et l'émulateur
      return _localDevHost;
    }

    return 'localhost';
  }

  static const bool useTunnel = false;
  static const String _publicTunnelUrl = 'https://gmao-senelec-mobile.loca.lt';

  String _buildBaseUrl(int port) {
    if (kReleaseMode) return 'https://$_productionHost:$_productionPort';
    if (useTunnel && _publicTunnelUrl.isNotEmpty) {
      return _publicTunnelUrl;
    }
    final host = _resolveHost();
    return 'http://$host:$port';
  }

  Future<void> _loadAuthToken() async {
    _authToken = await HiveService.getAccessToken();
    if (_authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_authToken';
      if (kDebugMode) print('ApiService: token chargé');
    }
  }

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (kDebugMode) print('ApiService: token défini');
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) print('ApiService: token supprimé');
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_authToken == null) {
            _authToken = await HiveService.getAccessToken();
            if (_authToken != null) {
              options.headers['Authorization'] = 'Bearer $_authToken';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ✅ NOUVEAU: Vérifier si la réponse est du HTML au lieu de JSON
          if (response.statusCode == 200) {
            final contentType = response.headers.value('content-type');

            // Détecter les réponses HTML (pare-feu WAF, erreurs serveur, etc.)
            if (contentType != null && contentType.contains('text/html')) {
              final responseText = response.data?.toString() ?? '';

              // Vérifier si c'est une page de rejet
              if (responseText.contains('Request Rejected') ||
                  responseText.contains('<html>')) {
                if (kDebugMode) {
                  print('⚠️ ApiService: Réponse HTML détectée au lieu de JSON');
                  print('Content-Type: $contentType');
                }

                // Transformer en erreur DioException
                return handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    type: DioExceptionType.badResponse,
                    error:
                        'La requête a été rejetée par le serveur (pare-feu ou filtre de sécurité)',
                  ),
                );
              }
            }
          }

          handler.next(response);
        },
        onError: (error, handler) async {
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
    Duration? timeout,
  }) async {
    try {
      final options = timeout != null
          ? Options(receiveTimeout: timeout, sendTimeout: timeout)
          : null;
      final r = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
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
      final r = await _dio.post(
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

    // ✅ NOUVEAU: Gestion spéciale pour les réponses HTML
    if (e.type == DioExceptionType.badResponse && status == 200) {
      final contentType = e.response?.headers.value('content-type');
      if (contentType != null && contentType.contains('text/html')) {
        message =
            'La requête a été bloquée par un pare-feu ou un filtre de sécurité';
        if (kDebugMode) {
          print('⚠️ ApiService: Réponse HTML au lieu de JSON (WAF/Firewall)');
        }
        return ApiException(message, statusCode: 403, endpoint: endpoint);
      }
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connexion impossible - vérifiez le réseau';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Réponse trop lente du serveur';
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