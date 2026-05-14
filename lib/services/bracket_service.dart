import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/participation_model.dart';

class BracketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _matchesRef(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).collection('matches');

  Stream<List<MatchModel>> getMatches(String tournamentId) =>
      _matchesRef(tournamentId)
          .orderBy('round', descending: true)
          .orderBy('position')
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());

  Future<List<MatchModel>> getMatchesOnce(String tournamentId) async {
    final snap = await _matchesRef(tournamentId)
        .orderBy('round', descending: true)
        .orderBy('position')
        .get();
    return snap.docs
        .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> generateBracket(
      String tournamentId, List<ParticipationModel> participants) async {
    final batch = _firestore.batch();
    final existing = await _matchesRef(tournamentId).get();
    for (var doc in existing.docs) {
      batch.delete(doc.reference);
    }

    final accepted = participants.where((p) => p.accepted && p.paid).toList();
    accepted.shuffle();

    final numParticipants = accepted.length;
    final numRounds = _numRounds(numParticipants);
    int totalMatches = (1 << (numRounds - 1));

    List<List<MatchModel?>> rounds = List.generate(numRounds, (_) => []);

    for (int r = 0; r < numRounds; r++) {
      int matchesInRound = totalMatches ~/ (1 << r);
      rounds[r] = List.filled(matchesInRound, null);
    }

    for (int i = 0; i < numParticipants; i += 2) {
      final pos = i ~/ 2;
      if (pos < rounds[0].length) {
        rounds[0][pos] = MatchModel(
          id: '',
          tournamentId: tournamentId,
          round: 0,
          position: pos,
          participant1Id: accepted[i].userId,
          participant1Team: accepted[i].teamName,
          participant2Id: i + 1 < numParticipants ? accepted[i + 1].userId : null,
          participant2Team: i + 1 < numParticipants ? accepted[i + 1].teamName : null,
        );
      }
    }

    for (int r = 1; r < numRounds; r++) {
      for (int p = 0; p < rounds[r].length; p++) {
        rounds[r][p] = MatchModel(
          id: '',
          tournamentId: tournamentId,
          round: r,
          position: p,
        );
      }
    }

    for (var round in rounds) {
      for (var match in round) {
        if (match != null) {
          final docRef = _matchesRef(tournamentId).doc();
          batch.set(docRef, match.toMap());
        }
      }
    }

    await batch.commit();
  }

  Future<void> setWinner(
      String tournamentId, String matchId, String winnerId, String winnerTeam) async {
    final match = await _matchesRef(tournamentId).doc(matchId).get();
    if (!match.exists) return;

    final data = match.data() as Map<String, dynamic>;
    await match.reference.update({
      'winnerId': winnerId,
      'completed': true,
    });

    final round = data['round'] as int;
    final position = data['position'] as int;

    final nextRound = round + 1;
    final nextPosition = position ~/ 2;

    final nextMatchSnap = await _matchesRef(tournamentId)
        .where('round', isEqualTo: nextRound)
        .where('position', isEqualTo: nextPosition)
        .get();

    if (nextMatchSnap.docs.isNotEmpty) {
      final nextMatchRef = nextMatchSnap.docs.first.reference;

      if (position % 2 == 0) {
        await nextMatchRef.update({
          'participant1Id': winnerId,
          'participant1Team': winnerTeam,
        });
      } else {
        await nextMatchRef.update({
          'participant2Id': winnerId,
          'participant2Team': winnerTeam,
        });
      }
    }
  }

  int _numRounds(int n) {
    if (n <= 1) return 1;
    int rounds = 0;
    int size = 1;
    while (size < n) {
      size <<= 1;
      rounds++;
    }
    return rounds;
  }
}
