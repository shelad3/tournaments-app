import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        if (auth.authResolved && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => auth.isLoggedIn ? const MainShell() : const LoginScreen(),
              ),
            );
          });
        }
        return Scaffold(
          backgroundColor: AppTheme.primaryColor,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_soccer, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Tournaments',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
