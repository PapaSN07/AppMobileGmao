import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/screens/equipments/modify_equipment_screen.dart';
import 'package:appmobilegmao/widgets/custom_buttons.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

class OverlayContent extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final IconData? titleIcon;
  final VoidCallback? onClose;
  final bool showModifyButton;
  final List<Map<String, dynamic>>? moreData;
  final Widget? topBadges;
  final Widget? statusBadge;

  const OverlayContent({
    super.key,
    required this.title,
    required this.details,
    this.titleIcon,
    this.onClose,
    this.showModifyButton = true,
    this.moreData,
    this.topBadges,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, responsive, spacing),
        SizedBox(height: spacing.large),

        // ✅ Section badges EN PREMIER
        if (topBadges != null || statusBadge != null) ...[
          _buildBadgesSection(responsive, spacing),
          SizedBox(height: spacing.large),
        ],

        _buildContent(responsive, spacing),
        if (showModifyButton) _buildActionButtons(context, responsive, spacing),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Row(
      children: [
        _buildBackButton(context, responsive, spacing),
        SizedBox(width: spacing.medium),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              fontSize: responsive.sp(20),
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.of(context).pop(),
      child: Container(
        width: responsive.spacing(40),
        height: responsive.spacing(40),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor15,
          borderRadius: BorderRadius.circular(responsive.spacing(12)),
          border: Border.all(color: AppTheme.primaryColor15, width: 1),
        ),
        child: Icon(
          Icons.arrow_back,
          size: responsive.iconSize(20),
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // ✅ CORRIGÉ: Section badges avec disposition verticale
  Widget _buildBadgesSection(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      padding: spacing.allPadding,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor15,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppTheme.primaryColor15, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Text(
            'Statut',
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(14),
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: spacing.small),

          // ✅ MODIFIÉ: Container pour badges d'action prenant toute la largeur
          if (topBadges != null) ...[
            Container(
              width: double.infinity, // ✅ Prend toute la largeur
              padding: spacing.custom(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor15,
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
              child:
                  topBadges!, // Les badges s'affichent en Row mais dans un container full-width
            ),
            SizedBox(height: spacing.small),
          ],

          // ✅ MODIFIÉ: Container pour badge de statut prenant toute la largeur
          if (statusBadge != null)
            Container(
              width: double.infinity, // ✅ Prend toute la largeur
              padding: spacing.custom(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor15,
                borderRadius: BorderRadius.circular(responsive.spacing(8)),
              ),
              child: statusBadge!,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      children:
          details.entries
              .where((entry) => entry.key.toLowerCase() != 'id')
              .map((entry) => _buildDetailItem(entry, responsive, spacing))
              .toList(),
    );
  }

  Widget _buildDetailItem(
    MapEntry<String, String> entry,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.medium),
      padding: spacing.allPadding,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor15,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppTheme.primaryColor15, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: responsive.sp(14),
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: spacing.small),
          Container(
            width: double.infinity,
            padding: spacing.custom(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor15,
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            child: Text(
              entry.value.isNotEmpty ? entry.value : 'Non renseigné',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                fontSize: responsive.sp(14),
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

  Widget _buildActionButtons(
    BuildContext context,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Container(
      margin: EdgeInsets.only(top: spacing.large),
      child: SecondaryButton(
        text: 'Modifier',
        icon: Icons.edit,
        width: double.infinity,
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ModifyEquipmentScreen(
                    equipmentData: details,
                    equipmentAttributes: moreData,
                  ),
            ),
          );
        },
      ),
    );
  }
}

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
