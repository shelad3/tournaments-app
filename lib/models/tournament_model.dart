enum EntryType { free, money }

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
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isMoney => entryType == EntryType.money;
  bool get isFree => entryType == EntryType.free;

  int get totalFee => isMoney ? entryFee + (entryFee * 5 ~/ 30) : 0;

  DateTime get effectiveStartTime => startTime ?? hostDate;
  DateTime get effectiveEndTime => endTime ?? effectiveStartTime.add(const Duration(hours: 4));

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
  );
}
