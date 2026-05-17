import 'tournament_model.dart';

class TournamentTemplate {
  final String id;
  final String name;
  final String? description;
  final String? gameCategory;
  final String? gameName;
  final String? platform;
  final EntryType entryType;
  final int entryFee;
  final int? minParticipants;
  final int? maxParticipants;
  final String minTier;
  final Map<int, int> prizeDistribution;
  final TournamentFormat format;
  final int groupCount;
  final int advancePerGroup;
  final bool autoGenerateBracket;
  final String createdBy;
  final DateTime createdAt;

  TournamentTemplate({
    required this.id,
    required this.name,
    this.description,
    this.gameCategory,
    this.gameName,
    this.platform,
    this.entryType = EntryType.free,
    this.entryFee = 0,
    this.minParticipants,
    this.maxParticipants,
    this.minTier = 'bronze',
    this.prizeDistribution = const {1: 100},
    this.format = TournamentFormat.singleElimination,
    this.groupCount = 0,
    this.advancePerGroup = 0,
    this.autoGenerateBracket = false,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get entryTypeLabel => entryType == EntryType.money ? 'Paid' : 'Free';
  String get formatLabel {
    switch (format) {
      case TournamentFormat.singleElimination: return 'Single Elimination';
      case TournamentFormat.groupStagePlayoffs: return 'Group Stage → Playoffs';
      case TournamentFormat.doubleElimination: return 'Double Elimination';
    }
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'gameCategory': gameCategory,
    'gameName': gameName,
    'platform': platform,
    'entryType': entryType.name,
    'entryFee': entryFee,
    'minParticipants': minParticipants,
    'maxParticipants': maxParticipants,
    'minTier': minTier,
    'prizeDistribution': prizeDistribution.map((k, v) => MapEntry(k.toString(), v)),
    'format': format.name,
    'groupCount': groupCount,
    'advancePerGroup': advancePerGroup,
    'autoGenerateBracket': autoGenerateBracket,
    'createdBy': createdBy,
    'createdAt': createdAt,
  };

  factory TournamentTemplate.fromMap(Map<String, dynamic> map, String id) => TournamentTemplate(
    id: id,
    name: map['name'] ?? '',
    description: map['description'],
    gameCategory: map['gameCategory'],
    gameName: map['gameName'],
    platform: map['platform'],
    entryType: map['entryType'] == 'money' ? EntryType.money : EntryType.free,
    entryFee: map['entryFee'] ?? 0,
    minParticipants: map['minParticipants'],
    maxParticipants: map['maxParticipants'],
    minTier: map['minTier'] ?? 'bronze',
    prizeDistribution: (map['prizeDistribution'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toInt())) ?? {1: 100},
    format: _parseFormat(map['format']),
    groupCount: map['groupCount'] ?? 0,
    advancePerGroup: map['advancePerGroup'] ?? 0,
    autoGenerateBracket: map['autoGenerateBracket'] ?? false,
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate(),
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
