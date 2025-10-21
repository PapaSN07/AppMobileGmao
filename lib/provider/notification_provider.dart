import 'dart:async';
import 'package:appmobilegmao/models/notification_model.dart';
import 'package:appmobilegmao/services/websocket_service.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _unreadCountSubscription;

  List<NotificationModel> get notifications => _wsService.notifications;
  int get unreadCount => _wsService.unreadCount;
  bool get isConnected =>
      _wsService.isConnected; // ✅ Exposer l'état de connexion

  NotificationProvider() {
    _init();
  }

  void _init() {
    // Écouter les nouvelles notifications
    _notificationSubscription = _wsService.notificationStream.listen((
      notification,
    ) {
      notifyListeners();
    });

    // Écouter les changements du compteur
    _unreadCountSubscription = _wsService.unreadCountStream.listen((_) {
      notifyListeners();
    });
  }

  /// ✅ NOUVELLE MÉTHODE: Rafraîchir la connexion WebSocket
  Future<void> refreshConnection() async {
    try {
      if (kDebugMode) {
        print('🔄 NotificationProvider: Rafraîchissement de la connexion...');
      }

      // Si déjà connecté, reconnecter pour forcer la mise à jour
      if (_wsService.isConnected) {
        await _wsService.disconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Reconnecter
      await _wsService.connect();

      notifyListeners();

      if (kDebugMode) {
        print('✅ NotificationProvider: Connexion rafraîchie avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationProvider: Erreur lors du rafraîchissement: $e');
      }
      rethrow;
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(int notificationId) async {
    await _wsService.markAsRead(notificationId);
    notifyListeners();
  }

  /// Marquer toutes comme lues
  Future<void> markAllAsRead() async {
    await _wsService.markAllAsRead();
    notifyListeners();
  }

  /// Supprimer une notification
  void deleteNotification(int notificationId) {
    _wsService.deleteNotification(notificationId);
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
