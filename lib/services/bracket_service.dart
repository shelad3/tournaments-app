import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/participation_model.dart';
import '../models/group_standing.dart';
import '../models/tournament_model.dart';

class BracketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _matchesRef(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).collection('matches');

  CollectionReference _standingsRef(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).collection('standings');

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

  Stream<List<GroupStanding>> getGroupStandings(String tournamentId, int groupIndex) =>
      _standingsRef(tournamentId)
          .where('groupIndex', isEqualTo: groupIndex)
          .orderBy('points', descending: true)
          .orderBy('goalDifference', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => GroupStanding.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());

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

  Future<void> generateGroupStage(
      String tournamentId, List<ParticipationModel> participants, int groupCount) async {
    final batch = _firestore.batch();

    final existing = await _matchesRef(tournamentId).get();
    for (var doc in existing.docs) {
      batch.delete(doc.reference);
    }
    final existingStandings = await _standingsRef(tournamentId).get();
    for (var doc in existingStandings.docs) {
      batch.delete(doc.reference);
    }

    final accepted = participants.where((p) => p.accepted && p.paid).toList();
    accepted.shuffle();

    final groups = <List<ParticipationModel>>[];
    for (int i = 0; i < groupCount; i++) {
      groups.add([]);
    }
    for (int i = 0; i < accepted.length; i++) {
      groups[i % groupCount].add(accepted[i]);
    }

    for (int g = 0; g < groups.length; g++) {
      final members = groups[g];
      for (int i = 0; i < members.length; i++) {
        final standingRef = _standingsRef(tournamentId).doc();
        batch.set(standingRef, GroupStanding(
          id: '',
          tournamentId: tournamentId,
          groupIndex: g,
          userId: members[i].userId,
          userName: members[i].teamName ?? members[i].userId,
        ).toMap());
      }

      int pos = 0;
      for (int i = 0; i < members.length; i++) {
        for (int j = i + 1; j < members.length; j++) {
          final matchRef = _matchesRef(tournamentId).doc();
          batch.set(matchRef, MatchModel(
            id: '',
            tournamentId: tournamentId,
            round: g,
            position: pos,
            participant1Id: members[i].userId,
            participant1Team: members[i].teamName,
            participant2Id: members[j].userId,
            participant2Team: members[j].teamName,
          ).toMap());
          pos++;
        }
      }
    }

    await batch.commit();
  }

  Future<void> advanceGroupWinners(
      String tournamentId, int groupCount, int advancePerGroup) async {
    final allStandings = await _standingsRef(tournamentId)
        .orderBy('groupIndex')
        .orderBy('points', descending: true)
        .orderBy('goalDifference', descending: true)
        .get();

    final advancing = <String>[];
    for (int g = 0; g < groupCount; g++) {
      final groupEntries = allStandings.docs
          .where((d) => (d.data() as Map)['groupIndex'] == g)
          .take(advancePerGroup);
      for (var entry in groupEntries) {
        advancing.add((entry.data() as Map)['userId'] as String);
      }
    }

    advancing.shuffle();
    final batch = _firestore.batch();
    final numParticipants = advancing.length;
    final numRounds = _numRounds(numParticipants);
    int totalMatches = (1 << (numRounds - 1));
    final playoffRound = groupCount;

    for (int i = 0; i < numParticipants; i += 2) {
      final pos = i ~/ 2;
      if (pos < totalMatches) {
        final matchRef = _matchesRef(tournamentId).doc();
        batch.set(matchRef, MatchModel(
          id: '',
          tournamentId: tournamentId,
          round: playoffRound,
          position: pos,
          participant1Id: advancing[i],
          participant2Id: i + 1 < numParticipants ? advancing[i + 1] : null,
        ).toMap());
      }
    }

    final playoffRounds = _numRounds(numParticipants);
    for (int r = 1; r < playoffRounds; r++) {
      int matchesInRound = totalMatches ~/ (1 << r);
      for (int p = 0; p < matchesInRound; p++) {
        final matchRef = _matchesRef(tournamentId).doc();
        batch.set(matchRef, MatchModel(
          id: '',
          tournamentId: tournamentId,
          round: playoffRound + r,
          position: p,
        ).toMap());
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

  Future<bool> shouldAutoGenerate(String tournamentId, int minParticipants, int maxParticipants) async {
    final snap = await _firestore
        .collection('participations')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('accepted', isEqualTo: true)
        .get();
    final count = snap.docs.length;
    return count >= (minParticipants > 0 ? minParticipants : 2) &&
        (maxParticipants == null || count >= maxParticipants);
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
