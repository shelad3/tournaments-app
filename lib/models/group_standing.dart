class GroupStanding {
  final String id;
  final String tournamentId;
  final int groupIndex;
  final String userId;
  final String userName;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  GroupStanding({
    required this.id,
    required this.tournamentId,
    required this.groupIndex,
    required this.userId,
    required this.userName,
    this.points = 0,
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  Map<String, dynamic> toMap() => {
    'tournamentId': tournamentId,
    'groupIndex': groupIndex,
    'userId': userId,
    'userName': userName,
    'points': points,
    'played': played,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
  };

  factory GroupStanding.fromMap(Map<String, dynamic> map, String id) => GroupStanding(
    id: id,
    tournamentId: map['tournamentId'] ?? '',
    groupIndex: map['groupIndex'] ?? 0,
    userId: map['userId'] ?? '',
    userName: map['userName'] ?? '',
    points: map['points'] ?? 0,
    played: map['played'] ?? 0,
    wins: map['wins'] ?? 0,
    draws: map['draws'] ?? 0,
    losses: map['losses'] ?? 0,
    goalsFor: map['goalsFor'] ?? 0,
    goalsAgainst: map['goalsAgainst'] ?? 0,
  );
}
