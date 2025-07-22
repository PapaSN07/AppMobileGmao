import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';

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
  final Duration? duration;
  final bool showProgressBar;

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
    this.duration,
    this.showProgressBar = false,
  });

  // Factory constructors pour différents types
  factory NotificationBar.success({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onClose,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    bool showProgressBar = false,
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
      duration: duration,
      showProgressBar: showProgressBar,
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
    Duration? duration,
    bool showProgressBar = false,
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
      duration: duration,
      showProgressBar: showProgressBar,
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
    Duration? duration,
    bool showProgressBar = false,
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
      duration: duration,
      showProgressBar: showProgressBar,
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
    Duration? duration,
    bool showProgressBar = false,
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
      duration: duration,
      showProgressBar: showProgressBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _NotificationBarContent(
      title: title,
      message: message,
      type: type,
      onTap: onTap,
      onClose: onClose,
      showAction: showAction,
      actionText: actionText,
      onActionPressed: onActionPressed,
      duration: duration ?? const Duration(seconds: 4),
      showProgressBar: showProgressBar,
    );
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
  final Duration duration;
  final bool showProgressBar;

  const _NotificationBarContent({
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    this.onClose,
    required this.showAction,
    this.actionText,
    this.onActionPressed,
    required this.duration,
    required this.showProgressBar,
  });

  @override
  State<_NotificationBarContent> createState() =>
      _NotificationBarContentState();
}

class _NotificationBarContentState extends State<_NotificationBarContent>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de glissement
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    // Animation de progress bar
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Démarrer les animations
    _slideController.forward();
    if (widget.showProgressBar) {
      _progressController.forward();
    }

    // Auto-fermeture après la durée spécifiée
    if (widget.onClose != null) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _slideController.reverse();
    if (mounted && widget.onClose != null) {
      widget.onClose!();
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppTheme.successColor;
      case NotificationType.error:
        return AppTheme.errorColor;
      case NotificationType.warning:
        return AppTheme.warningColor;
      case NotificationType.info:
        return AppTheme.infoColor;
    }
  }

  // ignore: unused_element
  Color _getAccentColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppTheme.successColorDark;
      case NotificationType.error:
        return AppTheme.errorColorDark;
      case NotificationType.warning:
        return AppTheme.warningColorDark;
      case NotificationType.info:
        return AppTheme.infoColorDark;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16, // Respecter la safe area
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 120, // Limiter la hauteur
              minHeight: 80,
            ),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.notificationShadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIcon(),
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Contenu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTheme.notificationTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message,
                                    style: AppTheme.notificationMessage
                                        .copyWith(
                                          color: const Color.fromRGBO(255, 255, 255, 0.9),
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.showAction &&
                                  widget.actionText != null) ...[
                                TextButton(
                                  onPressed: widget.onActionPressed,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    widget.actionText!,
                                    style: AppTheme.notificationAction,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              if (widget.onClose != null)
                                GestureDetector(
                                  onTap: _dismiss,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(255, 255, 255, 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress bar
                  if (widget.showProgressBar)
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: const Color.fromRGBO(255, 255, 255, 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromRGBO(255, 255, 255, 0.7),
                          ),
                          minHeight: 2,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Service pour gérer les notifications
class NotificationService {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, NotificationBar notification) {
    // Supprimer la notification précédente si elle existe
    _currentOverlay?.remove();

    _currentOverlay = OverlayEntry(
      builder: (context) => Stack(children: [notification]),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    bool showProgressBar = true,
  }) {
    show(
      context,
      NotificationBar.success(
        title: title,
        message: message,
        onTap: onTap,
        onClose: () => _currentOverlay?.remove(),
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        showProgressBar: showProgressBar,
      ),
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    bool showProgressBar = true,
  }) {
    show(
      context,
      NotificationBar.error(
        title: title,
        message: message,
        onTap: onTap,
        onClose: () => _currentOverlay?.remove(),
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        showProgressBar: showProgressBar,
      ),
    );
  }

  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    bool showProgressBar = true,
  }) {
    show(
      context,
      NotificationBar.warning(
        title: title,
        message: message,
        onTap: onTap,
        onClose: () => _currentOverlay?.remove(),
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        showProgressBar: showProgressBar,
      ),
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
    bool showAction = false,
    String? actionText,
    VoidCallback? onActionPressed,
    Duration? duration,
    bool showProgressBar = true,
  }) {
    show(
      context,
      NotificationBar.info(
        title: title,
        message: message,
        onTap: onTap,
        onClose: () => _currentOverlay?.remove(),
        showAction: showAction,
        actionText: actionText,
        onActionPressed: onActionPressed,
        duration: duration,
        showProgressBar: showProgressBar,
      ),
    );
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
