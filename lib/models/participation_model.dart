class ParticipationModel {
  final String id;
  final String userId;
  final String tournamentId;
  final String vote;
  final String? reason;
  final String? teamName;
  final bool accepted;
  final bool paid;
  final bool checkedIn;
  final DateTime createdAt;

  ParticipationModel({
    required this.id,
    required this.userId,
    required this.tournamentId,
    required this.vote,
    this.reason,
    this.teamName,
    this.accepted = false,
    this.paid = false,
    this.checkedIn = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'tournamentId': tournamentId,
    'vote': vote,
    'reason': reason,
    'teamName': teamName,
    'accepted': accepted,
    'paid': paid,
    'checkedIn': checkedIn,
    'createdAt': createdAt,
  };

  factory ParticipationModel.fromMap(Map<String, dynamic> map, String id) => ParticipationModel(
    id: id,
    userId: map['userId'] ?? '',
    tournamentId: map['tournamentId'] ?? '',
    vote: map['vote'] ?? 'yes',
    reason: map['reason'],
    teamName: map['teamName'],
    accepted: map['accepted'] ?? false,
    paid: map['paid'] ?? false,
    checkedIn: map['checkedIn'] ?? false,
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  ParticipationModel copyWith({
    String? id,
    String? userId,
    String? tournamentId,
    String? vote,
    String? reason,
    String? teamName,
    bool? accepted,
    bool? paid,
    bool? checkedIn,
    DateTime? createdAt,
  }) => ParticipationModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tournamentId: tournamentId ?? this.tournamentId,
    vote: vote ?? this.vote,
    reason: reason ?? this.reason,
    teamName: teamName ?? this.teamName,
    accepted: accepted ?? this.accepted,
    paid: paid ?? this.paid,
    checkedIn: checkedIn ?? this.checkedIn,
    createdAt: createdAt ?? this.createdAt,
  );
}
