import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:appmobilegmao/utils/required_fields_manager.dart';

/// ✅ Widget réutilisable pour afficher les champs requis (DRY)
class RequiredFieldsBadge extends StatelessWidget {
  final RequiredFieldsConfig config;
  final VoidCallback? onViewDetails;

  const RequiredFieldsBadge({
    super.key,
    required this.config,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    if (config.famille.isEmpty) {
      return const SizedBox.shrink();
    }

    final requiredFieldsCount = _countRequiredFields();

    return Container(
      padding: spacing.custom(all: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor10,
        borderRadius: BorderRadius.circular(responsive.spacing(8)),
        border: Border.all(color: AppTheme.warningColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.warningColor,
            size: responsive.iconSize(20),
          ),
          SizedBox(width: spacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Champs obligatoires',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMontserrat,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                    fontSize: responsive.sp(14),
                  ),
                ),
                SizedBox(height: spacing.tiny),
                Text(
                  '$requiredFieldsCount champ${requiredFieldsCount > 1 ? 's' : ''} requis pour cette famille',
                  style: TextStyle(
                    fontFamily: AppTheme.fontRoboto,
                    color: AppTheme.warningColor,
                    fontSize: responsive.sp(12),
                  ),
                ),
              ],
            ),
          ),
          if (onViewDetails != null) ...[
            SizedBox(width: spacing.small),
            IconButton(
              onPressed: onViewDetails,
              icon: Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.warningColor,
                size: responsive.iconSize(16),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  int _countRequiredFields() {
    int count = 0;
    if (config.requiresFeeder) count++;
    if (config.requiresNaturePoste) count++;
    if (config.requiresCodeH) count++;
    if (config.requiresTension) count++;
    if (config.requiresCelluleType) count++;
    if (config.requiresClientName) count++;
    if (config.requiresPosteNames) count += 2;
    return count;
  }
}
