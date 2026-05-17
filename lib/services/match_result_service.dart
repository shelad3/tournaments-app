import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/match_result_model.dart';
import 'referral_service.dart';

class MatchResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _matchesRef(String tournamentId) =>
      _firestore.collection('tournaments').doc(tournamentId).collection('matches');

  Future<void> reportResult({
    required String tournamentId,
    required MatchModel match,
    required String userId,
    required String result,
  }) async {
    final ref = _matchesRef(tournamentId).doc(match.id);

    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final currentStatus = reportStatusFromJson(data['reportStatus']);
    final existingResult1 = data['result1'] as String?;
    final existingResult2 = data['result2'] as String?;

    final isP1 = userId == match.participant1Id;
    final isP2 = userId == match.participant2Id;
    if (!isP1 && !isP2) return;

    if (currentStatus == MatchReportStatus.confirmed || currentStatus == MatchReportStatus.disputed) return;

    String? newResult1 = existingResult1;
    String? newResult2 = existingResult2;
    MatchReportStatus newStatus;

    if (isP1) {
      newResult1 = result;
      newStatus = existingResult2 != null ? MatchReportStatus.confirmed : MatchReportStatus.p1Reported;
    } else {
      newResult2 = result;
      newStatus = existingResult1 != null ? MatchReportStatus.confirmed : MatchReportStatus.p2Reported;
    }

    await ref.update({
      'result1': newResult1,
      'result2': newResult2,
      'reportStatus': reportStatusToJson(newStatus),
    });

    if (newStatus == MatchReportStatus.confirmed && newResult1 != null && newResult2 != null) {
      final resolved = _resolveResult(newResult1, newResult2, match);
      if (resolved != null) {
        if (resolved == MatchResultType.draw) {
          await ref.update({'completed': true, 'winnerId': null});
        } else {
          final winnerId = resolved == MatchResultType.p1Won ? match.participant1Id : match.participant2Id;
          final winnerTeam = resolved == MatchResultType.p1Won ? match.participant1Team : match.participant2Team;

          final matchData = await ref.get();
          if (!matchData.exists) return;
          await ref.update({
            'winnerId': winnerId,
            'completed': true,
          });

          if (winnerId != null) {
            await _advanceWinner(tournamentId, match, winnerId, winnerTeam);
          }

          final referralService = ReferralService();
          final futures = <Future<void>>[];
          if (match.participant1Id != null) {
            futures.add(referralService.checkAndAwardReferralBonus(match.participant1Id!));
          }
          if (match.participant2Id != null) {
            futures.add(referralService.checkAndAwardReferralBonus(match.participant2Id!));
          }
          await Future.wait(futures);
        }
      } else {
        await ref.update({
          'reportStatus': reportStatusToJson(MatchReportStatus.disputed),
        });
      }
    }
  }

  MatchResultType? _resolveResult(String r1, String r2, MatchModel match) {
    if (r1 == r2 && r1 == 'draw') return MatchResultType.draw;
    if (r1 == 'won' && r2 == 'lost') return MatchResultType.p1Won;
    if (r1 == 'lost' && r2 == 'won') return MatchResultType.p2Won;
    return null;
  }

  Future<void> _advanceWinner(
    String tournamentId,
    MatchModel match,
    String winnerId,
    String? winnerTeam,
  ) async {
    final round = match.round;
    final position = match.position;
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

  Future<void> adminResolve(String tournamentId, String matchId, String? winnerId) async {
    final ref = _matchesRef(tournamentId).doc(matchId);
    final updates = <String, dynamic>{
      'reportStatus': reportStatusToJson(MatchReportStatus.confirmed),
      'completed': true,
      'winnerId': winnerId,
    };
    await ref.update(updates);
  }
}
