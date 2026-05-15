import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tab_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/message_provider.dart';
import 'providers/forum_provider.dart';
import 'providers/bracket_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/discover_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

class FCTournamentsApp extends StatelessWidget {
  const FCTournamentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
        ChangeNotifierProvider(create: (_) => BracketProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => DiscoverProvider()),
        ChangeNotifierProvider(create: (_) => AppLockProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (_, auth, theme, __) => MaterialApp(
          title: 'Tournaments',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
