import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDZt350FCdLMaiUfWPsamXPSQ0EEikC-_s',
      appId: '1:251119516995:android:50899eb37b25a1bcb303f6',
      messagingSenderId: '251119516995',
      projectId: 'fc-tournaments-bc93a',
      storageBucket: 'fc-tournaments-bc93a.firebasestorage.app',
    ),
  );
  runApp(const FCTournamentsApp());
}
