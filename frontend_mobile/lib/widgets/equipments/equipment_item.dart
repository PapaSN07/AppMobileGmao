import 'package:flutter/material.dart';
import 'package:appmobilegmao/widgets/list_item.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

Widget buildEquipmentItem(
  Map<String, dynamic> equipment, {
  VoidCallback? onEdit,
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

  Widget? trailingAction;
  if (onEdit != null) {
    trailingAction = IconButton(
      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
      onPressed: onEdit,
      tooltip: 'Modifier',
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
  );
}
