import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppNotification>> getNotifications(String userId) =>
      _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
              .toList());

  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
    String? imageUrl,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .add(AppNotification(
          id: '',
          userId: userId,
          type: type,
          title: title,
          body: body,
          relatedId: relatedId,
          imageUrl: imageUrl,
        ).toMap());
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<int> getUnreadCount(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    return snap.docs.length;
  }
}
