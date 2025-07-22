import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/screens/equipments/modify_equipment_screen.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart'; // Ajout de l'import

class OverlayContent extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final IconData? titleIcon;
  final VoidCallback? onClose;
  final bool showModifyButton; // Nouveau paramètre

  const OverlayContent({
    super.key,
    required this.title,
    required this.details,
    this.titleIcon,
    this.onClose,
    this.showModifyButton = true, // Par défaut, afficher le bouton
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildContent(),
        if (showModifyButton)
          _buildActionButtons(context), // Affichage conditionnel
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Bouton retour
        _buildBackButton(context),
        const SizedBox(width: 12),

        // Titre
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor15,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor15, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children:
          details.entries.map((entry) => _buildDetailItem(entry)).toList(),
    );
  }

  Widget _buildDetailItem(MapEntry<String, String> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor15,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor15, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            entry.key,
            style: const TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),

          // Valeur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor15,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.value.isNotEmpty ? entry.value : 'Non renseigné',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color:
                    entry.value.isNotEmpty
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor15,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: SecondaryButton(
        text: 'Modifier',
        icon: Icons.edit,
        width: double.infinity,
        onPressed: () {
          // Fermer l'overlay d'abord
          Navigator.of(context).pop();

          // Puis naviguer vers l'écran de modification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ModifyEquipmentScreen(equipmentData: details),
            ),
          );
        },
      ),
    );
  }
}

// Classe pour les actions personnalisées (maintenue pour compatibilité)
class OverlayAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const OverlayAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });
}
