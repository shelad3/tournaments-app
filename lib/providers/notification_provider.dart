import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void loadNotifications(String userId) {
    _isLoading = true;
    notifyListeners();
    _service.getNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.read).length;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _notifications.firstWhere((n) => n.id == notificationId).userId;
    await _service.markAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
    String? imageUrl,
  }) async {
    await _service.addNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedId: relatedId,
      imageUrl: imageUrl,
    );
  }
}
