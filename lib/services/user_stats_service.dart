import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserStats {
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int prizeMoney;

  UserStats({
    this.tournamentsPlayed = 0,
    this.tournamentsWon = 0,
    this.prizeMoney = 0,
  });
}

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, userId);
  }

  Future<UserStats> getUserStats(String userId) async {
    final participationsSnap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: userId)
        .where('accepted', isEqualTo: true)
        .get();

    final played = participationsSnap.docs.length;
    int prizeMoney = 0;
    int won = 0;

    for (var pDoc in participationsSnap.docs) {
      final tournamentId = pDoc.data()['tournamentId'] as String;

      final matchesSnap = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .where('winnerId', isEqualTo: userId)
          .get();

      won += matchesSnap.docs.length;

      if (matchesSnap.docs.isNotEmpty) {
        final tDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
        if (tDoc.exists) {
          final tData = tDoc.data()!;
          if (tData['entryType'] == 'money') {
            final entryFee = (tData['entryFee'] ?? 0) as int;
            final paidSnap = await _firestore
                .collection('participations')
                .where('tournamentId', isEqualTo: tournamentId)
                .where('paid', isEqualTo: true)
                .get();
            prizeMoney += entryFee * paidSnap.docs.length;
          }
        }
      }
    }

    return UserStats(
      tournamentsPlayed: played,
      tournamentsWon: won,
      prizeMoney: prizeMoney,
    );
  }
}
