import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _userSub;

  UserModel? get user => _user;
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get isSubAdmin => _user?.isSubAdmin ?? false;
  bool get isFullAdmin => _user?.isFullAdmin ?? false;

  bool _authResolved = false;

  bool get authResolved => _authResolved;

  AuthProvider() {
    _authService.authState.listen(_onAuthStateChanged);
  }

  void _forceSuperAdmin() {
    if (_user != null && _user!.email == AuthService.superAdminEmail && _user!.role != UserRole.superAdmin) {
      _user = UserModel(
        uid: _user!.uid,
        fullName: _user!.fullName,
        email: _user!.email,
        username: _user!.username,
        phoneNumber: _user!.phoneNumber,
        photoUrl: _user!.photoUrl,
        favoriteTeam: _user!.favoriteTeam,
        favoriteGames: _user!.favoriteGames,
        role: UserRole.superAdmin,
        permissions: const ['manage_tournaments', 'manage_messages', 'manage_admins', 'view_participants'],
        emailVerified: _user!.emailVerified,
        createdAt: _user!.createdAt,
      );
    }
  }

  void _listenToUserDoc(String uid) {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!, doc.id);
        _forceSuperAdmin();
        _authResolved = true;
        notifyListeners();
      }
    });
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userSub?.cancel();
      _userSub = null;
      _user = null;
      _authResolved = true;
      notifyListeners();
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!, doc.id);
      _forceSuperAdmin();
    }
    _authResolved = true;
    notifyListeners();
    _listenToUserDoc(firebaseUser.uid);
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signUp(
        fullName: fullName,
        email: email,
        username: username,
        phoneNumber: phoneNumber,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(email: email, password: password);
      _forceSuperAdmin();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<bool> checkEmailVerification() async {
    final verified = await _authService.isEmailVerified();
    if (verified && _user != null && !_user!.emailVerified) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'emailVerified': true});
      _user = UserModel(
        uid: _user!.uid,
        fullName: _user!.fullName,
        email: _user!.email,
        username: _user!.username,
        phoneNumber: _user!.phoneNumber,
        photoUrl: _user!.photoUrl,
        favoriteTeam: _user!.favoriteTeam,
        favoriteGames: _user!.favoriteGames,
        role: _user!.role,
        permissions: _user!.permissions,
        maxEntryFee: _user!.maxEntryFee,
        maxDailyTournaments: _user!.maxDailyTournaments,
        approvalRequired: _user!.approvalRequired,
        emailVerified: true,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    }
    return verified;
  }

  Future<void> loadAllUsers() async {
    _allUsers = await _authService.getAllUsers();
    notifyListeners();
  }

  Future<void> updateUserRole(
    String uid,
    UserRole role,
    List<String> permissions, {
    int? maxEntryFee,
    int? maxDailyTournaments,
    bool approvalRequired = false,
  }) async {
    await _authService.updateUserRole(
      uid, role, permissions,
      maxEntryFee: maxEntryFee,
      maxDailyTournaments: maxDailyTournaments,
      approvalRequired: approvalRequired,
    );
    await loadAllUsers();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!, doc.id);
      _forceSuperAdmin();
      notifyListeners();
    }
  }
}
