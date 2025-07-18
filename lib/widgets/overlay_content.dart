import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

class OverlayContent extends StatelessWidget {
  final String title;
  final Map<String, String> details;
  final IconData? titleIcon;
  final VoidCallback? onClose;
  final List<OverlayAction>? actions;

  const OverlayContent({
    super.key,
    required this.title,
    required this.details,
    this.titleIcon,
    this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildContent(),
        if (actions != null && actions!.isNotEmpty) _buildActions(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Bouton retour
        _buildBackButton(context),
        const SizedBox(width: 12),

        // Titre
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onClose ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor15,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor15,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children:
          details.entries.map((entry) => _buildDetailItem(entry)).toList(),
    );
  }

  Widget _buildDetailItem(MapEntry<String, String> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor15,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor15,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            entry.key,
            style: const TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),

          // Valeur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor15,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.value.isNotEmpty ? entry.value : 'Non renseigné',
              style: TextStyle(
                fontFamily: AppTheme.fontRoboto,
                fontWeight: FontWeight.normal,
                fontSize: 14,
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

  Widget _buildActions() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions!.map((action) => _buildActionButton(action)).toList(),
      ),
    );
  }

  Widget _buildActionButton(OverlayAction action) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: action.onPressed,
          icon: Icon(
            action.icon,
            size: 18,
            color:
                action.isPrimary
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
          ),
          label: Text(
            action.label,
            style: TextStyle(
              fontFamily: AppTheme.fontMontserrat,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color:
                  action.isPrimary
                      ? AppTheme.secondaryColor
                      : AppTheme.primaryColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                action.isPrimary
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor15,
            elevation: action.isPrimary ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppTheme.primaryColor15,
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Classe pour les actions personnalisées
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
