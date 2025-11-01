import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart'; // ✅ AJOUTÉ
import 'package:appmobilegmao/theme/responsive_spacing.dart'; // ✅ AJOUTÉ

/// ✅ Widget réutilisable pour filtrer par statut (style Senelec)
class StatusFilterButtons extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const StatusFilterButtons({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing; // ✅ AJOUTÉ

    return Row(
      children: [
        Expanded(
          child: _buildStatusButton(
            context: context,
            label: 'En cours',
            value: 'in_progress',
            icon: Icons.pending_actions,
            isSelected: selectedStatus == 'in_progress',
          ),
        ),
        SizedBox(width: spacing.medium), // ✅ MODIFIÉ: Espacement responsive
        Expanded(
          child: _buildStatusButton(
            context: context,
            label: 'Archivé',
            value: 'archived',
            icon: Icons.archive_outlined,
            isSelected: selectedStatus == 'archived',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
  }) {
    final responsive = context.responsive; // ✅ AJOUTÉ
    final spacing = context.spacing; // ✅ AJOUTÉ

    return GestureDetector(
      onTap: () => onStatusChanged(value),
      child: Container(
        height: responsive.spacing(48), // ✅ MODIFIÉ: Hauteur responsive
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(
            responsive.spacing(12), // ✅ MODIFIÉ: Border radius responsive
          ),
          border: Border.all(
            color: isSelected ? AppTheme.secondaryColor : AppTheme.thirdColor30,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.secondaryColor30,
                      blurRadius: responsive.spacing(
                        8,
                      ), // ✅ MODIFIÉ: Blur responsive
                      offset: Offset(
                        0,
                        responsive.spacing(2), // ✅ MODIFIÉ: Offset responsive
                      ),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.secondaryColor,
              size: responsive.iconSize(
                20,
              ), // ✅ MODIFIÉ: Taille icône responsive
            ),
            SizedBox(width: spacing.small), // ✅ MODIFIÉ: Espacement responsive
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                color: isSelected ? Colors.white : AppTheme.secondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: responsive.sp(
                  15,
                ), // ✅ MODIFIÉ: Taille texte responsive
              ),
            ),
          ],
        ),
      ),
    );
  }
}
