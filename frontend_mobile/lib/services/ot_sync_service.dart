import 'dart:async';

import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/ot_conflict.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:flutter/foundation.dart';

/// Bilan d'un envoi de la file.
class SyncReport {
  const SyncReport({this.sent = 0, this.blocked = 0, this.stoppedByNetwork = false});

  /// Écritures envoyées à Coswin et retirées de la file.
  final int sent;

  /// Écritures qui demandent l'agent (conflit ou refus de Coswin).
  final int blocked;

  /// Le réseau a lâché pendant l'envoi : la suite partira au prochain retour du réseau.
  final bool stoppedByNetwork;

  /// Message de fin d'envoi pour l'agent.
  String get summary {
    final parts = <String>[
      if (sent > 0) '$sent envoi${sent > 1 ? 's' : ''} réussi${sent > 1 ? 's' : ''}',
      if (blocked > 0) '$blocked à vérifier',
      if (stoppedByNetwork) 'pas de réseau : la suite partira au retour du réseau',
    ];
    return parts.isEmpty ? 'Rien à envoyer.' : '${parts.join(' · ')}.';
  }
}

/// Envoie à Coswin, dans l'ordre de saisie, les écritures d'OT faites sans réseau.
///
/// - un seul envoi à la fois (les déclenchements simultanés partagent le même) ;
/// - seules les écritures de l'utilisateur connecté partent ;
/// - un conflit ou un refus de Coswin bloque seulement l'OT concerné ;
/// - une coupure réseau arrête l'envoi, la suite reste en attente.
class OtSyncService {
  OtSyncService({
    required Future<void> Function(PendingOtAction action) send,
    required String? Function() currentUsername,
    required Future<bool> Function() hasNetwork,
  })  : _send = send,
        _currentUsername = currentUsername,
        _hasNetwork = hasNetwork;

  final Future<void> Function(PendingOtAction action) _send;
  final String? Function() _currentUsername;
  final Future<bool> Function() _hasNetwork;

  Future<SyncReport>? _running;

  /// Incrémenté après chaque envoi réussi : les listes d'OT s'y abonnent pour se recharger.
  final ValueNotifier<int> completedSyncs = ValueNotifier(0);

  bool get isRunning => _running != null;

  Future<SyncReport> syncNow() => _running ??= _run().whenComplete(() => _running = null);

  Future<SyncReport> _run() async {
    final username = _currentUsername();
    if (username == null || username.isEmpty) return const SyncReport();
    if (PendingOtQueue.forUser(username).isEmpty) return const SyncReport();
    if (!await _hasNetwork()) return const SyncReport(stoppedByNetwork: true);

    var sent = 0;
    final blockedOts = <String>{};
    var stoppedByNetwork = false;

    for (final id in PendingOtQueue.forUser(username).map((a) => a.id).toList()) {
      // Relue à chaque tour : un OT créé juste avant a remplacé son code provisoire
      final action = PendingOtQueue.byId(id);
      if (action == null) continue;
      if (blockedOts.contains(action.otCode) || action.status != PendingStatus.pending) {
        blockedOts.add(action.otCode);
        continue;
      }
      try {
        await _send(action);
        await PendingOtQueue.remove(action.id);
        sent++;
      } on OtConflictException catch (e) {
        action
          ..status = PendingStatus.conflict
          ..conflicts = e.conflicts
          ..lastError = e.toString();
        await PendingOtQueue.save(action);
        blockedOts.add(action.otCode);
      } catch (e) {
        if (isNetworkFailure(e)) {
          stoppedByNetwork = true;
          break;
        }
        action
          ..status = PendingStatus.failed
          ..lastError = _readable(e);
        await PendingOtQueue.save(action);
        blockedOts.add(action.otCode);
      }
    }

    if (sent > 0) completedSyncs.value++;
    final blocked = PendingOtQueue.forUser(username).where((a) => a.status != PendingStatus.pending).length;
    return SyncReport(sent: sent, blocked: blocked, stoppedByNetwork: stoppedByNetwork);
  }

  /// Remet une écriture refusée dans la file et relance l'envoi.
  Future<SyncReport> retry(PendingOtAction action, {bool force = false}) async {
    action
      ..status = PendingStatus.pending
      ..lastError = null
      ..conflicts = const []
      ..force = force || action.force;
    await PendingOtQueue.save(action);
    return syncNow();
  }

  static String _readable(Object e) {
    final text = e is ApiException ? e.message : e.toString();
    return text.replaceFirst('Exception: ', '');
  }
}
