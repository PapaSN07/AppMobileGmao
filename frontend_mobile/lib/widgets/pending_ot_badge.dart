import 'package:appmobilegmao/services/pending_ot_queue.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_badge.dart';
import 'package:flutter/material.dart';

/// Badge d'une carte d'OT qui a des écritures faites sans réseau, pas encore envoyées.
/// Se met à jour tout seul quand la file change (saisie, envoi, refus).
class PendingOtBadge extends StatelessWidget {
  const PendingOtBadge({super.key, required this.otCode});

  final String otCode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PendingOtAction>>(
      valueListenable: PendingOtQueue.actions,
      builder: (context, actions, _) {
        final mine = actions.where((a) => a.otCode == otCode).toList();
        if (mine.isEmpty) return const SizedBox.shrink();

        final blocked = mine.any((a) => a.status != PendingStatus.pending);
        final label = blocked
            ? 'Envoi bloqué : voir les envois en attente'
            : PendingOtQueue.isTemporaryCode(otCode)
                ? 'Nouvel OT · en attente d\'envoi'
                : '${mine.length} modification${mine.length > 1 ? 's' : ''} en attente d\'envoi';
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: EquipmentBadge(
            label: label,
            color: blocked ? Colors.red.shade700 : Colors.orange.shade800,
            icon: blocked ? Icons.error_outline : Icons.cloud_upload_outlined,
          ),
        );
      },
    );
  }
}
