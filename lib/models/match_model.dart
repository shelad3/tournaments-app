import 'match_result_model.dart';

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
  final MatchReportStatus reportStatus;
  final String? result1;
  final String? result2;
  final DateTime? proposedTime;
  final String? proposedBy;
  final DateTime? scheduledTime;
  final String scheduleStatus;

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
    this.reportStatus = MatchReportStatus.none,
    this.result1,
    this.result2,
    this.proposedTime,
    this.proposedBy,
    this.scheduledTime,
    this.scheduleStatus = 'none',
  });

  String? get winnerTeam =>
      winnerId == participant1Id ? participant1Team : participant2Team;

  bool get hasBothParticipants =>
      participant1Id != null && participant2Id != null;

  bool get isBye => participant2Id == null;

  bool get hasScheduledTime => scheduledTime != null;

  Duration? get scheduleCountdown {
    if (scheduledTime == null) return null;
    return scheduledTime!.difference(DateTime.now());
  }

  bool get isSchedulePast => scheduleCountdown?.isNegative ?? false;

  String? get opponentId =>
      participant1Id == null ? null : participant2Id;

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
    'reportStatus': reportStatusToJson(reportStatus),
    'result1': result1,
    'result2': result2,
    'proposedTime': proposedTime,
    'proposedBy': proposedBy,
    'scheduledTime': scheduledTime,
    'scheduleStatus': scheduleStatus,
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
        reportStatus: reportStatusFromJson(map['reportStatus']),
        result1: map['result1'],
        result2: map['result2'],
        proposedTime: (map['proposedTime'] as dynamic)?.toDate(),
        proposedBy: map['proposedBy'],
        scheduledTime: (map['scheduledTime'] as dynamic)?.toDate(),
        scheduleStatus: map['scheduleStatus'] ?? 'none',
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
    MatchReportStatus? reportStatus,
    String? result1,
    String? result2,
    DateTime? proposedTime,
    String? proposedBy,
    DateTime? scheduledTime,
    String? scheduleStatus,
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
        reportStatus: reportStatus ?? this.reportStatus,
        result1: result1 ?? this.result1,
        result2: result2 ?? this.result2,
        proposedTime: proposedTime ?? this.proposedTime,
        proposedBy: proposedBy ?? this.proposedBy,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      );
}
