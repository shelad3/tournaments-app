import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkIn(String userId, String tournamentId) async {
    try {
      final snap = await _firestore
          .collection('participations')
          .where('userId', isEqualTo: userId)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();
      if (snap.docs.isEmpty) return false;
      await snap.docs.first.reference.update({'checkedIn': true});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> adminCheckIn(String userId, String tournamentId) async {
    return checkIn(userId, tournamentId);
  }

  Future<bool> undoCheckIn(String userId, String tournamentId) async {
    try {
      final snap = await _firestore
          .collection('participations')
          .where('userId', isEqualTo: userId)
          .where('tournamentId', isEqualTo: tournamentId)
          .get();
      if (snap.docs.isEmpty) return false;
      await snap.docs.first.reference.update({'checkedIn': false});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> checkedInCount(String tournamentId) async {
    final snap = await _firestore
        .collection('participations')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('accepted', isEqualTo: true)
        .where('checkedIn', isEqualTo: true)
        .get();
    return snap.docs.length;
  }

  Future<List<String>> getNoShowUserIds(String tournamentId) async {
    final snap = await _firestore
        .collection('participations')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('accepted', isEqualTo: true)
        .where('checkedIn', isEqualTo: false)
        .get();
    return snap.docs.map((d) => d.data()['userId'] as String).toList();
  }

  Future<void> replaceWithSubstitute(String tournamentId, String noShowUserId, String substituteUserId) async {
    final batch = _firestore.batch();

    final noShowSnap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: noShowUserId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    if (noShowSnap.docs.isNotEmpty) {
      batch.delete(noShowSnap.docs.first.reference);
    }

    final substituteSnap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: substituteUserId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    if (substituteSnap.docs.isNotEmpty) {
      batch.update(substituteSnap.docs.first.reference, {'accepted': true, 'checkedIn': true});
    }

    await batch.commit();
  }
}
