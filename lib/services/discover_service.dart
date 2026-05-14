import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/follow_model.dart';

class DiscoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final snap = await _firestore.collection('users').get();
    final users = <UserModel>[];
    for (var doc in snap.docs) {
      final data = doc.data();
      final name = (data['fullName'] as String? ?? '').toLowerCase();
      final username = (data['username'] as String? ?? '').toLowerCase();
      final email = (data['email'] as String? ?? '').toLowerCase();
      if (name.contains(q) || username.contains(q) || email.contains(q)) {
        users.add(UserModel.fromMap(data, doc.id));
      }
    }
    return users;
  }

  Future<Set<String>> getFollowingIds(String userId) async {
    final snap = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .get();
    return snap.docs.map((d) => d.data()['followingId'] as String).toSet();
  }

  Future<void> follow(String followerId, String followingId) async {
    final existing = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _firestore.collection('follows').add(FollowModel(
      id: '',
      followerId: followerId,
      followingId: followingId,
    ).toMap());
  }

  Future<void> unfollow(String followerId, String followingId) async {
    final snap = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<int> getFollowersCount(String userId) async {
    final snap = await _firestore
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .get();
    return snap.docs.length;
  }

  Future<int> getFollowingCount(String userId) async {
    final snap = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .get();
    return snap.docs.length;
  }
}
