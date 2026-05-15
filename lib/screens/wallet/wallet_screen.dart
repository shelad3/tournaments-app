import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/mpesa_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/app_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final _mpesaService = MpesaService();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final walletProv = context.read<WalletProvider>();
    walletProv.loadWallet(auth.user!.uid);
    walletProv.loadTransactions(auth.user!.uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showDepositDialog() {
    _amountController.clear();
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deposit via M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixIcon: Icon(Icons.money),
                helperText: 'Min ${WalletService.minDepositPerTransaction} KES',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                prefixIcon: Icon(Icons.phone_android),
                hintText: '0712345678',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(_amountController.text.trim());
              final phone = _phoneController.text.trim();
              if (amount == null || amount < WalletService.minDepositPerTransaction) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Minimum deposit: ${WalletService.minDepositPerTransaction} KES'), backgroundColor: Colors.red),
                );
                return;
              }
              if (phone.isEmpty || phone.length < 10) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid M-Pesa number'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx);
              _initiateDeposit(amount, phone);
            },
            child: const Text('Pay with M-Pesa'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateDeposit(int amount, String phone) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ref = 'DEP${DateTime.now().millisecondsSinceEpoch}';
    final result = await _mpesaService.stkPush(
      phone: '254${phone.substring(phone.length - 9)}',
      amount: amount,
      transactionRef: ref,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your phone for M-Pesa prompt'), backgroundColor: Colors.green),
      );
      _pollStatus(ref);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Payment failed'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pollStatus(String ref) async {
    await Future.delayed(const Duration(seconds: 5));
    for (int i = 0; i < 12; i++) {
      final status = await _mpesaService.checkStatus(ref);
      if (status == 'completed') {
        if (!mounted) return;
        context.read<WalletProvider>().loadWallet(context.read<AuthProvider>().user!.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit confirmed!'), backgroundColor: Colors.green),
        );
        return;
      } else if (status == 'failed') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Try again.'), backgroundColor: Colors.red),
        );
        return;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _showWithdrawDialog() {
    final auth = context.read<AuthProvider>();
    final registeredPhone = auth.user?.phoneNumber ?? '';
    _amountController.clear();
    _phoneController.text = registeredPhone;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Withdraw to M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixIcon: Icon(Icons.money_off),
                helperText: 'Min ${WalletService.minWithdrawal} KES',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'M-Pesa Phone Number',
                prefixIcon: const Icon(Icons.phone_android),
                hintText: '0712345678',
                helperText: 'Only your registered number can withdraw',
                helperStyle: TextStyle(color: Colors.red.shade400, fontSize: 11),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(_amountController.text.trim());
              final phone = _phoneController.text.trim();
              if (amount == null || amount < WalletService.minWithdrawal) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Minimum withdrawal: ${WalletService.minWithdrawal} KES'), backgroundColor: Colors.red),
                );
                return;
              }
              if (phone.isEmpty || phone.length < 10) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid M-Pesa number'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx);
              _initiateWithdrawal(amount, phone);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Withdraw to M-Pesa'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateWithdrawal(int amount, String phone) async {
    final auth = context.read<AuthProvider>();
    final walletProv = context.read<WalletProvider>();
    final balance = walletProv.balance;

    if (balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _mpesaService.b2cPayment(
      phone: '254${phone.substring(phone.length - 9)}',
      amount: amount,
      userId: auth.user!.uid,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (result.success) {
      await walletProv.withdraw(auth.user!.uid, amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal sent to your M-Pesa!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Withdrawal failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wallet'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WalletTab(
            showDepositDialog: _showDepositDialog,
            showWithdrawDialog: _showWithdrawDialog,
            loadData: _loadData,
          ),
          const _TransactionsTab(),
        ],
      ),
    );
  }
}

class _WalletTab extends StatelessWidget {
  final VoidCallback showDepositDialog;
  final VoidCallback showWithdrawDialog;
  final VoidCallback loadData;

  const _WalletTab({
    required this.showDepositDialog,
    required this.showWithdrawDialog,
    required this.loadData,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (_, auth, wallet, __) {
        if (!auth.isLoggedIn) {
          return EmptyState(
            icon: Icons.account_balance_wallet,
            title: 'Please sign in to view wallet',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => loadData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard.spacious(
                child: Column(
                  children: [
                    const Text('Current Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('${wallet.balance} KES',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        )),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        StatCard(
                          icon: Icons.arrow_downward,
                          label: 'Deposited',
                          value: '${wallet.wallet?.totalDeposited ?? 0} KES',
                          color: Colors.green,
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          icon: Icons.sports_soccer,
                          label: 'Spent',
                          value: '${wallet.wallet?.totalSpent ?? 0} KES',
                          color: Colors.blue,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatCard(
                          icon: Icons.emoji_events,
                          label: 'Prize Won',
                          value: '${wallet.wallet?.totalPrizeReceived ?? 0} KES',
                          color: Colors.amber,
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        StatCard(
                          icon: Icons.arrow_upward,
                          label: 'Withdrawn',
                          value: '${wallet.wallet?.totalWithdrawn ?? 0} KES',
                          color: Colors.red,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: showDepositDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Deposit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: wallet.balance >= WalletService.minWithdrawal ? showWithdrawDialog : null,
                      icon: const Icon(Icons.money_off),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
              if (wallet.balance < WalletService.minWithdrawal)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Minimum withdrawal: ${WalletService.minWithdrawal} KES',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Consumer2<AuthProvider, WalletProvider>(
      builder: (_, auth, wallet, __) {
        if (!auth.isLoggedIn) {
          return EmptyState(
            icon: Icons.account_balance_wallet,
            title: 'Please sign in to view transactions',
          );
        }
        if (wallet.transactions.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long,
            title: 'No transactions yet',
            subtitle: 'Deposit or join a tournament to see your transactions',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<WalletProvider>().loadTransactions(auth.user!.uid);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallet.transactions.length,
            itemBuilder: (_, i) {
              final txn = wallet.transactions[i];
              return AppCard.compact(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _txnColor(txn.type).withValues(alpha: 0.12),
                    child: Icon(_txnIcon(txn.type), color: _txnColor(txn.type), size: 20),
                  ),
                  title: Text(txn.typeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(dateFormat.format(txn.createdAt), style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    '${_txnPrefix(txn.type)}${txn.amount} KES',
                    style: TextStyle(color: _txnColor(txn.type), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _txnPrefix(TransactionType type) {
  switch (type) {
    case TransactionType.deposit:
    case TransactionType.prizeWon:
      return '+';
    case TransactionType.tournamentFee:
    case TransactionType.platformFee:
    case TransactionType.withdrawal:
      return '-';
  }
}

IconData _txnIcon(TransactionType type) {
  switch (type) {
    case TransactionType.deposit: return Icons.arrow_downward;
    case TransactionType.tournamentFee: return Icons.sports_soccer;
    case TransactionType.platformFee: return Icons.trending_up;
    case TransactionType.prizeWon: return Icons.emoji_events;
    case TransactionType.withdrawal: return Icons.arrow_upward;
  }
}

Color _txnColor(TransactionType type) {
  switch (type) {
    case TransactionType.deposit: return Colors.green;
    case TransactionType.tournamentFee: return Colors.blue;
    case TransactionType.platformFee: return Colors.orange;
    case TransactionType.prizeWon: return Colors.amber;
    case TransactionType.withdrawal: return Colors.red;
  }
}
