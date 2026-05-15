import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waiting_list_entry.dart';

class WaitingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> join(String userId, String tournamentId) async {
    try {
      final existing = await _firestore
          .collection('waiting_list')
          .where('userId', isEqualTo: userId)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();
      if (existing.docs.isNotEmpty) return false;

      await _firestore.collection('waiting_list').add({
        'userId': userId,
        'tournamentId': tournamentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> leave(String userId, String tournamentId) async {
    final snap = await _firestore
        .collection('waiting_list')
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<int> position(String userId, String tournamentId) async {
    final all = await _firestore
        .collection('waiting_list')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt')
        .get();
    for (int i = 0; i < all.docs.length; i++) {
      if (all.docs[i].data()['userId'] == userId) return i + 1;
    }
    return 0;
  }

  Future<int> waitingCount(String tournamentId) async {
    final snap = await _firestore
        .collection('waiting_list')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    return snap.docs.length;
  }

  Future<String?> promoteNext(String tournamentId) async {
    final snap = await _firestore
        .collection('waiting_list')
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final userId = snap.docs.first.data()['userId'] as String;
    await snap.docs.first.reference.delete();
    return userId;
  }

  Future<bool> isInWaitingList(String userId, String tournamentId) async {
    final snap = await _firestore
        .collection('waiting_list')
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Stream<int> waitingCountStream(String tournamentId) =>
      _firestore
          .collection('waiting_list')
          .where('tournamentId', isEqualTo: tournamentId)
          .snapshots()
          .map((snap) => snap.docs.length);
}
