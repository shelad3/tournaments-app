import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'referral_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    String? referredBy,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final role = _roleForEmail(email);
    final refService = ReferralService();
    final referralCode = refService.generateReferralCode(username, uid);
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      username: username,
      phoneNumber: phoneNumber,
      role: role,
      permissions: _permissionsForRole(role),
      referralCode: referralCode,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());

    if (referredBy != null && referredBy.isNotEmpty) {
      final referrerId = await refService.getReferrerIdByCode(referredBy);
      if (referrerId != null && referrerId != uid) {
        await refService.createReferral(
          referrerId: referrerId,
          referrerCode: referredBy.toUpperCase(),
          refereeId: uid,
          refereeName: fullName,
          refereeEmail: email,
        );
      }
    }

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

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;
    final email = userCredential.user!.email ?? '';
    final name = userCredential.user!.displayName ?? email.split('@').first;
    final photoUrl = userCredential.user!.photoURL;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }

    final role = _roleForEmail(email);
    final refService = ReferralService();
    final referralCode = refService.generateReferralCode(name.replaceAll(' ', '_'), uid);
    final user = UserModel(
      uid: uid,
      fullName: name,
      email: email,
      username: name.replaceAll(' ', '_').toLowerCase(),
      phoneNumber: '',
      photoUrl: photoUrl,
      role: role,
      permissions: _permissionsForRole(role),
      referralCode: referralCode,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) await user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException error) verificationFailed,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      codeSent: (verificationId, forceResendingToken) {
        codeSent(verificationId, forceResendingToken);
      },
      verificationFailed: verificationFailed,
      verificationCompleted: (credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            codeSent(userCredential.user!.uid, null);
          }
        } catch (_) {}
      },
      codeAutoRetrievalTimeout: (verificationId) {
        codeAutoRetrievalTimeout(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserModel?> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;
    final phone = userCredential.user!.phoneNumber ?? '';
    final name = userCredential.user!.displayName ?? 'User';
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    final refService = ReferralService();
    final referralCode = refService.generateReferralCode(name.replaceAll(' ', '_'), uid);
    final user = UserModel(
      uid: uid,
      fullName: name,
      email: userCredential.user!.email ?? '',
      username: name.replaceAll(' ', '_').toLowerCase(),
      phoneNumber: phone,
      role: _roleForEmail(userCredential.user!.email ?? ''),
      permissions: _permissionsForRole(_roleForEmail(userCredential.user!.email ?? '')),
      referralCode: referralCode,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

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
