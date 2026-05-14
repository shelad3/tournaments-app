import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _service = LeaderboardService();

  List<LeaderboardEntry> _entries = [];
  LeaderboardEntry? _currentUserEntry;
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntry> get entries => _entries;
  LeaderboardEntry? get currentUserEntry => _currentUserEntry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLeaderboard({String? currentUserId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _service.getLeaderboard();
      if (currentUserId != null) {
        try {
          _currentUserEntry = _entries.firstWhere((e) => e.userId == currentUserId);
        } catch (_) {
          _currentUserEntry = null;
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
