import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _firestore.collection('users').doc(uid).update(data);

  Future<String?> uploadProfileImage(String uid, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) return 'TOO_LARGE';
      final ref = _storage.ref().child('profile_pics/$uid');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    final snap = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return snap.docs.isNotEmpty;
  }
}
