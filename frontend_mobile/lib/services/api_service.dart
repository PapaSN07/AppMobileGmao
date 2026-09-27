import 'package:appmobilegmao/services/coswin_digest_interceptor.dart';
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
  static ApiService? _instance;
  late final Dio _dio;
  late final Dio _dioCoswin;
  late String baseUrl;
  String? _authToken;
  bool _isRefreshing = false;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _productionPort = 9099;
  static const String _productionHost = 'domtec.senelec.sn';
  static const String _coswinBaseUrl = 'https://nomcosw.senelec.sn:8083/ws/rest';

  /// Identifiants Coswin fournis à la construction de l'APK, jamais écrits dans le code :
  ///   flutter build apk --debug --dart-define-from-file=coswin.local.json
  /// (fichier local ignoré par git, modèle : coswin.local.example.json)
  static const String _coswinUser = String.fromEnvironment('COSWIN_USER');
  static const String _coswinPassword = String.fromEnvironment('COSWIN_PASSWORD');
  static bool get _hasCoswinCredentials => _coswinUser.isNotEmpty && _coswinPassword.isNotEmpty;

  String get macIpAddress => _resolveHost();
  int get defaultPort => _resolvePort();

  factory ApiService({int? port, String? customBaseUrl}) {
    _instance ??= ApiService._internal(port: port, customBaseUrl: customBaseUrl);
    if (customBaseUrl != null) {
      _instance!.setCustomBaseUrl(customBaseUrl);
    } else if (port != null) {
      _instance!.setPort(port);
    }
    return _instance!;
  }

  ApiService._internal({int? port, String? customBaseUrl}) {
    final resolvedPort = port ?? _resolvePort();
    baseUrl = customBaseUrl ?? _buildBaseUrl(resolvedPort);

    // 1️⃣ Client FastAPI (Auth JWT & Équipements)
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
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );


    _setupInterceptors();
    _dio.interceptors.add(_wafRejectionInterceptor());
    _loadAuthToken();

    // 2️⃣ Client Coswin Natif (OT, DI, Spécifications, Articles)
    _dioCoswin = Dio(
      BaseOptions(
        baseUrl: _coswinBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );


    _dioCoswin.interceptors.add(
      CoswinDigestInterceptor(
        username: _coswinUser,
        password: _coswinPassword,
        dio: _dioCoswin,
      ),
    );
    _dioCoswin.interceptors.add(_wafRejectionInterceptor());
  }

  /// Le pare-feu Senelec (WAF) répond « Request Rejected » en HTML avec un code 200.
  /// Sans ce contrôle, un refus serait pris pour un succès : on le transforme en erreur.
  static Interceptor _wafRejectionInterceptor() => InterceptorsWrapper(
        onResponse: (response, handler) {
          final contentType = response.headers.value('content-type') ?? '';
          final body = response.data is String ? response.data as String : '';
          if (contentType.contains('text/html') &&
              (body.contains('Request Rejected') || body.contains('<html>'))) {
            if (kDebugMode) {
              debugPrint('⚠️ ApiService: requête ${response.requestOptions.method} '
                  '${response.requestOptions.path} rejetée par le pare-feu');
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: 'La requête a été rejetée par le pare-feu Senelec',
              ),
            );
          }
          handler.next(response);
        },
      );

  int _resolvePort() {
    return _productionPort; 
  }

  String _resolveHost() {
    if (kIsWeb) {
      final webHost = Uri.base.host;
      if (webHost.isNotEmpty && webHost != 'localhost' && webHost != '127.0.0.1') {
        return webHost;
      }
      return _productionHost;
    }

    return _productionHost;
  }

  // Configuration Production vs Dev
  static const bool isProduction = true;
  static const String _productionBaseUrl = 'https://domtec.senelec.sn:9099';
  static const bool useTunnel = false;
  static const String _publicTunnelUrl = 'https://lovers-concerned-customs-finding.trycloudflare.com';

  String _buildBaseUrl(int port) {
    if (isProduction) {
      return _productionBaseUrl;
    }
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
    // Journal HTTP en debug uniquement : il contient identifiants de connexion et tokens.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Forcer le non-cache sur chaque requête
          options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';

          // DRY: Source unique de vérité pour le token JWT
          final token = _authToken ?? await HiveService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            _authToken = token;
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final resp = error.response;
          final path = error.requestOptions.path;
          final isAuthRoute = path.contains('/auth/login') || path.contains('/auth/refresh');

          // SOLID: Ne tenter le rafraîchissement que pour les requêtes métier (évite les boucles sur auth)
          if (resp?.statusCode == 401 && !isAuthRoute) {
            final refresh = await HiveService.getRefreshToken();
            if (refresh != null && !_isRefreshing) {
              _isRefreshing = true;
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
              } on DioException catch (dioErr) {
                // SOLID: Ne déconnecter QUE si le serveur rejette formellement le token (401/403)
                final refreshStatus = dioErr.response?.statusCode;
                if (refreshStatus == 401 || refreshStatus == 403) {
                  await HiveService.clearAllCache();
                  clearAuthToken();
                }
              } catch (_) {
                // Erreur réseau ou abort de socket: ne pas déconnecter l'utilisateur
              } finally {
                _isRefreshing = false;
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
  }) => _send(_dio, 'GET', endpoint, queryParameters: queryParameters, timeout: timeout);

  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _send(_dio, 'POST', endpoint, data: data, queryParameters: queryParameters);

  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _send(_dio, 'PUT', endpoint, data: data, queryParameters: queryParameters);

  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _send(_dio, 'PATCH', endpoint, data: data, queryParameters: queryParameters);

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) => _send(_dio, 'DELETE', endpoint, queryParameters: queryParameters);

  /// Point d'entrée unique des appels HTTP (FastAPI et Coswin) :
  /// même gestion des timeouts et même traduction des erreurs.
  Future<dynamic> _send(
    Dio client,
    String method,
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    if (identical(client, _dioCoswin) && !_hasCoswinCredentials) {
      throw ApiException(
        'Identifiants Coswin absents de cette version de l\'application '
        '(construire avec --dart-define-from-file=coswin.local.json).',
        endpoint: endpoint,
      );
    }
    try {
      final r = await client.request(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      return r.data;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    } catch (e) {
      final source = identical(client, _dioCoswin) ? 'Coswin' : 'de connexion';
      throw ApiException('Erreur $source: $e', endpoint: endpoint);
    }
  }

  ApiException _handleDioError(DioException e, String endpoint) {
    String message;
    final status = e.response?.statusCode ?? 0;

    // ✅ NOUVEAU: Gestion spéciale pour les réponses HTML
    if (e.type == DioExceptionType.badResponse && status == 200) {
      final contentType = e.response?.headers.value('content-type');
      if (contentType != null && contentType.contains('text/html')) {
        final method = e.requestOptions.method.toUpperCase();
        message = (method == 'PUT' || method == 'DELETE')
            ? 'Le pare-feu Senelec bloque les ${method == 'PUT' ? 'modifications' : 'suppressions'} '
                "vers Coswin : rien n'a été enregistré."
            : 'La requête a été bloquée par le pare-feu Senelec.';
        if (kDebugMode) {
          print('⚠️ ApiService: Réponse HTML au lieu de JSON (WAF/Firewall)');
        }
        return ApiException(message, statusCode: 403, endpoint: endpoint);
      }
    }

    // Extraire le message d'erreur détaillé du backend ou de Coswin si présent
    String? serverDetail;
    if (e.response?.data is Map) {
      final dataMap = e.response!.data as Map;
      serverDetail = dataMap['detail']?.toString() ??
          dataMap['faultstring']?.toString() ??
          dataMap['message']?.toString() ??
          dataMap['error']?.toString() ??
          dataMap['description']?.toString();
    } else if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
      final rawStr = (e.response!.data as String).trim();
      // Extraction des balises d'erreur XML/SOAP typiques de Coswin
      final faultMatch = RegExp(r'<faultstring>(.*?)</faultstring>', dotAll: true).firstMatch(rawStr);
      final msgMatch = RegExp(r'<message>(.*?)</message>', dotAll: true).firstMatch(rawStr);
      if (faultMatch != null) {
        serverDetail = faultMatch.group(1)?.trim();
      } else if (msgMatch != null) {
        serverDetail = msgMatch.group(1)?.trim();
      } else if (rawStr.contains('Request Rejected')) {
        serverDetail = 'Requête rejetée par le filtre de sécurité réseau Senelec (Request Rejected).';
      } else if (!rawStr.startsWith('<')) {
        serverDetail = rawStr.length > 300 ? rawStr.substring(0, 300) : rawStr;
      }
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Délai d\'attente dépassé : impossible de joindre le serveur Senelec.';
    } else if (e.type == DioExceptionType.sendTimeout) {
      message = 'Délai d\'envoi dépassé. Vérifiez votre connexion internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Le serveur Senelec met trop de temps à répondre. Veuillez réessayer.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Impossible de joindre le serveur (domtec.senelec.sn). Vérifiez votre connexion internet.';
    } else if (e.type == DioExceptionType.badCertificate) {
      message = 'Erreur de sécurité SSL : le certificat du serveur n\'a pas pu être validé.';
    } else if (e.type == DioExceptionType.cancel) {
      message = 'La requête a été annulée.';
    } else if (e.type == DioExceptionType.badResponse) {
      if (serverDetail != null && serverDetail.isNotEmpty) {
        message = serverDetail;
      } else if (status >= 500) {
        message = 'Erreur interne du serveur Senelec ($status). Veuillez réessayer plus tard.';
      } else if (status == 404) {
        message = 'Ressource non trouvée sur le serveur (404).';
      } else if (status == 401) {
        message = 'Session expirée ou non autorisée (401).';
      } else if (status == 403) {
        message = 'Accès refusé par le serveur (403).';
      } else {
        message = 'Erreur du serveur ($status).';
      }
    } else {
      message = serverDetail ?? 'Erreur réseau : impossible de joindre le serveur.';
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
  Dio get dioCoswin => _dioCoswin;
  String get currentBaseUrl => baseUrl;
  String get coswinBaseUrl => _coswinBaseUrl;

  // ========== MÉTHODES CLIENT COSWIN NATIF (OT, DI, ARTICLES, SPÉCIFICATIONS) ==========

  Future<dynamic> getCoswin(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) => _send(_dioCoswin, 'GET', endpoint, queryParameters: queryParameters, timeout: timeout);

  Future<dynamic> postCoswin(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _send(_dioCoswin, 'POST', endpoint, data: data, queryParameters: queryParameters);

  Future<dynamic> putCoswin(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _send(_dioCoswin, 'PUT', endpoint, data: data, queryParameters: queryParameters);

  Future<dynamic> deleteCoswin(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) => _send(_dioCoswin, 'DELETE', endpoint, queryParameters: queryParameters);
}