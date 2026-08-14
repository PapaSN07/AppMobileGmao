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
  final Widget? statusBadge; // ✅ Pour l'affichage principal
  final VoidCallback? onDetailsTap; // ✅ Bouton détails pour l'overlay
  final Widget? trailing;

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
    this.statusBadge,
    this.onDetailsTap,
    this.trailing,
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
    Widget? trailing,
  }) {
    return ListItemCustom(
      id: id,
      icon: Icons.settings,
      primaryText: code,
      primaryLabel: 'Code',
      fields: [
        ItemField(label: 'Famille', value: famille.trim().isEmpty ? '-' : famille),
        ItemField(label: 'Zone', value: zone.trim().isEmpty ? '-' : zone),
        ItemField(label: 'Entité', value: entity.trim().isEmpty ? '-' : entity),
        ItemField(label: 'Unité', value: unite.trim().isEmpty ? '-' : unite),
      ],
      overlayDetails: {
        'id': (id != null && id.isNotEmpty) ? id : code,
        'ID': (id != null && id.isNotEmpty) ? id : code,
        'code': code,
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
      trailing: trailing,
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
    String? status, // ✅ AJOUTÉ: Statut/État textuel de l'OT
    String overlayTitle = 'Détails de l\'ordre',
    VoidCallback? onTap,
    Widget? statusBadge,
    VoidCallback? onDetailsTap,
    Widget? trailing,
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
        if (status != null && status.isNotEmpty) 'État': status, // ✅ AJOUTÉ
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
      statusBadge: statusBadge,
      onDetailsTap: onDetailsTap,
      trailing: trailing,
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
    String? status,
    String overlayTitle = 'Détails de la demande',
    VoidCallback? onTap,
    VoidCallback? onDetailsTap,
    Widget? trailing,
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
        if (status != null && status.isNotEmpty) 'État': status,
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
      onDetailsTap: onDetailsTap,
      trailing: trailing,
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
        padding: spacing.custom(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(
            responsive.spacing(16),
          ),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIcon(responsive, spacing),
            SizedBox(width: spacing.medium),
            Expanded(child: _buildContent(responsive, spacing)),
            trailing ?? _buildArrowIcon(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Responsive responsive, ResponsiveSpacing spacing) {
    return Container(
      width: responsive.spacing(48),
      height: responsive.spacing(48),
      decoration: BoxDecoration(
        color: iconColor ?? const Color(0xFF0F1B80).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          responsive.spacing(12),
        ),
      ),
      child: Icon(
        icon,
        size: responsive.iconSize(24),
        color: const Color(0xFF0F1B80),
      ),
    );
  }

  Widget _buildContent(Responsive responsive, ResponsiveSpacing spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimaryRow(responsive, spacing),
        const SizedBox(height: 4),
        ..._buildFieldRows(responsive, spacing),
      ],
    );
  }

  Widget _buildPrimaryRow(Responsive responsive, ResponsiveSpacing spacing) {
    return Row(
      children: [
        Text(
          '$primaryLabel: ',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B1D4C),
            fontSize: responsive.sp(14),
          ),
        ),
        Expanded(
          child: Text(
            primaryText,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F1B80),
              fontSize: responsive.sp(14),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (statusBadge != null) ...[
          SizedBox(width: spacing.small),
          statusBadge!,
        ],
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
            '${field.label}: ',
            style: TextStyle(
              fontFamily: AppTheme.fontRoboto,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              fontSize: responsive.sp(12),
            ),
          ),
          Expanded(
            child: Text(
              field.value,
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
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
        size: responsive.iconSize(24), // ✅ Icône responsive
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
            onDetailsPressed: onDetailsTap, // ✅ Callback détails
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
