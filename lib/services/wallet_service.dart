import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/wallet_model.dart';
import '../models/super_wallet_model.dart';
import '../models/transaction_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _firestore.collection('wallets').doc(userId);
        final doc = await transaction.get(ref);
        if (!doc.exists) return;
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
    } catch (_) {
      return false;
    }
  }

  Future<bool> payTournamentFee(String userId, String tournamentId) async {
    try {
      final result = await _functions.httpsCallable('payTournamentFee').call({
        'tournamentId': tournamentId,
      });
      return (result.data as Map<String, dynamic>)['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') return false;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> awardPrize(String tournamentId, String winnerId) async {
    try {
      final result = await _functions.httpsCallable('awardPrize').call({
        'tournamentId': tournamentId,
        'winnerId': winnerId,
      });
      return (result.data as Map<String, dynamic>)['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> withdraw(String userId, int amount) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final phone = userDoc.data()?['phoneNumber'] as String?;
      if (phone == null) return false;

      final result = await _functions.httpsCallable('withdraw').call({
        'phone': phone,
        'amount': amount,
      });
      return (result.data as Map<String, dynamic>)['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'failed-precondition') return false;
      return false;
    } catch (_) {
      return false;
    }
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
