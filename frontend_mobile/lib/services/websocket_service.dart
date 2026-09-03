import 'dart:async';
import 'dart:convert';
import 'package:appmobilegmao/models/notification_model.dart';
import 'package:appmobilegmao/services/api_service.dart';
import 'package:appmobilegmao/services/hive_service.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/material.dart';

class WebSocketService {
  static final _apiService = ApiService();

  // ✅ CORRECTION: Utiliser la même IP que ApiService
  static String get macIpAddress => _apiService.macIpAddress;
  static int get defaultPort => _apiService.defaultPort;

  // ✅ CORRECTION: Construire l'URL WebSocket correctement
  static String get _wsBaseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty && Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1'
          ? Uri.base.host
          : macIpAddress;
      return 'ws://$host:$defaultPort';
    }
    // ✅ Pour Android/iOS: utiliser l'IP du serveur
    return 'ws://$macIpAddress:$defaultPort';
  }

  static const String _wsPath = '/ws/notifications';
  static const Duration _reconnectDelay = Duration(
    seconds: 5,
  ); // ✅ Augmenté à 5s
  static const int _maxReconnectAttempts = 5;

  // ✅ État interne
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  bool _isManualDisconnect = false;
  bool _isConnected = false; // ✅ AJOUTÉ: Flag pour tracker la connexion

  // ✅ Stream pour diffuser les notifications
  final _notificationController =
      StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;

  // ✅ Liste des notifications en mémoire
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  // ✅ Compteur de notifications non lues
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ✅ Stream pour notifier les changements du compteur
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // ✅ Getter pour vérifier si connecté
  bool get isConnected => _isConnected;

  // ✅ Singleton
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // ✅ Se connecter au WebSocket
  Future<void> connect() async {
    // ✅ CORRECTION: Vérifier si déjà connecté
    if (_isConnected && _channel != null) {
      if (kDebugMode) {
        print('✅ WebSocket: Déjà connecté');
      }
      return;
    }

    if (_isConnecting) {
      if (kDebugMode) {
        print('⚠️ WebSocket: Connexion en cours...');
      }
      return;
    }

    _isConnecting = true;
    _isManualDisconnect = false;

    try {
      // Récupérer le token JWT
      final token = await HiveService.getAccessToken();

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('❌ WebSocket: Token JWT manquant');
        }
        _isConnecting = false;
        return;
      }

      // ✅ CORRECTION: Construire l'URL avec l'IP correcte
      final wsUrl = '$_wsBaseUrl$_wsPath?token=$token';

      if (kDebugMode) {
        print('🔌 WebSocket: Tentative de connexion à $wsUrl');
      }

      // ✅ CORRECTION: Ajouter un timeout pour la connexion
      try {
        _channel = WebSocketChannel.connect(
          Uri.parse(wsUrl),
          protocols: ['websocket'], // ✅ AJOUTÉ: Spécifier le protocole
        );

        // ✅ CORRECTION: Attendre la connexion avec timeout
        await _channel!.ready.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('WebSocket connection timeout');
          },
        );

        // ✅ La connexion est établie
        _isConnected = true;
        _reconnectAttempts = 0;
        _isConnecting = false;

        if (kDebugMode) {
          print('✅ WebSocket: Connecté avec succès');
        }

        // Écouter les messages
        _messageSubscription = _channel!.stream.listen(
          _handleMessage,
          onError: _handleError,
          onDone: _handleDone,
          cancelOnError: false,
        );

        // Démarrer le ping pour maintenir la connexion active
        _startPingTimer();
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('❌ WebSocket: Timeout de connexion: $e');
        }
        _cleanup();
        _isConnecting = false;
        _scheduleReconnect();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket: Erreur de connexion: $e');
      }
      _cleanup();
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  // ✅ Gérer les messages entrants
  void _handleMessage(dynamic message) {
    try {
      if (kDebugMode) {
        print('📨 WebSocket: Message reçu: $message');
      }

      final data = jsonDecode(message as String);

      // ✅ Filtrer les messages de contrôle
      final messageType = data['type']?.toString().toLowerCase();
      if (messageType == 'connected' ||
          messageType == 'pong' ||
          messageType == 'ping') {
        if (kDebugMode) {
          print('🔔 WebSocket: Message de contrôle ignoré - $messageType');
        }
        return;
      }

      // ✅ Vérifier que c'est une vraie notification
      if (data['title'] == null || data['message'] == null) {
        if (kDebugMode) {
          print('⚠️ WebSocket: Message incomplet, ignoré');
        }
        return;
      }

      // ✅ Générer ID si manquant
      if (data['id'] == null) {
        data['id'] = DateTime.now().millisecondsSinceEpoch;
        if (kDebugMode) {
          print('⚠️ WebSocket: ID généré localement: ${data['id']}');
        }
      }

      // Créer et valider la notification
      final notification = NotificationModel.fromJson(data);
      if (notification.id <= 0) {
        if (kDebugMode) {
          print('❌ WebSocket: ID invalide, notification ignorée');
        }
        return;
      }

      // Ajouter la notification
      _notifications.insert(0, notification);
      _notificationController.add(notification);
      _unreadCountController.add(unreadCount);
      _showNotificationToast(notification);

      if (kDebugMode) {
        print('✅ WebSocket: Notification traitée - ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket: Erreur traitement: $e');
      }
    }
  }

  // ✅ Afficher la notification comme toast
  void _showNotificationToast(NotificationModel notification) {
    // Déterminer l'icône et la couleur selon le type
    IconData icon;
    Color backgroundColor;

    switch (notification.type) {
      case 'success':
        icon = Icons.check_circle;
        backgroundColor = Colors.green;
        break;
      case 'error':
        icon = Icons.error;
        backgroundColor = Colors.red;
        break;
      case 'warning':
        icon = Icons.warning;
        backgroundColor = Colors.orange;
        break;
      case 'info':
      default:
        icon = Icons.info;
        backgroundColor = AppTheme.secondaryColor;
    }

    showSimpleNotification(
      Text(
        notification.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontMontserrat,
        ),
      ),
      subtitle: Text(
        notification.message,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: AppTheme.fontRoboto,
        ),
      ),
      background: backgroundColor,
      leading: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 4),
      slideDismissDirection: DismissDirection.up,
    );
  }

  // ✅ Gérer les erreurs
  void _handleError(error) {
    if (kDebugMode) {
      print('❌ WebSocket: Erreur: $error');
    }
    _isConnected = false;
    _scheduleReconnect();
  }

  // ✅ Gérer la déconnexion
  void _handleDone() {
    if (kDebugMode) {
      print('🔌 WebSocket: Connexion fermée');
    }

    _isConnected = false;
    _cleanup();

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  // ✅ Planifier la reconnexion
  void _scheduleReconnect() {
    if (_isManualDisconnect || _isConnecting) return;

    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ WebSocket: Nombre max de tentatives de reconnexion atteint');
      }
      return;
    }

    if (kDebugMode) {
      print(
        '🔄 WebSocket: Tentative de reconnexion $_reconnectAttempts/$_maxReconnectAttempts dans ${_reconnectDelay.inSeconds}s',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isManualDisconnect && !_isConnected) {
        connect();
      }
    });
  }

  // ✅ Envoyer un ping pour maintenir la connexion
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
          if (kDebugMode) {
            print('🏓 WebSocket: Ping envoyé');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ WebSocket: Erreur lors de l\'envoi du ping: $e');
          }
          _isConnected = false;
          timer.cancel();
          _scheduleReconnect();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // ✅ Marquer une notification comme lue
  Future<void> markAsRead(int notificationId) async {
    // ✅ VALIDATION: Vérifier que l'ID est valide
    if (notificationId <= 0) {
      if (kDebugMode) {
        print(
          '❌ WebSocket: ID invalide ($notificationId), impossible de marquer comme lu',
        );
      }
      return;
    }

    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        print('⚠️ WebSocket: Non connecté, impossible de marquer comme lu');
      }
      // Mettre à jour localement quand même
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCountController.add(unreadCount);
      }
      return;
    }

    try {
      // Envoyer le message au serveur
      _channel!.sink.add(
        jsonEncode({
          'action': 'mark_as_read',
          'notification_id': notificationId,
        }),
      );

      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCountController.add(unreadCount);
      }

      if (kDebugMode) {
        print('✅ WebSocket: Notification $notificationId marquée comme lue');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket: Erreur lors du marquage comme lu: $e');
      }
    }
  }

  // ✅ Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        print(
          '⚠️ WebSocket: Non connecté, impossible de marquer tout comme lu',
        );
      }
      // Mettre à jour localement quand même
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCountController.add(0);
      return;
    }

    try {
      // Envoyer le message au serveur
      _channel!.sink.add(jsonEncode({'action': 'mark_all_as_read'}));

      // Mettre à jour localement
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCountController.add(0);

      if (kDebugMode) {
        print('✅ WebSocket: Toutes les notifications marquées comme lues');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket: Erreur lors du marquage global: $e');
      }
    }
  }

  // ✅ Supprimer une notification
  void deleteNotification(int notificationId) {
    // ✅ VALIDATION: Vérifier que l'ID est valide
    if (notificationId <= 0) {
      if (kDebugMode) {
        print(
          '❌ WebSocket: ID invalide ($notificationId), impossible de supprimer',
        );
      }
      return;
    }

    _notifications.removeWhere((n) => n.id == notificationId);
    _unreadCountController.add(unreadCount);

    if (kDebugMode) {
      print('🗑️ WebSocket: Notification $notificationId supprimée');
    }
  }

  // ✅ Nettoyer les ressources
  void _cleanup() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel = null;
    _isConnected = false;
  }

  // ✅ Se déconnecter manuellement
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('🔌 WebSocket: Déconnexion manuelle');
    }

    _isManualDisconnect = true;
    _isConnected = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    try {
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ WebSocket: Erreur lors de la fermeture: $e');
      }
    } finally {
      _cleanup();
    }
  }

  // ✅ Nettoyer complètement le service
  void dispose() {
    disconnect();
    _notificationController.close();
    _unreadCountController.close();
    _notifications.clear();

    if (kDebugMode) {
      print('🗑️ WebSocket: Service disposed');
    }
  }
}
