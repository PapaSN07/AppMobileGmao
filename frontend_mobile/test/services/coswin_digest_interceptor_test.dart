import 'dart:convert';
import 'dart:typed_data';

import 'package:appmobilegmao/services/coswin_digest_interceptor.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux serveur Coswin : Digest avec compteur `nc` strictement croissant par nonce
/// (comportement constaté sur nomcosw.senelec.sn), réponses dans le désordre.
class _StrictDigestServer implements HttpClientAdapter {
  int _issued = 0;
  final Map<String, int> _lastNc = {};
  int challenges = 0;

  String _md5(String s) => md5.convert(utf8.encode(s)).toString();

  ResponseBody _json(int status, Object body, {Map<String, List<String>> headers = const {}}) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        'content-type': ['application/json'],
        ...headers,
      });

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // Latence variable : les requêtes parallèles arrivent dans un ordre aléatoire.
    await Future.delayed(Duration(milliseconds: (options.uri.query.hashCode % 7) * 3));

    final auth = options.headers['Authorization'] as String?;
    if (auth == null) return _challenge();

    String param(String name) => RegExp('$name="?([^",]+)"?').firstMatch(auth)!.group(1)!;
    final nonce = param('nonce');
    final nc = int.parse(param('nc'), radix: 16);
    final uri = param('uri');
    final ha1 = _md5('admin:CoswinWSRealm:admin');
    final ha2 = _md5('${options.method}:$uri');
    final expected = _md5('$ha1:$nonce:${param('nc')}:${param('cnonce')}:auth:$ha2');

    final valid = _lastNc.containsKey(nonce) && nc > _lastNc[nonce]! && param('response') == expected;
    if (!valid) return _challenge();
    _lastNc[nonce] = nc;
    return _json(200, {'ok': true});
  }

  ResponseBody _challenge() {
    challenges++;
    final nonce = 'nonce${_issued++}';
    _lastNc[nonce] = 0;
    return _json(401, {'message': 'Unauthorized'}, headers: {
      'www-authenticate': ['Digest realm="CoswinWSRealm", nonce="$nonce", opaque="0000", qop="auth"'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('parallel Coswin requests never reuse a nonce out of order', () async {
    final server = _StrictDigestServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://coswin.test/ws/rest'))..httpClientAdapter = server;
    dio.interceptors.add(CoswinDigestInterceptor(username: 'admin', password: 'admin', dio: dio));

    // Premier chargement : 8 requêtes simultanées, puis une seconde vague.
    for (var wave = 0; wave < 2; wave++) {
      final responses = await Future.wait([
        for (var i = 0; i < 8; i++) dio.get('/workorders', queryParameters: {'n': '$wave-$i'}),
      ]);
      expect(responses.map((r) => r.statusCode), everyElement(200));
    }
    // La seconde vague réutilise les nonces obtenus lors de la première.
    expect(server.challenges, lessThanOrEqualTo(8));
  });
}
