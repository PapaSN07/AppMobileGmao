import 'package:flutter/material.dart';
import 'package:appmobilegmao/models/historique_equipment.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_badge.dart';
import 'package:intl/intl.dart';
import 'package:appmobilegmao/utils/responsive.dart'; // ✅ AJOUTÉ
import 'package:appmobilegmao/theme/responsive_spacing.dart'; // ✅ AJOUTÉ

/// ✅ Fonction pour construire un item d'historique (réutilise ListItemCustom)
Widget buildHistoryEquipmentItem(
  HistoriqueEquipment item, {
  VoidCallback? onTap,
}) {
  // Convertir les attributs
  List<Map<String, dynamic>>? historyAttributes;
  try {
    if (item.attributes != null && item.attributes!.isNotEmpty) {
      historyAttributes =
          item.attributes!.map((attr) {
            return {
              'id': attr.id?.toString(),
              'name': attr.name?.toString(),
              'value': attr.value?.toString(),
              'type': attr.type?.toString(),
              'specification': attr.specification?.toString(),
              'index': attr.index?.toString(),
            };
          }).toList();
    }
  } catch (_) {
    historyAttributes = null;
  }

  return ListItemCustom.history(
    id: item.equipmentId,
    code: item.code ?? '',
    famille: item.famille,
    zone: item.zone,
    entity: item.entity,
    unite: item.unite,
    centreCharge: item.centreCharge,
    description: item.description,
    codeParent: item.codeParent,
    feeder: item.feeder,
    feederDescription: item.feederDescription,
    localisation: item.localisation,
    createdBy: item.createdBy,
    judgedBy: item.judgedBy,
    commentaire: item.commentaire,
    status: item.status,
    isNew: item.isNew,
    isUpdate: item.isUpdate,
    isDeleted: item.isDeleted,
    isApproved: item.isApproved,
    isRejected: item.isRejected,
    updatedAt: item.updatedAt,
    attributes: historyAttributes,
    topRightBadges: _buildTopRightBadges(item),
    bottomLeftBadge: _buildStatusBadge(item),
    onTap: null,
  );
}

/// ✅ CORRIGÉ: Badges responsive en haut à droite (Nouveau/Modifié/Supprimé)
Widget _buildTopRightBadges(HistoriqueEquipment item) {
  final badges = <Widget>[];

  if (item.isNew == true) {
    badges.add(
      const EquipmentBadge(
        label: 'Nouveau',
        color: AppTheme.successColor,
        icon: Icons.fiber_new,
      ),
    );
  }
  if (item.isUpdate == true) {
    badges.add(
      // ✅ MODIFIÉ: Padding responsive
      Builder(
        builder: (context) {
          final spacing = context.spacing;
          return Padding(
            padding: EdgeInsets.only(left: spacing.tiny), // ✅ Responsive
            child: const EquipmentBadge(
              label: 'Modifié',
              color: AppTheme.warningColor,
              icon: Icons.edit,
            ),
          );
        },
      ),
    );
  }
  if (item.isDeleted == true) {
    badges.add(
      // ✅ MODIFIÉ: Padding responsive
      Builder(
        builder: (context) {
          final spacing = context.spacing;
          return Padding(
            padding: EdgeInsets.only(left: spacing.tiny), // ✅ Responsive
            child: const EquipmentBadge(
              label: 'Supprimé',
              color: AppTheme.errorColor,
              icon: Icons.delete,
            ),
          );
        },
      ),
    );
  }

  if (badges.isEmpty) return const SizedBox.shrink();

  return Row(mainAxisSize: MainAxisSize.min, children: badges);
}

/// ✅ CORRIGÉ: Badge de statut avec responsivité complète
Widget _buildStatusBadge(HistoriqueEquipment item) {
  return Builder(
    builder: (context) {
      final responsive = context.responsive;
      final spacing = context.spacing;

      IconData icon;
      String text;
      Color color;

      if (item.isApproved == true) {
        icon = Icons.check_circle;
        text = 'Approuvé';
        color = AppTheme.successColor;
      } else if (item.isRejected == true) {
        icon = Icons.cancel;
        text = 'Rejeté';
        color = AppTheme.errorColor;
      } else {
        icon = Icons.pending;
        text = 'En attente';
        color = AppTheme.warningColor;
      }

      // ✅ Ajouter date sur la même ligne
      if (item.updatedAt != null) {
        text += ' • ${_formatDate(item.updatedAt!)}';
      }

      return Container(
        padding: spacing.custom(
          horizontal: 10,
          vertical: 6,
        ), // ✅ MODIFIÉ: Padding responsive
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            responsive.spacing(12),
          ), // ✅ MODIFIÉ: Border radius responsive
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: responsive.iconSize(
                14,
              ), // ✅ MODIFIÉ: Taille d'icône responsive
              color: color,
            ),
            SizedBox(width: spacing.tiny), // ✅ MODIFIÉ: Espacement responsive
            Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontMontserrat,
                fontSize: responsive.sp(
                  12,
                ), // ✅ MODIFIÉ: Taille de texte responsive
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    },
  );
}

String _formatDate(String date) {
  try {
    final parsedDate = DateTime.parse(date);
    return DateFormat('dd/MM/yy').format(parsedDate);
  } catch (e) {
    try {
      return date.substring(0, 10);
    } catch (_) {
      return '';
    }
  }
}
