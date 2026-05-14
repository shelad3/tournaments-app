import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_lock_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    final ok = await context.read<AppLockProvider>().authenticate();
    if (mounted) {
      setState(() {
        _authenticating = false;
        if (!ok) _error = 'Authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white70),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to access the app',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 32),
              if (_authenticating)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _authenticate,
                    child: const Text('Try Again', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
