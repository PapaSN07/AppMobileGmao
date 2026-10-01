import 'dart:convert';

import 'package:appmobilegmao/services/offline_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Stockage en mémoire à la place du stockage chiffré du système.
class _MemoryStore implements CredentialStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('PBKDF2-HMAC-SHA256 matches the reference test vectors', () {
    expect(
      _hex(OfflineCredentials.pbkdf2(utf8.encode('password'), utf8.encode('salt'), 1)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      _hex(OfflineCredentials.pbkdf2(utf8.encode('password'), utf8.encode('salt'), 2)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
  });

  group('offline login', () {
    late _MemoryStore store;
    late OfflineCredentials credentials;

    setUp(() {
      store = _MemoryStore();
      credentials = OfflineCredentials(store: store);
    });

    test('the right password gives back the user profile, the wrong one does not', () async {
      await credentials.remember('Agent.Test', 'Secret123', {'username': 'agent.test', 'code': '587'});

      expect(await credentials.verify('agent.test', 'Secret123'), {'username': 'agent.test', 'code': '587'});
      expect(await credentials.verify('agent.test', 'secret123'), isNull);
      expect(await credentials.verify('autre.agent', 'Secret123'), isNull);
    });

    test('the password itself is never stored', () async {
      await credentials.remember('agent.test', 'Secret123', {'username': 'agent.test'});
      expect(store.values.values.any((v) => v.contains('Secret123')), isFalse);
    });

    test('no previous online login: offline login is refused', () async {
      expect(await credentials.verify('agent.test', 'Secret123'), isNull);
    });
  });
}
