import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/super_wallet_model.dart';
import '../models/transaction_model.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _service = WalletService();

  WalletModel? _wallet;
  SuperWalletModel? _superWallet;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  WalletModel? get wallet => _wallet;
  SuperWalletModel? get superWallet => _superWallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _wallet?.balance ?? 0;

  Future<void> loadWallet(String userId) async {
    _wallet = await _service.ensureWallet(userId);
    notifyListeners();
  }

  Future<void> loadSuperWallet() async {
    _superWallet = await _service.ensureSuperWallet();
    notifyListeners();
  }

  void loadTransactions(String userId) {
    _service.getTransactions(userId).listen((txns) {
      _transactions = txns;
      notifyListeners();
    });
  }

  Future<bool> deposit(String userId, int amount) async {
    if (amount < WalletService.minDepositPerTransaction) {
      _error = 'Minimum deposit is ${WalletService.minDepositPerTransaction} KES';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.deposit(userId, amount);
      if (success) await loadWallet(userId);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> payTournamentFee(String userId, String tournamentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.payTournamentFee(userId, tournamentId);
      if (success) {
        await loadWallet(userId);
        await loadSuperWallet();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> withdraw(String userId, int amount) async {
    if (amount < WalletService.minWithdrawal) {
      _error = 'Minimum withdrawal is ${WalletService.minWithdrawal} KES';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _service.withdraw(userId, amount);
      if (success) await loadWallet(userId);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
