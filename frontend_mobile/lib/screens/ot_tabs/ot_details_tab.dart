import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/order.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

/// Onglet "Détails" - Affiche le taux de réalisation et un bouton pour accéder aux détails complets
/// Principe SOLID: Single Responsibility - Gère uniquement l'affichage du taux de réalisation
class DetailsTab extends StatefulWidget {
  final Order order;

  const DetailsTab({super.key, required this.order});

  @override
  State<DetailsTab> createState() => DetailsTabState();
}

class DetailsTabState extends State<DetailsTab> {
  // Contrôleur pour le champ taux de réalisation
  late TextEditingController _tauxRealisationController;

  @override
  void initState() {
    super.initState();
    try {
      final rate = widget.order.completionRate;
      _tauxRealisationController = TextEditingController(
        text: rate != null ? '${rate.toInt()}%' : '0%',
      );
    } catch (e) {
      debugPrint('Erreur initState DetailsTab: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tauxRealisationController.dispose();
    } catch (e) {
      debugPrint('Erreur dispose DetailsTab: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailField(
              label: 'Code OT',
              value: widget.order.code,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Équipement',
              value: widget.order.unite,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Description',
              value: widget.order.description,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Famille / Classe',
              value: widget.order.famille,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Zone',
              value: widget.order.zone,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Entité',
              value: widget.order.entity,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            _buildDetailField(
              label: 'Centre de charge',
              value: widget.order.centre,
              spacing: spacing,
            ),
            const SizedBox(height: 16),
            // Champ "Taux de réalisation"
            const Text(
              'Taux de réalisation',
              style: TextStyle(
                color: Color(0xFF0F1B80),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tauxRealisationController,
                      readOnly: true,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erreur build DetailsTab: $e');
      return Center(
        child: Text('Erreur: $e'),
      );
    }
  }

  /// Widget réutilisable pour afficher un champ de détail en lecture seule
  Widget _buildDetailField({
    required String label,
    required String value,
    required ResponsiveSpacing spacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F1B80),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TextFormField(
            initialValue: value,
            readOnly: true,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

}
