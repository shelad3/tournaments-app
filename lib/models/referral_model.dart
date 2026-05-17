class ReferralModel {
  final String id;
  final String referrerId;
  final String referrerCode;
  final String refereeId;
  final String refereeName;
  final String refereeEmail;
  final DateTime joinedAt;
  final bool bonusAwarded;
  final int bonusAmount;

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referrerCode,
    required this.refereeId,
    required this.refereeName,
    required this.refereeEmail,
    DateTime? joinedAt,
    this.bonusAwarded = false,
    this.bonusAmount = 0,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'referrerId': referrerId,
    'referrerCode': referrerCode,
    'refereeId': refereeId,
    'refereeName': refereeName,
    'refereeEmail': refereeEmail,
    'joinedAt': joinedAt,
    'bonusAwarded': bonusAwarded,
    'bonusAmount': bonusAmount,
  };

  factory ReferralModel.fromMap(Map<String, dynamic> map, String id) => ReferralModel(
    id: id,
    referrerId: map['referrerId'] ?? '',
    referrerCode: map['referrerCode'] ?? '',
    refereeId: map['refereeId'] ?? '',
    refereeName: map['refereeName'] ?? '',
    refereeEmail: map['refereeEmail'] ?? '',
    joinedAt: (map['joinedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    bonusAwarded: map['bonusAwarded'] ?? false,
    bonusAmount: map['bonusAmount'] ?? 0,
  );
}
