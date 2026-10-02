import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/services/ot_sync_service.dart';
import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Écritures d'OT faites sans réseau : état de l'envoi, conflits et refus à traiter.
class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  bool _sending = false;

  /// Libellés Senelec des champs d'OT (tableau des conflits).
  static const Map<String, String> _fieldLabels = {
    'wowoJob': 'Intervention',
    'wowoJobType': 'Type d\'intervention',
    'wowoJobClass': 'Classe d\'intervention',
    'wowoCostcentre': 'Centre de responsabilité',
    'wowoEquipment': 'Équipement',
    'wowoSupervisor': 'Superviseur',
    'wowoUserStatus': 'Statut',
    'wowoPriority': 'Priorité',
    'wowoZone': 'Zone',
    'wowoRequestEntity': 'Entité',
    'wowoCompletionRate': 'Taux de réalisation',
    'wowoFeedbackNote': 'Commentaire',
  };

  OtSyncService get _sync => context.read<OtSyncService>();

  Future<void> _run(Future<SyncReport> Function() action) async {
    setState(() => _sending = true);
    try {
      final report = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(report.summary)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _abandon(PendingOtAction action) async {
    // Abandonner la création d'un OT abandonne aussi ce qui a été saisi dessus
    final linked = action.kind == PendingOtKind.createOT
        ? PendingOtQueue.all().where((a) => a.otCode == action.otCode).toList()
        : [action];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner ?'),
        content: Text(linked.length > 1
            ? 'L\'OT ne sera pas créé, ni les ${linked.length - 1} élément(s) saisi(s) dessus. '
                'Cette saisie sera perdue.'
            : 'Cette saisie ne sera pas envoyée à Coswin et sera perdue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonner', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final a in linked) {
      await PendingOtQueue.remove(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = HiveService.getCurrentUser()?.username;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Envois en attente')),
      body: ValueListenableBuilder<List<PendingOtAction>>(
        valueListenable: PendingOtQueue.actions,
        builder: (context, actions, _) {
          final mine = actions.where((a) => a.username == username).toList();
          if (mine.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Tout a été envoyé à Coswin.', textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ces saisies ont été faites sans réseau. Elles partent automatiquement '
                'dès que le réseau revient, dans l\'ordre où elles ont été faites.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _sending ? null : () => _run(_sync.syncNow),
                icon: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Envoyer maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.senelecReflexBlue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              for (final action in mine) _buildAction(action),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAction(PendingOtAction action) {
    String two(int n) => n.toString().padLeft(2, '0');
    final at = action.createdAt;
    final (statusLabel, statusColor) = switch (action.status) {
      PendingStatus.pending => ('En attente du réseau', Colors.orange.shade800),
      PendingStatus.conflict => ('Modifié dans Coswin entre-temps', Colors.red.shade700),
      PendingStatus.failed => ('Refusé par Coswin', Colors.red.shade700),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(action.description, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Saisi le ${two(at.day)}/${two(at.month)} à ${two(at.hour)}h${two(at.minute)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
            if (action.status == PendingStatus.failed && action.lastError != null) ...[
              const SizedBox(height: 4),
              Text(action.lastError!, style: const TextStyle(fontSize: 13)),
            ],
            if (action.status == PendingStatus.conflict) ...[
              const SizedBox(height: 8),
              for (final c in action.conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                      text: '${_fieldLabels[c.field] ?? c.field}\n',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: 'Coswin : ${c.coswin.isEmpty ? '(vide)' : c.coswin}\n'),
                    TextSpan(text: 'Votre valeur : ${c.mine.isEmpty ? '(vide)' : c.mine}'),
                  ])),
                ),
            ],
            if (action.status != PendingStatus.pending)
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () => _run(() => _sync.retry(action, force: action.status == PendingStatus.conflict)),
                    child: Text(action.status == PendingStatus.conflict ? 'Envoyer ma version' : 'Réessayer'),
                  ),
                  TextButton(
                    onPressed: _sending ? null : () => _abandon(action),
                    child: Text(
                      action.status == PendingStatus.conflict ? 'Abandonner ma modification' : 'Abandonner',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
