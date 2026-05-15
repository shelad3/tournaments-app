import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_history_entry.dart';

class TournamentHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TournamentHistoryEntry>> getHistory(String userId) async {
    final participationsSnap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: userId)
        .where('accepted', isEqualTo: true)
        .get();

    final now = DateTime.now();
    final List<TournamentHistoryEntry> entries = [];

    for (var pDoc in participationsSnap.docs) {
      final tournamentId = pDoc.data()['tournamentId'] as String;
      final tDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
      if (!tDoc.exists) continue;

      final tData = tDoc.data()!;
      final endTime = (tData['endTime'] as dynamic)?.toDate();
      final startTime = (tData['startTime'] as dynamic)?.toDate();
      final hostDate = (tData['hostDate'] as dynamic).toDate();
      final effectiveEnd = endTime ?? (startTime ?? hostDate).add(const Duration(hours: 4));

      if (effectiveEnd.isAfter(now)) continue;

      final matchesSnap = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .where('winnerId', isEqualTo: userId)
          .get();

      final won = matchesSnap.docs.isNotEmpty;

      int prizeMoney = 0;
      if (won && tData['entryType'] == 'money') {
        final entryFee = (tData['entryFee'] ?? 0) as int;
        final paidSnap = await _firestore
            .collection('participations')
            .where('tournamentId', isEqualTo: tournamentId)
            .where('paid', isEqualTo: true)
            .get();
        prizeMoney = entryFee * paidSnap.docs.length;
      }

      entries.add(TournamentHistoryEntry(
        tournamentId: tournamentId,
        title: tData['title'] ?? '',
        date: effectiveEnd,
        gameName: tData['gameName'] ?? '',
        platform: tData['platform'],
        won: won,
        prizeMoney: prizeMoney,
        imageUrl: tData['imageUrl'],
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}
