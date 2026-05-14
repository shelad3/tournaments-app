class MatchModel {
  final String id;
  final String tournamentId;
  final int round;
  final int position;
  final String? participant1Id;
  final String? participant1Team;
  final String? participant2Id;
  final String? participant2Team;
  final String? winnerId;
  final bool completed;

  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.position,
    this.participant1Id,
    this.participant1Team,
    this.participant2Id,
    this.participant2Team,
    this.winnerId,
    this.completed = false,
  });

  String? get winnerTeam =>
      winnerId == participant1Id ? participant1Team : participant2Team;

  bool get hasBothParticipants =>
      participant1Id != null && participant2Id != null;

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'round': round,
    'position': position,
    'participant1Id': participant1Id,
    'participant1Team': participant1Team,
    'participant2Id': participant2Id,
    'participant2Team': participant2Team,
    'winnerId': winnerId,
    'completed': completed,
  };

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) =>
      MatchModel(
        id: id,
        tournamentId: map['tournamentId'] ?? '',
        round: map['round'] ?? 0,
        position: map['position'] ?? 0,
        participant1Id: map['participant1Id'],
        participant1Team: map['participant1Team'],
        participant2Id: map['participant2Id'],
        participant2Team: map['participant2Team'],
        winnerId: map['winnerId'],
        completed: map['completed'] ?? false,
      );

  MatchModel copyWith({
    String? id,
    String? tournamentId,
    int? round,
    int? position,
    String? participant1Id,
    String? participant1Team,
    String? participant2Id,
    String? participant2Team,
    String? winnerId,
    bool? completed,
  }) =>
      MatchModel(
        id: id ?? this.id,
        tournamentId: tournamentId ?? this.tournamentId,
        round: round ?? this.round,
        position: position ?? this.position,
        participant1Id: participant1Id ?? this.participant1Id,
        participant1Team: participant1Team ?? this.participant1Team,
        participant2Id: participant2Id ?? this.participant2Id,
        participant2Team: participant2Team ?? this.participant2Team,
        winnerId: winnerId ?? this.winnerId,
        completed: completed ?? this.completed,
      );
}
