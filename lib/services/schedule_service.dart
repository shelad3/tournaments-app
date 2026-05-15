import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _matchesRef(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).collection('matches');

  Future<void> proposeTime({
    required String tournamentId,
    required String matchId,
    required String userId,
    required DateTime time,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'proposedTime': Timestamp.fromDate(time),
      'proposedBy': userId,
      'scheduleStatus': 'proposed',
    });
  }

  Future<void> confirmTime({
    required String tournamentId,
    required String matchId,
    required DateTime time,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'scheduledTime': Timestamp.fromDate(time),
      'proposedTime': null,
      'proposedBy': null,
      'scheduleStatus': 'confirmed',
    });
  }

  Future<void> cancelProposal({
    required String tournamentId,
    required String matchId,
  }) async {
    await _matchesRef(tournamentId).doc(matchId).update({
      'proposedTime': null,
      'proposedBy': null,
      'scheduleStatus': 'none',
    });
  }

  Future<String?> getOpponentFcmToken({
    required String tournamentId,
    required String matchId,
    required String myUserId,
  }) async {
    final matchSnap = await _matchesRef(tournamentId).doc(matchId).get();
    if (!matchSnap.exists) return null;
    final data = matchSnap.data() as Map<String, dynamic>;
    final opponentId = data['participant1Id'] == myUserId
        ? data['participant2Id'] as String?
        : data['participant1Id'] as String?;
    if (opponentId == null) return null;
    final userSnap = await _firestore.collection('users').doc(opponentId).get();
    return userSnap.data()?['fcmToken'] as String?;
  }
}
