class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userTeam;
  final int wins;
  final int prizeMoney;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userTeam,
    required this.wins,
    required this.prizeMoney,
    required this.rank,
  });
}
