import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  runApp(const FCTournamentsApp());
}
