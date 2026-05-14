import 'package:flutter/material.dart';

enum UpdateType { tournamentStarted, tournamentEnded, winnerAnnounced, newTournament, matchResult }

class LeagueUpdateModel {
  final String id;
  final UpdateType type;
  final String title;
  final String body;
  final String? gameName;
  final String? tournamentId;
  final DateTime createdAt;

  LeagueUpdateModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.gameName,
    this.tournamentId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData get icon {
    switch (type) {
      case UpdateType.tournamentStarted: return Icons.play_arrow;
      case UpdateType.tournamentEnded: return Icons.stop;
      case UpdateType.winnerAnnounced: return Icons.emoji_events;
      case UpdateType.newTournament: return Icons.add_circle;
      case UpdateType.matchResult: return Icons.swap_vert;
    }
  }

  Color get color {
    switch (type) {
      case UpdateType.tournamentStarted: return Colors.green;
      case UpdateType.tournamentEnded: return Colors.red;
      case UpdateType.winnerAnnounced: return Colors.amber;
      case UpdateType.newTournament: return Colors.blue;
      case UpdateType.matchResult: return Colors.purple;
    }
  }
}
