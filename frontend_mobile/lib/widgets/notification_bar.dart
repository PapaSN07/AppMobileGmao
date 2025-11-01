import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

enum NotificationType { success, error, warning, info }

class NotificationBar extends StatelessWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showProgressBar;
  final Duration? duration;

  const NotificationBar({
    super.key,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.onTap,
    this.onClose,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
    this.showProgressBar = false,
    this.duration,
  });

  // Constructeurs factory inchangés
  factory NotificationBar.success({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onClose,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    bool showProgressBar = false,
    Duration? duration,
  }) {
    return NotificationBar(
      title: title,
      message: message,
      type: NotificationType.success,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      showProgressBar: showProgressBar,
      duration: duration,
    );
  }

  factory NotificationBar.error({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onClose,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    bool showProgressBar = false,
    Duration? duration,
  }) {
    return NotificationBar(
      title: title,
      message: message,
      type: NotificationType.error,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      showProgressBar: showProgressBar,
      duration: duration,
    );
  }

  factory NotificationBar.warning({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onClose,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    bool showProgressBar = false,
    Duration? duration,
  }) {
    return NotificationBar(
      title: title,
      message: message,
      type: NotificationType.warning,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      showProgressBar: showProgressBar,
      duration: duration,
    );
  }

  factory NotificationBar.info({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onClose,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    bool showProgressBar = false,
    Duration? duration,
  }) {
    return NotificationBar(
      title: title,
      message: message,
      type: NotificationType.info,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      showProgressBar: showProgressBar,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retourner directement le contenu sans Positioned
    return _NotificationBarContent(
      title: title,
      message: message,
      type: type,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      showProgressBar: showProgressBar,
      duration: duration,
    );
  }

  // Méthodes helper pour les icônes et couleurs
  static IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  static Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return AppTheme.secondaryColor;
    }
  }
}

class _NotificationBarContent extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showProgressBar;
  final Duration? duration;

  const _NotificationBarContent({
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    this.onClose,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
    this.showProgressBar = false,
    this.duration,
  });

  @override
  State<_NotificationBarContent> createState() =>
      _NotificationBarContentState();
}

class _NotificationBarContentState extends State<_NotificationBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Démarrer l'animation d'entrée
    _animationController.forward();

    // Timer pour fermeture automatique (si duration est spécifiée)
    if (widget.duration != null) {
      _autoCloseTimer = Timer(widget.duration!, () {
        if (mounted && widget.onClose != null) {
          widget.onClose!();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: spacing.custom(
            horizontal: 16,
            vertical: 8,
          ), // ✅ Margin responsive
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              responsive.spacing(12),
            ), // ✅ Border radius responsive
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: responsive.spacing(8), // ✅ Blur radius responsive
                offset: Offset(0, responsive.spacing(4)), // ✅ Offset responsive
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenu principal
              Padding(
                padding: spacing.allPadding, // ✅ Padding responsive
                child: Row(
                  children: [
                    // Icône
                    Icon(
                      NotificationBar._getIcon(widget.type),
                      color: NotificationBar._getColor(widget.type),
                      size: responsive.iconSize(24), // ✅ Icône responsive
                    ),
                    SizedBox(width: spacing.medium), // ✅ Espacement responsive
                    // Contenu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                              fontSize: responsive.sp(16), // ✅ Texte responsive
                            ),
                          ),
                          SizedBox(
                            height: spacing.tiny,
                          ), // ✅ Espacement responsive
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMontserrat,
                              color: AppTheme.thirdColor,
                              fontSize: responsive.sp(14), // ✅ Texte responsive
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bouton d'action (optionnel)
                    if (widget.showAction && widget.actionText != null) ...[
                      SizedBox(width: spacing.small), // ✅ Espacement responsive
                      TextButton(
                        onPressed: widget.onActionPressed,
                        child: Text(
                          widget.actionText!,
                          style: TextStyle(
                            color: NotificationBar._getColor(widget.type),
                            fontWeight: FontWeight.w600,
                            fontSize: responsive.sp(14), // ✅ Texte responsive
                          ),
                        ),
                      ),
                    ],

                    // Bouton de fermeture
                    if (widget.onClose != null) ...[
                      SizedBox(width: spacing.small), // ✅ Espacement responsive
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                        iconSize: responsive.iconSize(20), // ✅ Icône responsive
                        color: AppTheme.thirdColor,
                      ),
                    ],
                  ],
                ),
              ),

              // Barre de progression (optionnelle)
              if (widget.showProgressBar)
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    NotificationBar._getColor(widget.type),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Service pour gérer les notifications avec Overlay
class NotificationService {
  static OverlayEntry? _currentOverlay;

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      NotificationBar.success(
        title: title,
        message: message,
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        onClose: () => _hideCurrentNotification(),
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 6),
  }) {
    _showNotification(
      context,
      NotificationBar.error(
        title: title,
        message: message,
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        onClose: () => _hideCurrentNotification(),
      ),
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 5),
    bool showProgressBar = false,
  }) {
    _showNotification(
      context,
      NotificationBar.warning(
        title: title,
        message: message,
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        showProgressBar: showProgressBar,
        onClose: () => _hideCurrentNotification(),
      ),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      NotificationBar.info(
        title: title,
        message: message,
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        onClose: () => _hideCurrentNotification(),
      ),
    );
  }

  static void _showNotification(
    BuildContext context,
    NotificationBar notification,
  ) {
    final responsive = Responsive.of(context);
    final spacing = ResponsiveSpacing.of(context);

    // Fermer la notification précédente si elle existe
    _hideCurrentNotification();

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            top: responsive.spacing(50), // ✅ Position top responsive
            left: spacing.medium, // ✅ Position left responsive
            right: spacing.medium, // ✅ Position right responsive
            child: Material(color: Colors.transparent, child: notification),
          ),
    );

    overlay.insert(_currentOverlay!);
  }

  static void _hideCurrentNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
