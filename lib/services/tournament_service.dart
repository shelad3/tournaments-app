import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';
import '../models/participation_model.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TournamentModel>> getTournaments() =>
      _firestore
          .collection('tournaments')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => TournamentModel.fromMap(doc.data(), doc.id))
              .toList());

  Future<bool> participate(ParticipationModel participation) async {
    final existing = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: participation.userId)
        .where('tournamentId', isEqualTo: participation.tournamentId)
        .get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      if (doc.data()['accepted'] == true) return false;
      await doc.reference.delete();
    }
    await _firestore.collection('participations').add(participation.toMap());
    return true;
  }

  Future<void> acceptParticipation(String userId, String tournamentId, {bool paid = false}) async {
    final snap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'accepted': true,
        if (paid) 'paid': true,
      });
    }
  }

  Future<ParticipationModel?> getUserParticipation(
      String userId, String tournamentId) async {
    final snap = await _firestore
        .collection('participations')
        .where('userId', isEqualTo: userId)
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    if (snap.docs.isEmpty) return null;
    return ParticipationModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Stream<List<ParticipationModel>> getTournamentParticipants(
          String tournamentId) =>
      _firestore
          .collection('participations')
          .where('tournamentId', isEqualTo: tournamentId)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ParticipationModel.fromMap(doc.data(), doc.id))
              .toList());

  Stream<List<ParticipationModel>> getUserParticipations(String userId) =>
      _firestore
          .collection('participations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ParticipationModel.fromMap(doc.data(), doc.id))
              .toList());

  Future<Map<String, int>> getParticipantCounts(String tournamentId) async {
    final snap = await _firestore
        .collection('participations')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    final yes = snap.docs.where((d) => d.data()['vote'] == 'yes').length;
    final no = snap.docs.where((d) => d.data()['vote'] == 'no').length;
    return {'yes': yes, 'no': no, 'total': snap.docs.length};
  }

  Stream<int> acceptedCountStream(String tournamentId) =>
      _firestore
          .collection('participations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('accepted', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.length);
}
