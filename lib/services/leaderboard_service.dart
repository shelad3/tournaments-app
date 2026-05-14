import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_model.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final tournamentsSnap = await _firestore.collection('tournaments').get();
    final Map<String, int> wins = {};
    final Map<String, int> prizeMoney = {};

    for (var tDoc in tournamentsSnap.docs) {
      final tData = tDoc.data();
      final isMoney = tData['entryType'] == 'money';
      final entryFee = (tData['entryFee'] ?? 0) as int;

      int paidCount = 0;
      if (isMoney) {
        final partsSnap = await _firestore
            .collection('participations')
            .where('tournamentId', isEqualTo: tDoc.id)
            .where('paid', isEqualTo: true)
            .get();
        paidCount = partsSnap.docs.length;
      }

      final matchesSnap = await _firestore
          .collection('tournaments')
          .doc(tDoc.id)
          .collection('matches')
          .where('completed', isEqualTo: true)
          .get();

      for (var mDoc in matchesSnap.docs) {
        final mData = mDoc.data();
        final winnerId = mData['winnerId'] as String?;
        if (winnerId != null && winnerId.isNotEmpty) {
          wins[winnerId] = (wins[winnerId] ?? 0) + 1;
          if (isMoney && paidCount > 0) {
            prizeMoney[winnerId] =
                (prizeMoney[winnerId] ?? 0) + (entryFee * paidCount);
          }
        }
      }
    }

    final userIds = {...wins.keys, ...prizeMoney.keys};

    final Map<String, UserModel> users = {};
    for (var uid in userIds) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        users[uid] = UserModel.fromMap(userDoc.data()!, uid);
      }
    }

    final entries = userIds.map((uid) {
      final user = users[uid];
      return LeaderboardEntry(
        userId: uid,
        userName: user?.username ?? user?.fullName ?? 'Unknown',
        userTeam: user?.favoriteTeam,
        wins: wins[uid] ?? 0,
        prizeMoney: prizeMoney[uid] ?? 0,
        rank: 0,
      );
    }).toList();

    entries.sort((a, b) {
      final winCmp = b.wins.compareTo(a.wins);
      if (winCmp != 0) return winCmp;
      return b.prizeMoney.compareTo(a.prizeMoney);
    });

    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        userId: entries[i].userId,
        userName: entries[i].userName,
        userTeam: entries[i].userTeam,
        wins: entries[i].wins,
        prizeMoney: entries[i].prizeMoney,
        rank: i + 1,
      );
    }

    return entries;
  }

  Future<LeaderboardEntry?> getUserRank(String userId) async {
    final entries = await getLeaderboard();
    try {
      return entries.firstWhere((e) => e.userId == userId);
    } catch (_) {
      return null;
    }
  }
}
