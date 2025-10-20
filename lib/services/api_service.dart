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

  static const Duration _timeout = Duration(seconds: 60);
  static const int _defaultPort = 8000;
  static const String _macIpAddress = '192.168.1.102';
  // static const int _defaultPort = 9099;
  // static const String _macIpAddress = 'domtec.senelec.sn';

  ApiService({int? port, String? customBaseUrl}) {
    baseUrl = customBaseUrl ?? _buildBaseUrl(port ?? _defaultPort);
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _setupInterceptors();
    _loadAuthToken(); // async fire-and-forget: charge token si présent
  }

  String _buildBaseUrl(int port) {
    if (kIsWeb) return 'http://localhost:$port';
    // Pour Android et iOS on utilise l'IP du Mac (comme demandé)
    // return 'https://$_macIpAddress:$port'; // Pour le prod
    return 'http://$_macIpAddress:$port'; // Pour le dev sans SSL
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
        onError: (error, handler) async {
          final resp = error.response;
          if (resp?.statusCode == 401) {
            // tentative de refresh
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
                  // rejouer la requête initiale
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retry = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retry);
                }
              } catch (_) {
                // si échec refresh -> clear et laisser l'erreur remonter
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

  // utilitaires
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
