class WalletModel {
  final String userId;
  final int balance;
  final int totalDeposited;
  final int totalSpent;
  final int totalWithdrawn;
  final int totalPrizeReceived;

  WalletModel({
    required this.userId,
    this.balance = 0,
    this.totalDeposited = 0,
    this.totalSpent = 0,
    this.totalWithdrawn = 0,
    this.totalPrizeReceived = 0,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'balance': balance,
    'totalDeposited': totalDeposited,
    'totalSpent': totalSpent,
    'totalWithdrawn': totalWithdrawn,
    'totalPrizeReceived': totalPrizeReceived,
  };

  factory WalletModel.fromMap(Map<String, dynamic> map, String userId) => WalletModel(
    userId: userId,
    balance: map['balance'] ?? 0,
    totalDeposited: map['totalDeposited'] ?? 0,
    totalSpent: map['totalSpent'] ?? 0,
    totalWithdrawn: map['totalWithdrawn'] ?? 0,
    totalPrizeReceived: map['totalPrizeReceived'] ?? 0,
  );

  WalletModel copyWith({
    int? balance,
    int? totalDeposited,
    int? totalSpent,
    int? totalWithdrawn,
    int? totalPrizeReceived,
  }) => WalletModel(
    userId: userId,
    balance: balance ?? this.balance,
    totalDeposited: totalDeposited ?? this.totalDeposited,
    totalSpent: totalSpent ?? this.totalSpent,
    totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
    totalPrizeReceived: totalPrizeReceived ?? this.totalPrizeReceived,
  );
}
