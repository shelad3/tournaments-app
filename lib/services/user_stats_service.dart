import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserStats {
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int prizeMoney;
  final double winRate;
  final Map<String, GameStats> perGame;

  UserStats({
    this.tournamentsPlayed = 0,
    this.tournamentsWon = 0,
    this.prizeMoney = 0,
    this.perGame = const {},
  }) : winRate = tournamentsPlayed > 0
      ? (tournamentsWon / tournamentsPlayed) * 100
      : 0;
}

class GameStats {
  final String gameName;
  final int played;
  final int won;
  final int prizeMoney;

  GameStats({
    required this.gameName,
    this.played = 0,
    this.won = 0,
    this.prizeMoney = 0,
  });

  double get winRate => played > 0 ? (won / played) * 100 : 0;
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
    final Map<String, GameStats> perGame = {};

    for (var pDoc in participationsSnap.docs) {
      final tournamentId = pDoc.data()['tournamentId'] as String;

      final tDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
      String gameName = 'Unknown';
      if (tDoc.exists) {
        gameName = tDoc.data()?['gameName'] as String? ?? 'Unknown';
      }

      if (!perGame.containsKey(gameName)) {
        perGame[gameName] = GameStats(gameName: gameName);
      }

      final matchesSnap = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .where('winnerId', isEqualTo: userId)
          .get();

      perGame[gameName] = GameStats(
        gameName: gameName,
        played: perGame[gameName]!.played + 1,
        won: perGame[gameName]!.won + (matchesSnap.docs.isNotEmpty ? 1 : 0),
        prizeMoney: perGame[gameName]!.prizeMoney,
      );

      won += matchesSnap.docs.length;

      if (matchesSnap.docs.isNotEmpty && tDoc.exists) {
        final tData = tDoc.data()!;
        if (tData['entryType'] == 'money') {
          final entryFee = (tData['entryFee'] ?? 0) as int;
          final paidSnap = await _firestore
              .collection('participations')
              .where('tournamentId', isEqualTo: tournamentId)
              .where('paid', isEqualTo: true)
              .get();
          final prize = entryFee * paidSnap.docs.length;
          prizeMoney += prize;
          perGame[gameName] = GameStats(
            gameName: gameName,
            played: perGame[gameName]!.played,
            won: perGame[gameName]!.won,
            prizeMoney: perGame[gameName]!.prizeMoney + prize,
          );
        }
      }
    }

    return UserStats(
      tournamentsPlayed: played,
      tournamentsWon: won,
      prizeMoney: prizeMoney,
      perGame: perGame,
    );
  }
}
