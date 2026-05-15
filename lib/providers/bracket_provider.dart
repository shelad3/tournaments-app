import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/participation_model.dart';
import '../services/bracket_service.dart';
import '../services/match_result_service.dart';
import '../services/schedule_service.dart';

class BracketProvider extends ChangeNotifier {
  final BracketService _service = BracketService();
  final MatchResultService _resultService = MatchResultService();
  final ScheduleService _scheduleService = ScheduleService();

  List<MatchModel> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<List<MatchModel>> get rounds {
    if (_matches.isEmpty) return [];
    final maxRound = _matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
    return List.generate(
      maxRound + 1,
      (r) => _matches.where((m) => m.round == r).toList()
        ..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  Stream<void> loadMatches(String tournamentId) {
    _isLoading = true;
    notifyListeners();
    return _service.getMatches(tournamentId).map((matches) {
      _matches = matches;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> generateBracket(
      String tournamentId, List<ParticipationModel> participants) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.generateBracket(tournamentId, participants);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setWinner(
      String tournamentId, String matchId, String winnerId, String winnerTeam) async {
    await _service.setWinner(tournamentId, matchId, winnerId, winnerTeam);
  }

  Future<void> reportResult({
    required String tournamentId,
    required MatchModel match,
    required String userId,
    required String result,
  }) async {
    await _resultService.reportResult(
      tournamentId: tournamentId,
      match: match,
      userId: userId,
      result: result,
    );
  }

  Future<void> adminResolve(
      String tournamentId, String matchId, String? winnerId) async {
    await _resultService.adminResolve(tournamentId, matchId, winnerId);
  }

  Future<void> proposeTime({
    required String tournamentId,
    required String matchId,
    required String userId,
    required DateTime time,
  }) async {
    await _scheduleService.proposeTime(
      tournamentId: tournamentId,
      matchId: matchId,
      userId: userId,
      time: time,
    );
  }

  Future<void> confirmTime({
    required String tournamentId,
    required String matchId,
    required DateTime time,
  }) async {
    await _scheduleService.confirmTime(
      tournamentId: tournamentId,
      matchId: matchId,
      time: time,
    );
  }

  Future<void> cancelProposal({
    required String tournamentId,
    required String matchId,
  }) async {
    await _scheduleService.cancelProposal(
      tournamentId: tournamentId,
      matchId: matchId,
    );
  }

  bool hasBracket() => _matches.isNotEmpty;
}
