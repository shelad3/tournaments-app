class TournamentHistoryEntry {
  final String tournamentId;
  final String title;
  final DateTime date;
  final String gameName;
  final String? platform;
  final bool won;
  final int prizeMoney;
  final String? imageUrl;

  TournamentHistoryEntry({
    required this.tournamentId,
    required this.title,
    required this.date,
    this.gameName = '',
    this.platform,
    this.won = false,
    this.prizeMoney = 0,
    this.imageUrl,
  });
}
