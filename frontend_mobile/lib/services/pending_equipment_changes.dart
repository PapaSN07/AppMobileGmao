import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Équipements modifiés depuis ce téléphone et encore en attente de validation.
///
/// Une modification d'équipement est enregistrée par le backend comme une
/// proposition (base intermédiaire) : la liste, qui lit les données officielles,
/// continue d'afficher l'ancienne valeur jusqu'à la validation. On garde donc la
/// date d'envoi pour afficher « En attente de validation » sur l'équipement.
///
/// L'application ne sait pas quand la validation a lieu : l'indication
/// disparaît après [_ttl].
class PendingEquipmentChanges {
  PendingEquipmentChanges._();

  static const String _boxName = 'pending_equipment_changes';
  static const Duration _ttl = Duration(days: 30);

  /// Code équipement → date d'envoi, chargé au démarrage pour un accès immédiat.
  static final Map<String, DateTime> _sentAt = {};

  static String _key(String code) => code.trim().toUpperCase();

  /// Charge les modifications en attente (à appeler après l'initialisation de Hive).
  static Future<void> load() async {
    try {
      final box = await Hive.openBox(_boxName);
      _sentAt.clear();
      final expired = <dynamic>[];
      for (final key in box.keys) {
        final date = DateTime.tryParse(box.get(key)?.toString() ?? '');
        if (date == null || DateTime.now().difference(date) > _ttl) {
          expired.add(key);
        } else {
          _sentAt[key.toString()] = date;
        }
      }
      await box.deleteAll(expired);
    } catch (e) {
      if (kDebugMode) debugPrint('PendingEquipmentChanges: chargement impossible: $e');
    }
  }

  /// Note qu'une modification de [code] vient d'être envoyée pour validation.
  static Future<void> markPending(String code) async {
    if (code.trim().isEmpty) return;
    final now = DateTime.now();
    _sentAt[_key(code)] = now;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key(code), now.toIso8601String());
    } catch (e) {
      if (kDebugMode) debugPrint('PendingEquipmentChanges: sauvegarde impossible: $e');
    }
  }

  /// Date d'envoi de la modification en attente pour [code], ou null.
  static DateTime? pendingSince(String code) {
    final date = _sentAt[_key(code)];
    if (date == null || DateTime.now().difference(date) > _ttl) return null;
    return date;
  }
}
