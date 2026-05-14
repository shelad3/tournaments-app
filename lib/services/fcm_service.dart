import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> saveTokenToFirestore(String userId) async {
    final token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  Future<void> removeTokenFromFirestore(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  void onForegroundMessage(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void onBackgroundMessage(BackgroundMessageHandler handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  void onMessageOpenedApp(void Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }
}
