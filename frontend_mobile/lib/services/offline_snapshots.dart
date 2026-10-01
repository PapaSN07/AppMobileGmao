import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Dernière copie enregistrée d'une liste ou d'une fiche, avec sa date.
class OfflineSnapshot<T> {
  const OfflineSnapshot(this.data, this.savedAt);

  final T data;
  final DateTime savedAt;
}

/// Consultation hors ligne : dernière liste d'OT, d'équipements et fiches OT
/// chargées avec réseau, gardées sur le téléphone pour être affichées sans réseau.
class OfflineSnapshots {
  static const String _boxName = 'offline_snapshots';
  static const Duration _ttl = Duration(days: 30);

  static Box<String>? _box;

  /// Ouvre le stockage et supprime les copies trop anciennes (à appeler après l'initialisation de Hive).
  static Future<void> load() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final expired = box.keys.where((key) {
        final savedAt = _decode(box.get(key))?.savedAt;
        return savedAt == null || DateTime.now().difference(savedAt) > _ttl;
      }).toList();
      await box.deleteAll(expired);
      _box = box;
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineSnapshots: ouverture impossible: $e');
    }
  }

  static Future<void> saveList(String key, List<Map<String, dynamic>> items) =>
      saveAll({key: items});

  static Future<void> saveMap(String key, Map<String, dynamic> item) => saveAll({key: item});

  /// Enregistre plusieurs copies en une seule écriture.
  static Future<void> saveAll(Map<String, Object> entries) async {
    final box = _box;
    if (box == null || entries.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    try {
      await box.putAll({
        for (final entry in entries.entries)
          entry.key: jsonEncode({'savedAt': now, 'data': entry.value}),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('OfflineSnapshots: enregistrement impossible: $e');
    }
  }

  static OfflineSnapshot<List<Map<String, dynamic>>>? readList(String key) {
    final snapshot = _decode(_box?.get(key));
    final data = snapshot?.data;
    if (snapshot == null || data is! List) return null;
    return OfflineSnapshot(
      data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList(),
      snapshot.savedAt,
    );
  }

  static OfflineSnapshot<Map<String, dynamic>>? readMap(String key) {
    final snapshot = _decode(_box?.get(key));
    final data = snapshot?.data;
    if (snapshot == null || data is! Map) return null;
    return OfflineSnapshot(Map<String, dynamic>.from(data), snapshot.savedAt);
  }

  static OfflineSnapshot<Object?>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      final savedAt = DateTime.tryParse(json['savedAt']?.toString() ?? '');
      if (savedAt == null) return null;
      return OfflineSnapshot(json['data'], savedAt);
    } catch (_) {
      return null;
    }
  }
}
