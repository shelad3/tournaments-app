import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/participation_model.dart';
import '../services/bracket_service.dart';

class BracketProvider extends ChangeNotifier {
  final BracketService _service = BracketService();

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

  bool hasBracket() => _matches.isNotEmpty;
}
