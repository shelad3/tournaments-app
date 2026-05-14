import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/super_wallet_model.dart';
import '../models/transaction_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int minDepositPerTransaction = 30;
  static const int minWithdrawal = 50;

  Future<WalletModel?> getWallet(String userId) async {
    final doc = await _firestore.collection('wallets').doc(userId).get();
    if (!doc.exists) return null;
    return WalletModel.fromMap(doc.data()!, doc.id);
  }

  Future<WalletModel> ensureWallet(String userId) async {
    final existing = await getWallet(userId);
    if (existing != null) return existing;
    final wallet = WalletModel(userId: userId);
    await _firestore.collection('wallets').doc(userId).set(wallet.toMap());
    return wallet;
  }

  Future<bool> deposit(String userId, int amount) async {
    if (amount < minDepositPerTransaction) return false;
    await _firestore.runTransaction((transaction) async {
      final ref = _firestore.collection('wallets').doc(userId);
      final doc = await transaction.get(ref);
      final wallet = WalletModel.fromMap(doc.data()!, doc.id);
      transaction.update(ref, wallet.copyWith(
        balance: wallet.balance + amount,
        totalDeposited: wallet.totalDeposited + amount,
      ).toMap());
    });
    await _firestore.collection('transactions').add(TransactionModel(
      id: '', userId: userId, type: TransactionType.deposit, amount: amount,
    ).toMap());
    return true;
  }

  Future<bool> payTournamentFee(String userId, String tournamentId) async {
    final baseFee = await _getTournamentFee(tournamentId);
    if (baseFee == null) return false;
    final totalFee = baseFee + (baseFee * 5 ~/ 30);
    final platformFee = totalFee - baseFee;

    final userWallet = await getWallet(userId);
    if (userWallet == null || userWallet.balance < totalFee) return false;

    await _firestore.runTransaction((transaction) async {
      final wRef = _firestore.collection('wallets').doc(userId);
      final sRef = _firestore.collection('admin').doc('super_wallet');
      final wDoc = await transaction.get(wRef);
      final sDoc = await transaction.get(sRef);
      final wallet = WalletModel.fromMap(wDoc.data()!, wDoc.id);
      final superWallet = sDoc.exists
          ? SuperWalletModel.fromMap(sDoc.data()!, sDoc.id)
          : SuperWalletModel();

      transaction.update(wRef, wallet.copyWith(
        balance: wallet.balance - totalFee,
        totalSpent: wallet.totalSpent + totalFee,
      ).toMap());
      transaction.update(sRef, superWallet.copyWith(
        prizePool: superWallet.prizePool + baseFee,
        platformEarnings: superWallet.platformEarnings + platformFee,
        totalProcessed: superWallet.totalProcessed + totalFee,
      ).toMap());
    });

    await _firestore.collection('transactions').add(TransactionModel(
      id: '', userId: userId, type: TransactionType.tournamentFee, amount: baseFee, reference: tournamentId,
    ).toMap());
    if (platformFee > 0) {
      await _firestore.collection('transactions').add(TransactionModel(
        id: '', userId: userId, type: TransactionType.platformFee, amount: platformFee, reference: tournamentId,
      ).toMap());
    }
    return true;
  }

  Future<bool> awardPrize(String tournamentId, String winnerId) async {
    final participants = await _firestore
        .collection('participations')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('accepted', isEqualTo: true)
        .get();
    final paidCount = participants.docs.where((d) => d.data()['paid'] == true).length;
    final baseFee = await _getTournamentFee(tournamentId);
    if (baseFee == null || paidCount == 0) return false;
    final prizeAmount = baseFee * paidCount;

    await _firestore.runTransaction((transaction) async {
      final sRef = _firestore.collection('admin').doc('super_wallet');
      final wRef = _firestore.collection('wallets').doc(winnerId);
      final sDoc = await transaction.get(sRef);
      final wDoc = await transaction.get(wRef);
      final superWallet = SuperWalletModel.fromMap(sDoc.data()!, sDoc.id);
      final winnerWallet = WalletModel.fromMap(wDoc.data()!, wDoc.id);

      if (superWallet.prizePool < prizeAmount) return;

      transaction.update(sRef, superWallet.copyWith(
        prizePool: superWallet.prizePool - prizeAmount,
      ).toMap());
      transaction.update(wRef, winnerWallet.copyWith(
        balance: winnerWallet.balance + prizeAmount,
        totalPrizeReceived: winnerWallet.totalPrizeReceived + prizeAmount,
      ).toMap());
    });

    await _firestore.collection('transactions').add(TransactionModel(
      id: '', userId: winnerId, type: TransactionType.prizeWon, amount: prizeAmount, reference: tournamentId,
    ).toMap());
    return true;
  }

  Future<bool> withdraw(String userId, int amount) async {
    if (amount < minWithdrawal) return false;
    final wallet = await getWallet(userId);
    if (wallet == null || wallet.balance < amount) return false;

    await _firestore.runTransaction((transaction) async {
      final ref = _firestore.collection('wallets').doc(userId);
      final doc = await transaction.get(ref);
      final w = WalletModel.fromMap(doc.data()!, doc.id);
      transaction.update(ref, w.copyWith(
        balance: w.balance - amount,
        totalWithdrawn: w.totalWithdrawn + amount,
      ).toMap());
    });

    await _firestore.collection('transactions').add(TransactionModel(
      id: '', userId: userId, type: TransactionType.withdrawal, amount: amount,
    ).toMap());
    return true;
  }

  Future<SuperWalletModel?> getSuperWallet() async {
    final doc = await _firestore.collection('admin').doc('super_wallet').get();
    if (!doc.exists) return null;
    return SuperWalletModel.fromMap(doc.data()!, doc.id);
  }

  Future<SuperWalletModel> ensureSuperWallet() async {
    final existing = await getSuperWallet();
    if (existing != null) return existing;
    final wallet = SuperWalletModel();
    await _firestore.collection('admin').doc('super_wallet').set(wallet.toMap());
    return wallet;
  }

  Future<int?> _getTournamentFee(String tournamentId) async {
    final doc = await _firestore.collection('tournaments').doc(tournamentId).get();
    if (!doc.exists) return null;
    return doc.data()!['entryFee'] as int?;
  }

  Stream<List<TransactionModel>> getTransactions(String userId) =>
      _firestore.collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList());

  Stream<List<TransactionModel>> getAllTransactions() =>
      _firestore.collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
              .toList());
}
