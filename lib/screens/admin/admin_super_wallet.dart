import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction_model.dart';

class AdminSuperWallet extends StatefulWidget {
  const AdminSuperWallet({super.key});

  @override
  State<AdminSuperWallet> createState() => _AdminSuperWalletState();
}

class _AdminSuperWalletState extends State<AdminSuperWallet> {
  @override
  void initState() {
    super.initState();
    context.read<WalletProvider>().loadSuperWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Wallet')),
      body: Consumer<WalletProvider>(
        builder: (_, wp, __) {
          final sw = wp.superWallet;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Platform Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('${sw?.totalBalance ?? 0} KES',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'Prize Pool', value: '${sw?.prizePool ?? 0} KES', color: Colors.green),
                          _Stat(label: 'Platform Earnings', value: '${sw?.platformEarnings ?? 0} KES', color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _Stat(label: 'Total Processed', value: '${sw?.totalProcessed ?? 0} KES', color: Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final txns = snap.data!.docs.map((d) => TransactionModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                  if (txns.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('No transactions', style: TextStyle(color: Colors.grey)));
                  return Column(
                    children: txns.map((txn) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: Icon(_txnIcon(txn.type), color: _txnColor(txn.type), size: 20),
                        title: Text(txn.typeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(DateFormat('MMM dd HH:mm').format(txn.createdAt), style: const TextStyle(fontSize: 11)),
                        trailing: Text('${txn.amount} KES', style: TextStyle(fontWeight: FontWeight.bold, color: _txnColor(txn.type), fontSize: 13)),
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
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
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
