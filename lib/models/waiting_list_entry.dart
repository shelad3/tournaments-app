class WaitingListEntry {
  final String id;
  final String userId;
  final String tournamentId;
  final DateTime createdAt;

  WaitingListEntry({
    required this.id,
    required this.userId,
    required this.tournamentId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'tournamentId': tournamentId,
    'createdAt': createdAt,
  };

  factory WaitingListEntry.fromMap(Map<String, dynamic> map, String id) => WaitingListEntry(
    id: id,
    userId: map['userId'] ?? '',
    tournamentId: map['tournamentId'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );
}
