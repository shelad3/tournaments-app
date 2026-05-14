enum TransactionType { deposit, tournamentFee, platformFee, prizeWon, withdrawal }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final int interestPaid;
  final String? reference;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.interestPaid = 0,
    this.reference,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.tournamentFee:
        return 'Tournament Fee (Prize Pool)';
      case TransactionType.platformFee:
        return 'Platform Service Fee';
      case TransactionType.prizeWon:
        return 'Prize Won';
      case TransactionType.withdrawal:
        return 'Withdrawal';
    }
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': _typeToDb(type),
    'amount': amount,
    'interestPaid': interestPaid,
    'reference': reference,
    'createdAt': createdAt,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) => TransactionModel(
    id: id,
    userId: map['userId'] ?? '',
    type: _parseType(map['type']),
    amount: map['amount'] ?? 0,
    interestPaid: map['interestPaid'] ?? 0,
    reference: map['reference'],
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  static String _typeToDb(TransactionType type) {
    switch (type) {
      case TransactionType.deposit: return 'deposit';
      case TransactionType.tournamentFee: return 'tournament_fee';
      case TransactionType.platformFee: return 'platform_fee';
      case TransactionType.prizeWon: return 'prize_won';
      case TransactionType.withdrawal: return 'withdrawal';
    }
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'deposit': return TransactionType.deposit;
      case 'tournament_fee': return TransactionType.tournamentFee;
      case 'platform_fee': return TransactionType.platformFee;
      case 'prize_won': return TransactionType.prizeWon;
      case 'withdrawal': return TransactionType.withdrawal;
      default: return TransactionType.deposit;
    }
  }
}
