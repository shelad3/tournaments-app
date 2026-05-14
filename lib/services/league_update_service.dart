import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/league_update_model.dart';
import '../models/user_model.dart';

class LeagueUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<LeagueUpdateModel>> getUpdates(UserModel user) {
    final favoriteGames = user.favoriteGames.toSet();
    final controller = StreamController<List<LeagueUpdateModel>>.broadcast();
    final updates = <LeagueUpdateModel>[];

    void emit() {
      updates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(List.from(updates));
    }

    _firestore
        .collection('tournaments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      updates.clear();
      final now = DateTime.now();

      for (var doc in snap.docs) {
        final data = doc.data();
        final gameName = data['gameName'] as String?;
        if (favoriteGames.isNotEmpty && gameName != null && !favoriteGames.contains(gameName)) continue;

        final title = data['title'] as String? ?? '';
        final startTime = (data['startTime'] as dynamic)?.toDate();
        final endTime = (data['endTime'] as dynamic)?.toDate();
        final createdAt = (data['createdAt'] as dynamic)?.toDate() ?? now;

        if (endTime != null && endTime.isBefore(now) && endTime.isAfter(now.subtract(const Duration(days: 2)))) {
          updates.add(LeagueUpdateModel(
            id: 'ended_${doc.id}',
            type: UpdateType.tournamentEnded,
            title: '$title has ended',
            body: 'The tournament has concluded.',
            gameName: gameName,
            tournamentId: doc.id,
            createdAt: endTime,
          ));
        } else if (startTime != null && startTime.isBefore(now) && startTime.isAfter(now.subtract(const Duration(hours: 24)))) {
          updates.add(LeagueUpdateModel(
            id: 'started_${doc.id}',
            type: UpdateType.tournamentStarted,
            title: '$title has started!',
            body: 'The tournament is underway.',
            gameName: gameName,
            tournamentId: doc.id,
            createdAt: startTime,
          ));
        } else if (createdAt.isAfter(now.subtract(const Duration(days: 3)))) {
          updates.add(LeagueUpdateModel(
            id: 'new_${doc.id}',
            type: UpdateType.newTournament,
            title: 'New tournament: $title',
            body: gameName != null ? 'A new $gameName tournament is open for registration.' : 'A new tournament is open for registration.',
            gameName: gameName,
            tournamentId: doc.id,
            createdAt: createdAt,
          ));
        }
      }
      emit();
    });

    return controller.stream;
  }
}
