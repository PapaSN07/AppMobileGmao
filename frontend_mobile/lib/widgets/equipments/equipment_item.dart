import 'package:appmobilegmao/screens/equipments/modify_equipment_screen.dart';
import 'package:appmobilegmao/services/pending_equipment_changes.dart';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/equipments/equipment_badge.dart';

/// Carte d'un équipement. [showEditButton] : crayon qui ouvre le même écran de
/// modification que le bouton « Modifier » de la fiche bleue.
Widget buildEquipmentItem(
  Map<String, dynamic> equipment, {
  bool showEditButton = false,
}) {
  List<Map<String, dynamic>>? equipmentAttributes;
  try {
    if (equipment['attributes'] != null && equipment['attributes'] is List) {
      final attributesList = equipment['attributes'] as List;
      equipmentAttributes =
          attributesList
              .map((attr) {
                if (attr is Map<String, dynamic>) return attr;
                if (attr is Map) return Map<String, dynamic>.from(attr);
                try {
                  final dynamic attrObj = attr;
                  return <String, dynamic>{
                    'id': attrObj.id?.toString(),
                    'name': attrObj.name?.toString(),
                    'value': attrObj.value?.toString(),
                    'type': attrObj.type?.toString(),
                    'specification': attrObj.specification?.toString(),
                    'index': attrObj.index?.toString(),
                  };
                } catch (_) {
                  return <String, dynamic>{};
                }
              })
              .where((a) => a.isNotEmpty)
              .toList();
    }
  } catch (_) {
    equipmentAttributes = null;
  }

  final details = ListItemCustom.equipmentDetails(
    id: equipment['id']?.toString() ?? '',
    codeParent: equipment['codeParent'] ?? '',
    feeder: equipment['feeder'] ?? '',
    feederDescription: equipment['feederDescription'] ?? '',
    code: equipment['code'] ?? '',
    famille: equipment['famille'] ?? '',
    zone: equipment['zone'] ?? '',
    entity: equipment['entity'] ?? '',
    unite: equipment['unite'] ?? '',
    centre: equipment['centreCharge'] ?? '',
    description: equipment['description'] ?? '',
    longitude: equipment['longitude']?.toString() ?? '',
    latitude: equipment['latitude']?.toString() ?? '',
  );

  Widget? trailingAction;
  if (showEditButton) {
    trailingAction = Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
        tooltip: 'Modifier',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ModifyEquipmentScreen(
              equipmentData: details,
              equipmentAttributes: equipmentAttributes,
            ),
          ),
        ),
      ),
    );
  }

  // Modification envoyée depuis ce téléphone, pas encore validée
  final code = equipment['code']?.toString() ?? '';
  final pendingSince = PendingEquipmentChanges.pendingSince(code);
  Widget? pendingBadge;
  if (pendingSince != null) {
    String two(int n) => n.toString().padLeft(2, '0');
    pendingBadge = EquipmentBadge(
      label: 'En attente de validation · envoyé le ${two(pendingSince.day)}/${two(pendingSince.month)}',
      color: Colors.orange.shade800,
      icon: Icons.schedule,
    );
  }

  return ListItemCustom.equipment(
    id: equipment['id']?.toString() ?? '',
    codeParent: equipment['codeParent'] ?? '',
    feeder: equipment['feeder'] ?? '',
    feederDescription: equipment['feederDescription'] ?? '',
    code: equipment['code'] ?? '',
    famille: equipment['famille'] ?? '',
    zone: equipment['zone'] ?? '',
    entity: equipment['entity'] ?? '',
    unite: equipment['unite'] ?? '',
    centre: equipment['centreCharge'] ?? '',
    description: equipment['description'] ?? '',
    longitude: equipment['longitude']?.toString() ?? '',
    latitude: equipment['latitude']?.toString() ?? '',
    attributes: equipmentAttributes,
    trailing: trailingAction,
    statusBadge: pendingBadge,
  );
}
