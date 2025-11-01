import 'package:appmobilegmao/models/notification_model.dart';
import 'package:appmobilegmao/provider/notification_provider.dart';
import 'package:appmobilegmao/screens/widgets/empty_notifications_screen.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/utils/responsive.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: AppTheme.fontMontserrat,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: responsive.sp(20),
          ),
        ),
        backgroundColor: AppTheme.secondaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: spacing.custom(all: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor20,
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: responsive.iconSize(20),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              if (notifProvider.unreadCount == 0) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: Container(
                  padding: spacing.custom(all: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor20,
                    borderRadius: BorderRadius.circular(responsive.spacing(8)),
                  ),
                  child: Icon(
                    Icons.done_all,
                    color: Colors.white,
                    size: responsive.iconSize(20),
                  ),
                ),
                onPressed: () async {
                  await notifProvider.markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Toutes les notifications ont été marquées comme lues',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(8),
                          ),
                        ),
                      ),
                    );
                  }
                },
                tooltip: 'Tout marquer comme lu',
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          final notifications = notifProvider.notifications;

          if (notifications.isEmpty) {
            return EmptyNotificationsScreen(
              onRefresh: () async {
                // ✅ CORRECTION: Appeler la méthode de rafraîchissement
                try {
                  await notifProvider.refreshConnection();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Connexion rafraîchie avec succès'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(8),
                          ),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors du rafraîchissement: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(8),
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
            );
          }

          return ListView.builder(
            padding: spacing.custom(all: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(
                context,
                notification,
                notifProvider,
                responsive,
                spacing,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
    Responsive responsive,
    ResponsiveSpacing spacing,
  ) {
    // ✅ VALIDATION: Vérifier que l'ID est valide
    if (notification.id <= 0) {
      if (kDebugMode) {
        print(
          '⚠️ NotificationCard: ID invalide (${notification.id}), carte ignorée',
        );
      }
      return const SizedBox.shrink();
    }

    // Déterminer l'icône et la couleur selon le type
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'success':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'error':
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'info':
      default:
        icon = Icons.info;
        iconColor = AppTheme.secondaryColor;
    }

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: spacing.custom(right: 20),
        margin: spacing.custom(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(responsive.spacing(12)),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: responsive.iconSize(30),
        ),
      ),
      onDismissed: (_) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification supprimée'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(responsive.spacing(8)),
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          // ✅ VALIDATION: Ne marquer comme lu que si l'ID est valide
          if (!notification.isRead && notification.id > 0) {
            try {
              await provider.markAsRead(notification.id);
              if (kDebugMode) {
                print('✅ Notification ${notification.id} marquée comme lue');
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Erreur lors du marquage: $e');
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        },
        child: Container(
          margin: spacing.custom(bottom: 12),
          padding: spacing.custom(all: 16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
            border: Border.all(
              color:
                  notification.isRead
                      ? AppTheme.thirdColor30
                      : AppTheme.secondaryColor30,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.boxShadowColor,
                blurRadius: responsive.spacing(10),
                offset: Offset(0, responsive.spacing(2)),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                padding: spacing.custom(all: 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive.spacing(10)),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: responsive.iconSize(28),
                ),
              ),
              SizedBox(width: spacing.medium),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                        fontFamily: AppTheme.fontMontserrat,
                      ),
                    ),
                    SizedBox(height: spacing.tiny),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        color: AppTheme.thirdColor,
                        fontFamily: AppTheme.fontRoboto,
                      ),
                    ),
                    SizedBox(height: spacing.tiny),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontFamily: AppTheme.fontRoboto,
                        color: AppTheme.thirdColor,
                        fontSize: responsive.sp(12),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
