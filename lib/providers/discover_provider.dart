import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/discover_service.dart';

class DiscoverProvider extends ChangeNotifier {
  final DiscoverService _service = DiscoverService();

  List<UserModel> _searchResults = [];
  Set<String> _followingIds = {};
  bool _isSearching = false;
  String? _error;

  List<UserModel> get searchResults => _searchResults;
  Set<String> get followingIds => _followingIds;
  bool get isSearching => _isSearching;
  String? get error => _error;

  bool isFollowing(String userId) => _followingIds.contains(userId);

  Future<void> loadFollowing(String userId) async {
    _followingIds = await _service.getFollowingIds(userId);
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchUsers(query);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> toggleFollow(String followerId, String targetId) async {
    if (_followingIds.contains(targetId)) {
      await _service.unfollow(followerId, targetId);
      _followingIds.remove(targetId);
    } else {
      await _service.follow(followerId, targetId);
      _followingIds.add(targetId);
    }
    notifyListeners();
  }
}
