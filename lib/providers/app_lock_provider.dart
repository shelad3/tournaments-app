import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class AppLockProvider extends ChangeNotifier {
  static const _prefsKey = 'app_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isEnabled = false;
  bool _isAuthenticated = false;
  bool _biometricAvailable = false;

  bool get isEnabled => _isEnabled;
  bool get isAuthenticated => _isAuthenticated;
  bool get biometricAvailable => _biometricAvailable;

  AppLockProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefsKey) ?? false;
    await _checkBiometrics();
    notifyListeners();
  }

  Future<void> _checkBiometrics() async {
    try {
      _biometricAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      _biometricAvailable = false;
    }
  }

  Future<bool> authenticate() async {
    if (!_isEnabled) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    try {
      _isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      notifyListeners();
      return _isAuthenticated;
    } catch (_) {
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggle(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (!value) _isAuthenticated = false;
    notifyListeners();
  }

  void lock() {
    if (_isEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
