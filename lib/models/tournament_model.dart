enum EntryType { free, money }

enum TournamentFormat { singleElimination, groupStagePlayoffs, doubleElimination }

class TournamentModel {
  final String id;
  final String title;
  final String description;
  final DateTime signUpEndDate;
  final DateTime hostDate;
  final EntryType entryType;
  final int entryFee;
  final String createdBy;
  final DateTime createdAt;
  final String? imageUrl;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? gameCategory;
  final String? gameName;
  final String? platform;
  final int? maxParticipants;
  final int? minParticipants;
  final String minTier;
  final Map<int, int> prizeDistribution;
  final TournamentFormat format;
  final int groupCount;
  final int advancePerGroup;
  final bool autoGenerateBracket;
  final String? templateId;
  final String? passcode;

  TournamentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.signUpEndDate,
    required this.hostDate,
    required this.entryType,
    this.entryFee = 0,
    required this.createdBy,
    DateTime? createdAt,
    this.imageUrl,
    this.startTime,
    this.endTime,
    this.gameCategory,
    this.gameName,
    this.platform,
    this.maxParticipants,
    this.minParticipants,
    this.minTier = 'bronze',
    this.prizeDistribution = const {1: 100},
    this.format = TournamentFormat.singleElimination,
    this.groupCount = 0,
    this.advancePerGroup = 0,
    this.autoGenerateBracket = false,
    this.templateId,
    this.passcode,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isMoney => entryType == EntryType.money;
  bool get isFree => entryType == EntryType.free;
  bool get isGroupStage => format == TournamentFormat.groupStagePlayoffs;
  bool get isDoubleElimination => format == TournamentFormat.doubleElimination;

  int get totalFee => isMoney ? entryFee + (entryFee * 5 ~/ 30) : 0;

  DateTime get effectiveStartTime => startTime ?? hostDate;
  DateTime get effectiveEndTime => endTime ?? effectiveStartTime.add(const Duration(hours: 4));

  bool get hasTierRestriction => minTier != 'bronze';
  bool get isLocked => passcode != null && passcode!.length == 6;

  String get formatLabel {
    switch (format) {
      case TournamentFormat.singleElimination: return 'Single Elimination';
      case TournamentFormat.groupStagePlayoffs: return 'Group Stage → Playoffs';
      case TournamentFormat.doubleElimination: return 'Double Elimination';
    }
  }

  int prizeForPosition(int position) {
    final total = prizeDistribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;
    final share = prizeDistribution[position] ?? 0;
    return share;
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'signUpEndDate': signUpEndDate,
    'hostDate': hostDate,
    'entryType': entryType.name,
    'entryFee': entryFee,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'imageUrl': imageUrl,
    'startTime': startTime,
    'endTime': endTime,
    'gameCategory': gameCategory,
    'gameName': gameName,
    'platform': platform,
    'maxParticipants': maxParticipants,
    'minParticipants': minParticipants,
    'minTier': minTier,
    'prizeDistribution': prizeDistribution.map((k, v) => MapEntry(k.toString(), v)),
    'format': format.name,
    'groupCount': groupCount,
    'advancePerGroup': advancePerGroup,
    'autoGenerateBracket': autoGenerateBracket,
    'templateId': templateId,
    'passcode': passcode,
  };

  factory TournamentModel.fromMap(Map<String, dynamic> map, String id) => TournamentModel(
    id: id,
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    signUpEndDate: (map['signUpEndDate'] as dynamic).toDate(),
    hostDate: (map['hostDate'] as dynamic).toDate(),
    entryType: map['entryType'] == 'money' ? EntryType.money : EntryType.free,
    entryFee: map['entryFee'] ?? 0,
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate(),
    imageUrl: map['imageUrl'],
    startTime: (map['startTime'] as dynamic)?.toDate(),
    endTime: (map['endTime'] as dynamic)?.toDate(),
    gameCategory: map['gameCategory'],
    gameName: map['gameName'],
    platform: map['platform'],
    maxParticipants: map['maxParticipants'],
    minParticipants: map['minParticipants'],
    minTier: map['minTier'] ?? 'bronze',
    prizeDistribution: (map['prizeDistribution'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toInt())) ?? {1: 100},
    format: _parseFormat(map['format']),
    groupCount: map['groupCount'] ?? 0,
    advancePerGroup: map['advancePerGroup'] ?? 0,
    autoGenerateBracket: map['autoGenerateBracket'] ?? false,
    templateId: map['templateId'],
    passcode: map['passcode'],
  );

  static TournamentFormat _parseFormat(dynamic format) {
    if (format is String) {
      switch (format) {
        case 'groupStagePlayoffs': return TournamentFormat.groupStagePlayoffs;
        case 'doubleElimination': return TournamentFormat.doubleElimination;
      }
    }
    return TournamentFormat.singleElimination;
  }
}
