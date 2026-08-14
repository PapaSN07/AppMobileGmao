import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/work_request.dart';

/// =====================================================================
/// INFO DI (Demandes d'Intervention) - SAUVEGARDE DU CODE D'ORIGINE
/// Pour réactiver l'écran info d'origine, supprimez les commentaires /* ... */
/// =====================================================================

class DIInfoScreen extends StatelessWidget {
  final WorkRequest request;

  const DIInfoScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche DI ${request.dinqCode}'),
        backgroundColor: const Color(0xFF0F1B80),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.article_outlined, size: 64, color: Color(0xFF0F1B80)),
              const SizedBox(height: 16),
              Text(
                "Fiche d'information DI ${request.dinqCode}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Code d'origine sauvegardé en commentaire pour le développeur du module.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =====================================================================
CODE D'ORIGINE COMPLET DE DI_INFO_SCREEN (CONSERVÉ EN BACKUP) :
======================================================================== */
/*


  void _navigateToTabs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIDetailScreen(request: request),
      ),
    );
  }

  String _formatDateLong(String? dateStr, String defaultValue) {
    if (dateStr == null || dateStr.isEmpty) return defaultValue;
    final formatted = dateStr.replaceAll('T', ' ');
    if (formatted.length < 16) return formatted;
    return formatted.substring(0, 16);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    // Get color according to Priority
    Color priorityColor = Colors.grey;
    if (request.dinqPriority == 'URGENT') {
      priorityColor = const Color(0xFFEF4444);
    } else if (request.dinqPriority == 'NORMAL') {
      priorityColor = const Color(0xFFF59E0B);
    } else if (request.dinqPriority == 'DEPL_SUPPORT') {
      priorityColor = const Color(0xFF3B82F6);
    }

    // Get color according to Status
    Color statusBg = const Color(0xFFE2E8F0);
    Color statusText = const Color(0xFF64748B);
    if (request.dinqUserStatus.contains('Créée')) {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFD97706);
    } else if (request.dinqUserStatus.contains('OT créé')) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF2B1D4C),
        title: 'DI ${request.dinqCode}',
      ),
      body: ListView(
        padding: spacing.custom(all: 16),
        children: [
          // En-tête : Badge État & Priorité
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.dinqUserStatus,
                  style: TextStyle(
                    color: statusText,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.sp(13),
                  ),
                ),
              ),
              if (request.dinqPriority != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.dinqPriority!,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.sp(12),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.medium),

          // Carte 1: Équipement
          _buildInfoCard(context, 'Équipement', [
            _buildFieldRow('Code Équipement', request.dinqEquipment),
            _buildFieldRow('Description', request.dinqEquipmentDescription),
          ]),
          SizedBox(height: spacing.medium),

          // Carte 2: Description Panne
          Container(
            padding: spacing.custom(all: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description du Problème',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    fontSize: responsive.sp(14),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  request.dinqDescription,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    fontSize: responsive.sp(14),
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.medium),

          // Carte 3: Détails Demande
          _buildInfoCard(context, 'Détails de la demande', [
            _buildFieldRow('Demandeur', request.dinqSupervisor ?? 'ERIC DASYLVA CARDOZO'),
            _buildFieldRow('Destinataire', request.dinqActionEntity ?? 'UMP-DV'),
            _buildFieldRow('Date déclaration', _formatDateLong(request.dinqAskDate, '24/07/2026 13:41')),
            _buildFieldRow('Zone géographique', request.dinqZone ?? 'DAKAR'),
          ]),
          SizedBox(height: spacing.large),

          // Bouton pour voir les détails complets (les autres pages)
          ElevatedButton.icon(
            onPressed: () => _navigateToTabs(context),
            icon: const Icon(Icons.menu_open_outlined, color: Colors.white),
            label: Text(
              'Voir les autres pages de la DI',
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontWeight: FontWeight.bold,
                fontSize: responsive.sp(14),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: spacing.custom(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      padding: spacing.custom(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
              fontSize: responsive.sp(14),
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/

