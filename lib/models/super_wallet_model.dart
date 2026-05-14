class SuperWalletModel {
  final String id;
  final int prizePool;
  final int platformEarnings;
  final int totalProcessed;

  SuperWalletModel({
    this.id = 'super_wallet',
    this.prizePool = 0,
    this.platformEarnings = 0,
    this.totalProcessed = 0,
  });

  int get totalBalance => prizePool + platformEarnings;

  Map<String, dynamic> toMap() => {
    'prizePool': prizePool,
    'platformEarnings': platformEarnings,
    'totalProcessed': totalProcessed,
  };

  factory SuperWalletModel.fromMap(Map<String, dynamic> map, String id) => SuperWalletModel(
    id: id,
    prizePool: map['prizePool'] ?? 0,
    platformEarnings: map['platformEarnings'] ?? 0,
    totalProcessed: map['totalProcessed'] ?? 0,
  );

  SuperWalletModel copyWith({
    int? prizePool,
    int? platformEarnings,
    int? totalProcessed,
  }) => SuperWalletModel(
    id: id,
    prizePool: prizePool ?? this.prizePool,
    platformEarnings: platformEarnings ?? this.platformEarnings,
    totalProcessed: totalProcessed ?? this.totalProcessed,
  );
}
