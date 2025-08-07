import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_overlay.dart';
import 'package:appmobilegmao/widgets/overlay_item.dart';

class ListItemCustom extends StatelessWidget {
  final String? id;
  final IconData icon;
  final String primaryText;
  final String primaryLabel;
  final List<ItemField> fields;
  final Map<String, String> overlayDetails;
  final String overlayTitle;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool showModifyButton;

  const ListItemCustom({
    super.key,
    this.id,
    required this.icon,
    required this.primaryText,
    required this.primaryLabel,
    required this.fields,
    required this.overlayDetails,
    this.overlayTitle = 'Détails',
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.showModifyButton = true,
  });

  // Constructeur pour les équipements
  factory ListItemCustom.equipment({
    String? id,
    required String codeParent,
    required String feeder,
    required String feederDescription,
    required String code,
    required String famille,
    required String zone,
    required String entity,
    required String unite,
    required String centre,
    required String description,
    required String longitude,
    required String latitude,
    bool showModifyButton = true,
    String overlayTitle = 'Détails de l\'équipement',
    VoidCallback? onTap,
  }) {
    return ListItemCustom(
      id: id,
      icon: Icons.settings,
      primaryText: code,
      primaryLabel: 'Code',
      fields: [
        ItemField(label: 'Famille', value: famille),
        ItemField(label: 'Zone', value: zone),
        ItemField(label: 'Entité', value: entity),
        ItemField(label: 'Unité', value: unite),
      ],
      overlayDetails: {
        'Code': code,
        'Famille': famille,
        'Zone': zone,
        'Entité': entity,
        'Unité': unite,
        'Centre': centre,
        'Code Parent': codeParent,
        'Feeder': feeder,
        'Feeder Description': feederDescription,
        'Description': description,
        'Longitude': longitude,
        'Latitude': latitude,
      },
      overlayTitle: overlayTitle,
      showModifyButton: showModifyButton,
      onTap: onTap,
    );
  }

  // Constructeur pour les ordres de travail
  factory ListItemCustom.order({
    String? id,
    required String code,
    required String famille,
    required String zone,
    required String entity,
    required String unite,
    required String centre,
    required String description,
    String overlayTitle = 'Détails de l\'ordre',
    VoidCallback? onTap,
  }) {
    return ListItemCustom(
      id: id,
      icon: Icons.assignment,
      primaryText: code,
      primaryLabel: 'Code',
      fields: [
        ItemField(label: 'Famille', value: famille),
        ItemField(label: 'Zone', value: zone),
        ItemField(label: 'Entité', value: entity),
        ItemField(label: 'Unité', value: unite),
      ],
      overlayDetails: {
        'Code': code,
        'Famille': famille,
        'Zone': zone,
        'Entité': entity,
        'Unité': unite,
        'Centre': centre,
        'Description': description,
      },
      overlayTitle: overlayTitle,
      showModifyButton: false,
      onTap: onTap,
    );
  }

  // Constructeur pour les demandes d'intervention
  factory ListItemCustom.intervention({
    String? id,
    required String code,
    required String famille,
    required String zone,
    required String entity,
    required String unite,
    required String centre,
    required String description,
    String overlayTitle = 'Détails de la demande',
    VoidCallback? onTap,
  }) {
    return ListItemCustom(
      id: id,
      icon: Icons.build,
      primaryText: code,
      primaryLabel: 'Code',
      fields: [
        ItemField(label: 'Famille', value: famille),
        ItemField(label: 'Zone', value: zone),
        ItemField(label: 'Entité', value: entity),
        ItemField(label: 'Unité', value: unite),
      ],
      overlayDetails: {
        'Code': code,
        'Famille': famille,
        'Zone': zone,
        'Entité': entity,
        'Unité': unite,
        'Centre': centre,
        'Description': description,
      },
      overlayTitle: overlayTitle,
      showModifyButton: false,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showOverlay(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 10),
            Expanded(child: _buildContent()),
            _buildArrowIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: iconColor ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        size: 30,
        color: backgroundColor ?? AppTheme.secondaryColor,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildPrimaryRow(), ..._buildFieldRows()],
    );
  }

  Widget _buildPrimaryRow() {
    return Row(
      children: [
        Text(
          '$primaryLabel:',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.primaryColor,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            primaryText,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppTheme.primaryColor,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFieldRows() {
    List<Widget> rows = [];

    // Grouper les champs par paires
    for (int i = 0; i < fields.length; i += 2) {
      List<ItemField> rowFields = [];
      rowFields.add(fields[i]);
      if (i + 1 < fields.length) {
        rowFields.add(fields[i + 1]);
      }

      rows.add(_buildFieldRow(rowFields));
    }

    return rows;
  }

  Widget _buildFieldRow(List<ItemField> rowFields) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rowFields.map((field) => _buildFieldItem(field)).toList(),
    );
  }

  Widget _buildFieldItem(ItemField field) {
    return Expanded(
      child: Row(
        children: [
          Text(
            '${field.label}:',
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontWeight: FontWeight.normal,
              color: textColor ?? AppTheme.primaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              field.value,
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                color: textColor ?? AppTheme.primaryColor,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIcon() {
    return Transform(
      transform: Matrix4.rotationZ(-0.785398),
      alignment: Alignment.center,
      child: Icon(
        Icons.arrow_back,
        size: 24,
        color: textColor ?? AppTheme.primaryColor,
      ),
    );
  }

  void _showOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomOverlay(
          onClose: () => Navigator.of(context).pop(),
          content: OverlayContent(
            title: overlayTitle,
            details: overlayDetails,
            titleIcon: icon,
            showModifyButton: showModifyButton,
            // actions: _buildOverlayActions(context),
          ),
        );
      },
    );
  }
}

// Classe pour représenter un champ
class ItemField {
  final String label;
  final String value;

  const ItemField({required this.label, required this.value});
}
