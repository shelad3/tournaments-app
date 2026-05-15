import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static const String superAdminEmail = 'sheldonramu8@gmail.com';

  static UserRole _roleForEmail(String email) =>
      email == superAdminEmail ? UserRole.superAdmin : UserRole.user;

  static List<String> _permissionsForRole(UserRole role) {
    if (role == UserRole.superAdmin || role == UserRole.admin) {
      return ['manage_tournaments', 'manage_messages', 'manage_admins', 'view_participants'];
    }
    if (role == UserRole.subAdmin) {
      return ['manage_tournaments', 'manage_messages', 'view_participants'];
    }
    return [];
  }

  Future<UserModel?> signUp({
    required String fullName,
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final role = _roleForEmail(email);
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      username: username,
      phoneNumber: phoneNumber,
      role: role,
      permissions: _permissionsForRole(role),
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> updateUserRole(
    String uid,
    UserRole role,
    List<String> permissions, {
    int? maxEntryFee,
    int? maxDailyTournaments,
    bool approvalRequired = false,
  }) async {
    final data = <String, dynamic>{
      'role': role.name,
      'permissions': permissions,
    };
    if (role == UserRole.subAdmin) {
      data['maxEntryFee'] = maxEntryFee;
      data['maxDailyTournaments'] = maxDailyTournaments;
      data['approvalRequired'] = approvalRequired;
    } else {
      data['maxEntryFee'] = null;
      data['maxDailyTournaments'] = null;
      data['approvalRequired'] = false;
    }
    await _firestore.collection('users').doc(uid).update(data);
  }
}
