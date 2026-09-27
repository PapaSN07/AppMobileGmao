import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Nonce Digest délivré par Coswin, avec son compteur de requêtes (nc).
class _DigestNonce {
  final String realm;
  final String nonce;
  final String? opaque;
  final String? qop;
  int nc = 0;

  _DigestNonce({required this.realm, required this.nonce, this.opaque, this.qop});
}

/// Intercepteur Dio pour l'authentification HTTP Digest (RFC 2617)
/// de l'API native Coswin de la Senelec (nomcosw.senelec.sn).
///
/// Coswin refuse (401) toute requête dont le compteur `nc` n'est pas strictement
/// supérieur au précédent pour un même nonce. Des requêtes parallèles partageant
/// un nonce peuvent arriver dans le désordre : chaque requête en cours dispose
/// donc de son propre nonce, emprunté à une réserve et rendu à la fin.
class CoswinDigestInterceptor extends Interceptor {
  final String username;
  final String password;
  final Dio dio;

  CoswinDigestInterceptor({
    required this.username,
    required this.password,
    required this.dio,
  });

  static const String _nonceKey = '_digest_nonce';
  static const String _retriedKey = '_digest_retried';

  /// Nonces libres (aucune requête en cours ne les utilise).
  final List<_DigestNonce> _idleNonces = [];

  String _md5(String input) => md5.convert(utf8.encode(input)).toString();

  static String? _extractParam(String header, String param) {
    final match = RegExp('$param="?([^",]+)"?').firstMatch(header);
    return match?.group(1);
  }

  static String _generateCnonce() {
    final rand = Random.secure();
    return base64Url.encode(List<int>.generate(8, (_) => rand.nextInt(256))).substring(0, 8);
  }

  String _buildDigestHeader(_DigestNonce n, {required String method, required String uri}) {
    n.nc++;
    final ncStr = n.nc.toRadixString(16).padLeft(8, '0');
    final cnonce = _generateCnonce();
    final useQop = n.qop != null && n.qop!.contains('auth');

    final ha1 = _md5('$username:${n.realm}:$password');
    final ha2 = _md5('$method:$uri');
    final response = useQop
        ? _md5('$ha1:${n.nonce}:$ncStr:$cnonce:auth:$ha2')
        : _md5('$ha1:${n.nonce}:$ha2');

    final buffer = StringBuffer('Digest ')
      ..write('username="$username", realm="${n.realm}", nonce="${n.nonce}", ')
      ..write('uri="$uri", response="$response"');
    if (n.opaque != null && n.opaque!.isNotEmpty) buffer.write(', opaque="${n.opaque}"');
    if (useQop) buffer.write(', qop=auth, nc=$ncStr, cnonce="$cnonce"');
    buffer.write(', algorithm=MD5');
    return buffer.toString();
  }

  static String _uriOf(RequestOptions options) =>
      options.uri.path + (options.uri.hasQuery ? '?${options.uri.query}' : '');

  /// Rend le nonce de la requête à la réserve (ou l'abandonne s'il a été refusé).
  void _release(RequestOptions options, {required bool reusable}) {
    final n = options.extra.remove(_nonceKey);
    if (reusable && n is _DigestNonce) _idleNonces.add(n);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Paramètres obligatoires Coswin Senelec systématiquement injectés
    options.queryParameters.putIfAbsent('dataSource', () => 'APPMOBILE');
    options.queryParameters.putIfAbsent('cwUser', () => 'supervisor');

    // 2. Anti-cache strict pour garantir des données fraîches
    options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    options.headers['Pragma'] = 'no-cache';
    options.headers['Expires'] = '0';
    options.headers['Accept'] = 'application/json';

    // 3. Authentification Digest préventive avec un nonce réservé à cette requête.
    //    Sans nonce disponible, la requête part sans authentification et le défi 401
    //    de Coswin en fournit un nouveau (voir onError).
    var n = options.extra[_nonceKey] as _DigestNonce?;
    if (n == null && _idleNonces.isNotEmpty) {
      n = _idleNonces.removeLast();
      options.extra[_nonceKey] = n;
    }
    if (n != null) {
      options.headers['Authorization'] = _buildDigestHeader(
        n,
        method: options.method.toUpperCase(),
        uri: _uriOf(options),
      );
    } else {
      options.headers.remove('Authorization');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _release(response.requestOptions, reusable: true);
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    // Un nonce refusé (401) est abandonné ; sinon il reste utilisable.
    _release(options, reusable: !isUnauthorized);

    // Au plus un rejeu par requête (évite les boucles infinies)
    if (!isUnauthorized || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final wwwAuth = err.response?.headers.value('www-authenticate');
    if (wwwAuth == null || !wwwAuth.toLowerCase().contains('digest')) {
      return handler.next(err);
    }

    final realm = _extractParam(wwwAuth, 'realm');
    final nonce = _extractParam(wwwAuth, 'nonce');
    if (realm == null || nonce == null) return handler.next(err);

    if (kDebugMode) debugPrint('🔑 CoswinDigest: défi 401 reçu, rejeu avec un nouveau nonce');

    // Nouveau nonce réservé à ce rejeu ; l'en-tête est construit par onRequest.
    options.extra[_nonceKey] = _DigestNonce(
      realm: realm,
      nonce: nonce,
      opaque: _extractParam(wwwAuth, 'opaque'),
      qop: _extractParam(wwwAuth, 'qop'),
    );
    options.extra[_retriedKey] = true;

    try {
      return handler.resolve(await dio.fetch(options));
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }
}
