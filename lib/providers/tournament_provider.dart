import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';
import '../models/participation_model.dart';
import '../services/tournament_service.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentService _service = TournamentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TournamentModel> _tournaments = [];
  List<ParticipationModel> _userParticipations = [];
  Map<String, Map<String, int>> _participantCounts = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<TournamentModel> get tournaments => _tournaments;
  List<ParticipationModel> get userParticipations => _userParticipations;
  Map<String, Map<String, int>> get participantCounts => _participantCounts;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<TournamentModel> get myTournaments {
    final regIds = _userParticipations
        .where((p) => p.accepted)
        .map((p) => p.tournamentId)
        .toSet();
    return _tournaments.where((t) => regIds.contains(t.id)).toList();
  }

  bool isRegistered(String tournamentId) =>
      _userParticipations.any((p) => p.tournamentId == tournamentId && p.accepted);

  ParticipationModel? getParticipation(String tournamentId) {
    final matches = _userParticipations.where((p) => p.tournamentId == tournamentId);
    return matches.isEmpty ? null : matches.first;
  }

  void loadTournaments() {
    _hasLoaded = false;
    notifyListeners();
    _service.getTournaments().listen((tournaments) {
      _tournaments = tournaments;
      _hasLoaded = true;
      notifyListeners();
    });
  }

  void loadUserParticipations(String userId) {
    _service.getUserParticipations(userId).listen((participations) {
      _userParticipations = participations;
      _hasLoaded = true;
      notifyListeners();
    });
  }

  Future<Map<String, int>> loadParticipantCounts(String tournamentId) async {
    final counts = await _service.getParticipantCounts(tournamentId);
    _participantCounts[tournamentId] = counts;
    notifyListeners();
    return counts;
  }

  Future<bool> participate({
    required String userId,
    required String tournamentId,
    required String vote,
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final participation = ParticipationModel(
        id: '',
        userId: userId,
        tournamentId: tournamentId,
        vote: vote,
        reason: reason,
      );
      final result = await _service.participate(participation);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> acceptParticipation(String userId, String tournamentId, {bool paid = false}) async {
    await _service.acceptParticipation(userId, tournamentId, paid: paid);
  }

  Future<ParticipationModel?> getUserParticipation(
      String userId, String tournamentId) async {
    return await _service.getUserParticipation(userId, tournamentId);
  }

  Future<List<ParticipationModel>> getTournamentParticipants(String tournamentId) async {
    final snap = await _service.getTournamentParticipants(tournamentId).first;
    return snap;
  }

  Stream<List<ParticipationModel>> getParticipantsStream(String tournamentId) =>
      _service.getTournamentParticipants(tournamentId);

  Stream<int> acceptedParticipantCountStream(String tournamentId) =>
      _service.acceptedCountStream(tournamentId);

  Future<DocumentSnapshot> getUserProfile(String userId) =>
      _firestore.collection('users').doc(userId).get();
}
