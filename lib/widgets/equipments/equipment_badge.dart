// lib/widgets/equipments/equipment_badge.dart
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

/// ✅ Badge réutilisable pour afficher un statut d'équipement (Nouveau/Modifié/Supprimé)
class EquipmentBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const EquipmentBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Container(
      padding: spacing.custom(
        horizontal: 8,
        vertical: 4,
      ), // ✅ MODIFIÉ: Padding responsive
      margin: EdgeInsets.only(
        right: spacing.tiny,
      ), // ✅ MODIFIÉ: Margin responsive
      decoration: BoxDecoration(
        color: AppTheme.primaryColor, // ✅ CORRIGÉ: Transparent au lieu de white
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: responsive.iconSize(
                14,
              ), // ✅ MODIFIÉ: Taille icône responsive
              color: color,
            ),
            SizedBox(
              width: spacing.tiny / 2,
            ), // ✅ MODIFIÉ: Espacement responsive (3px ≈ tiny/2)
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontSize: responsive.sp(12), // ✅ MODIFIÉ: Taille texte responsive
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none, // ✅ AJOUTÉ: Pas de soulignement
              decorationColor: Colors.transparent, // ✅ AJOUTÉ
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
