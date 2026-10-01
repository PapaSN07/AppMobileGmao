import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage clé → valeur utilisé pour les identifiants hors ligne (remplaçable dans les tests).
abstract class CredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Stockage chiffré du système (Keystore Android / Keychain iOS).
class SecureCredentialStore implements CredentialStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineCredentials: lecture impossible: $e');
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineCredentials: écriture impossible: $e');
    }
  }
}

/// Connexion hors ligne : après une connexion réussie en ligne, on garde sur le
/// téléphone une **empreinte** du mot de passe (PBKDF2-HMAC-SHA256 salé), jamais
/// le mot de passe lui-même, ainsi que le profil de l'utilisateur. Sans réseau,
/// on peut alors vérifier le mot de passe localement.
class OfflineCredentials {
  OfflineCredentials({CredentialStore? store}) : _store = store ?? SecureCredentialStore();

  final CredentialStore _store;

  static const int _iterations = 10000;
  static const int _saltLength = 16;

  static String _normalize(String username) => username.trim().toLowerCase();
  static String _hashKey(String username) => 'offline_hash_${_normalize(username)}';
  static String _userKey(String username) => 'offline_user_${_normalize(username)}';

  /// Mémorise l'empreinte du mot de passe et le profil après une connexion en ligne réussie.
  Future<void> remember(String username, String password, Map<String, dynamic> userJson) async {
    final salt = Uint8List.fromList(List<int>.generate(_saltLength, (_) => Random.secure().nextInt(256)));
    final hash = pbkdf2(utf8.encode(password), salt, _iterations);
    await _store.write(_hashKey(username), '${base64.encode(salt)}.$_iterations.${base64.encode(hash)}');
    await _store.write(_userKey(username), jsonEncode(userJson));
  }

  /// Profil de l'utilisateur si le mot de passe correspond à la dernière connexion en ligne, sinon null.
  Future<Map<String, dynamic>?> verify(String username, String password) async {
    final record = await _store.read(_hashKey(username));
    final parts = record?.split('.');
    if (parts == null || parts.length != 3) return null;

    final salt = base64.decode(parts[0]);
    final iterations = int.tryParse(parts[1]) ?? _iterations;
    final expected = base64.decode(parts[2]);
    final actual = pbkdf2(utf8.encode(password), salt, iterations);
    if (!_constantTimeEquals(actual, expected)) return null;

    final user = await _store.read(_userKey(username));
    if (user == null) return null;
    return jsonDecode(user) as Map<String, dynamic>;
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018), une clé de 32 octets.
  @visibleForTesting
  static Uint8List pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    final block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    var u = block;
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
