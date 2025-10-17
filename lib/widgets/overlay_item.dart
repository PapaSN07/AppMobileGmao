import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/screens/equipments/modify_equipment_screen.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart'; // Ajout de l'import
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class OverlayContent extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final IconData? titleIcon;
  final VoidCallback? onClose;
  final bool showModifyButton;
  final List<Map<String, dynamic>>? moreData; // Données supplémentaires optionnelles

  const OverlayContent({
    super.key,
    required this.title,
    required this.details,
    this.titleIcon,
    this.onClose,
    this.showModifyButton = true,
    this.moreData,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, responsive, spacing),
        SizedBox(height: spacing.large), // ✅ Espacement responsive
        _buildContent(responsive, spacing),
        if (showModifyButton)
          _buildActionButtons(context, responsive, spacing), // Affichage conditionnel
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Responsive responsive, ResponsiveSpacing spacing) {
    return Row(
      children: [
        // Bouton retour
        _buildBackButton(context, responsive, spacing),
        SizedBox(width: spacing.medium), // ✅ Espacement responsive

        // Titre
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              fontSize: responsive.sp(20), // ✅ Texte responsive
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, Responsive responsive, ResponsiveSpacing spacing) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.of(context).pop(),
      child: Container(
        width: responsive.spacing(40), // ✅ Largeur responsive
        height: responsive.spacing(40), // ✅ Hauteur responsive
        decoration: BoxDecoration(
          color: AppTheme.primaryColor15,
          borderRadius: BorderRadius.circular(responsive.spacing(12)), // ✅ Border radius responsive
          border: Border.all(color: AppTheme.primaryColor15, width: 1),
        ),
        child: Icon(
          Icons.arrow_back,
          size: responsive.iconSize(20), // ✅ Icône responsive
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildContent(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      children: details.entries
          .where((entry) => entry.key.toLowerCase() != 'id')
          .map((entry) => _buildDetailItem(entry, responsive, spacing))
          .toList(),
    );
  }

  Widget _buildDetailItem(MapEntry<String, String> entry, Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.medium), // ✅ Margin responsive
      padding: spacing.allPadding, // ✅ Padding responsive
      decoration: BoxDecoration(
        color: AppTheme.primaryColor15,
        borderRadius: BorderRadius.circular(responsive.spacing(12)), // ✅ Border radius responsive
        border: Border.all(color: AppTheme.primaryColor15, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            entry.key,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(14), // ✅ Texte responsive
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: spacing.small), // ✅ Espacement responsive

          // Valeur
          Container(
            width: double.infinity,
            padding: spacing.custom(vertical: 8, horizontal: 12), // ✅ Padding responsive
            decoration: BoxDecoration(
              color: AppTheme.primaryColor15,
              borderRadius: BorderRadius.circular(responsive.spacing(8)), // ✅ Border radius responsive
            ),
            child: Text(
              entry.value.isNotEmpty ? entry.value : 'Non renseigné',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                fontSize: responsive.sp(14), // ✅ Texte responsive
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

  Widget _buildActionButtons(BuildContext context, Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      margin: EdgeInsets.only(top: spacing.large), // ✅ Margin responsive
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
                  (context) => ModifyEquipmentScreen(equipmentData: details, equipmentAttributes: moreData),
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