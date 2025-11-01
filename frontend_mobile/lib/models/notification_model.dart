import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final int id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String title;
  final String message;
  final String type; // success, error, warning, info
  final DateTime timestamp;
  @JsonKey(name: 'is_read')
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  /// Créer une copie avec des modifications
  NotificationModel copyWith({
    int? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // ✅ CORRECTION: Parsing robuste avec génération d'ID si manquant
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Vérifier si l'ID existe, sinon générer un ID temporaire
    final rawId = json['id'];
    final int notificationId;

    if (rawId == null) {
      // Générer un ID basé sur le timestamp actuel
      notificationId = DateTime.now().millisecondsSinceEpoch;
      if (kDebugMode) {
        print(
          '⚠️ NotificationModel: ID manquant, génération locale: $notificationId',
        );
      }
    } else if (rawId is int) {
      notificationId = rawId;
    } else if (rawId is String) {
      notificationId =
          int.tryParse(rawId) ?? DateTime.now().millisecondsSinceEpoch;
    } else {
      notificationId = DateTime.now().millisecondsSinceEpoch;
    }

    return NotificationModel(
      id: notificationId,
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
