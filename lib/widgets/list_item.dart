import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/custom_overlay.dart';
import 'package:appmobilegmao/widgets/overlay_item.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

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
  final List<Map<String, dynamic>>? attributes;
  final Widget? topRightBadges; // ✅ Pour l'overlay uniquement
  final Widget? bottomLeftBadge; // ✅ Pour l'overlay uniquement

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
    this.attributes,
    this.topRightBadges,
    this.bottomLeftBadge,
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
    List<Map<String, dynamic>>? attributes,
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
        'ID': id ?? '',
        'Code': code,
        'Famille': famille,
        'Zone': zone,
        'Entité': entity,
        'Unité': unite,
        'Centre Charge': centre,
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
      attributes: attributes,
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

  // ✅ NOUVEAU: Constructeur pour l'historique
  factory ListItemCustom.history({
    required String? id,
    required String code,
    required String? famille,
    required String? zone,
    required String? entity,
    required String? unite,
    required String? centreCharge,
    required String? description,
    required String? codeParent,
    required String? feeder,
    required String? feederDescription,
    required String? localisation,
    required String? createdBy,
    required String? judgedBy,
    required String? commentaire,
    required String? status,
    required bool? isNew,
    required bool? isUpdate,
    required bool? isDeleted,
    required bool? isApproved,
    required bool? isRejected,
    required String? updatedAt,
    List<Map<String, dynamic>>? attributes,
    Widget? topRightBadges,
    Widget? bottomLeftBadge,
    VoidCallback? onTap,
  }) {
    return ListItemCustom(
      id: id,
      icon: Icons.history,
      primaryText: code,
      primaryLabel: 'Code',
      fields: [
        ItemField(label: 'Famille', value: famille ?? '-'),
        ItemField(label: 'Zone', value: zone ?? '-'),
        ItemField(label: 'Entité', value: entity ?? '-'),
        ItemField(label: 'Unité', value: unite ?? '-'),
      ],
      overlayDetails: {
        'ID': id ?? '',
        'Code': code,
        'Famille': famille ?? '-',
        'Zone': zone ?? '-',
        'Entité': entity ?? '-',
        'Unité': unite ?? '-',
        'Centre Charge': centreCharge ?? '-',
        'Code Parent': codeParent ?? '-',
        'Feeder': feeder ?? '-',
        'Feeder Description': feederDescription ?? '-',
        'Description': description ?? '-',
        'Localisation': localisation ?? '-',
        'Créé par': createdBy ?? '-',
        'Jugé par': judgedBy ?? '-',
        'Commentaire': commentaire ?? '-',
        'Statut': status ?? '-',
        'Mis à jour': updatedAt ?? '-',
        'Nouveau': isNew == true ? 'Oui' : 'Non',
        'Modifié': isUpdate == true ? 'Oui' : 'Non',
        'Supprimé': isDeleted == true ? 'Oui' : 'Non',
        'Approuvé': isApproved == true ? 'Oui' : 'Non',
        'Rejeté': isRejected == true ? 'Oui' : 'Non',
      },
      overlayTitle: 'Historique de l\'équipement',
      showModifyButton: false,
      onTap: onTap,
      attributes: attributes,
      topRightBadges: topRightBadges, // ✅ Passé à l'overlay
      bottomLeftBadge: bottomLeftBadge, // ✅ Passé à l'overlay
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return GestureDetector(
      onTap: onTap ?? () => _showOverlay(context),
      child: Container(
        padding: spacing.custom(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(responsive.spacing(20)),
        ),
        // ✅ MODIFIÉ: Supprimer le Stack et les badges
        child: Row(
          children: [
            _buildIcon(responsive, spacing),
            SizedBox(width: spacing.medium),
            Expanded(child: _buildContent(responsive, spacing)),
            _buildArrowIcon(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      width: responsive.spacing(56),
      height: responsive.spacing(56),
      decoration: BoxDecoration(
        color: iconColor ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(responsive.spacing(15)),
      ),
      child: Icon(
        icon,
        size: responsive.iconSize(30),
        color: backgroundColor ?? AppTheme.secondaryColor,
      ),
    );
  }

  Widget _buildContent(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimaryRow(responsive, spacing),
        ..._buildFieldRows(responsive, spacing),
      ],
    );
  }

  Widget _buildPrimaryRow(Responsive responsive, ResponsiveSpacing spacing) {
    return Row(
      children: [
        Text(
          '$primaryLabel:',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.primaryColor,
            fontSize: responsive.sp(18),
          ),
        ),
        SizedBox(width: spacing.small),
        Expanded(
          child: Text(
            primaryText,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppTheme.primaryColor,
              fontSize: responsive.sp(18),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFieldRows(
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    List<Widget> rows = [];

    for (int i = 0; i < fields.length; i += 2) {
      List<ItemField> rowFields = [];
      rowFields.add(fields[i]);
      if (i + 1 < fields.length) {
        rowFields.add(fields[i + 1]);
      }

      rows.add(_buildFieldRow(rowFields, responsive, spacing));
    }

    return rows;
  }

  Widget _buildFieldRow(
    List<ItemField> rowFields,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          rowFields
              .map((field) => _buildFieldItem(field, responsive, spacing))
              .toList(),
    );
  }

  Widget _buildFieldItem(
    ItemField field,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    return Expanded(
      child: Row(
        children: [
          Text(
            '${field.label}:',
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontWeight: FontWeight.normal,
              color: textColor ?? AppTheme.primaryColor,
              fontSize: responsive.sp(12),
            ),
          ),
          SizedBox(width: spacing.small),
          Expanded(
            child: Text(
              field.value,
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                color: textColor ?? AppTheme.primaryColor,
                fontSize: responsive.sp(12),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIcon(Responsive responsive) {
    return Transform(
      transform: Matrix4.rotationZ(-0.785398),
      alignment: Alignment.center,
      child: Icon(
        Icons.arrow_back,
        size: responsive.iconSize(24),
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
            moreData: attributes,
            titleIcon: icon,
            showModifyButton: showModifyButton,
            topBadges: topRightBadges, // ✅ Passé à l'overlay
            statusBadge: bottomLeftBadge, // ✅ Passé à l'overlay
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
