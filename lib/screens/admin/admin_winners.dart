import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../services/wallet_service.dart';

class AdminWinners extends StatelessWidget {
  const AdminWinners({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Winners')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tournaments = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (_, i) {
              final t = TournamentModel.fromMap(tournaments[i].data() as Map<String, dynamic>, tournaments[i].id);
              return _TournamentWinnerCard(tournament: t, docId: tournaments[i].id);
            },
          );
        },
      ),
    );
  }
}

class _TournamentWinnerCard extends StatelessWidget {
  final TournamentModel tournament;
  final String docId;
  const _TournamentWinnerCard({required this.tournament, required this.docId});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('participations')
            .where('tournamentId', isEqualTo: tournament.id)
            .where('paid', isEqualTo: true)
            .snapshots(),
        builder: (_, partSnap) {
          final paidCount = partSnap.data?.docs.length ?? 0;
          final prizePool = tournament.entryFee * paidCount;
          return ExpansionTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(tournament.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${dateFormat.format(tournament.hostDate)} • $paidCount paid • $prizePool KES prize'),
            children: [
              if (paidCount > 0)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('participations')
                      .where('tournamentId', isEqualTo: tournament.id)
                      .where('paid', isEqualTo: true)
                      .snapshots(),
                  builder: (_, paidSnap) {
                    final paidDocs = paidSnap.data?.docs ?? [];
                    return Column(
                      children: paidDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
                          builder: (_, userSnap) {
                            final userData = userSnap.data?.data() as Map<String, dynamic>?;
                            final name = userData?['fullName'] ?? 'Unknown';
                            final email = userData?['email'] ?? '';
                            return ListTile(
                              leading: const Icon(Icons.person, color: Colors.grey),
                              title: Text(name),
                              subtitle: Text(email),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.emoji_events, size: 18),
                                label: const Text('Select Winner'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                onPressed: () => _selectWinner(context, tournament.id, data['userId'], prizePool),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No paid participants yet', style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  void _selectWinner(BuildContext context, String tournamentId, String winnerId, int prizeAmount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Winner'),
        content: Text('Award $prizeAmount KES prize to this player?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Confirm Winner')),
        ],
      ),
    );
    if (confirmed != true) return;
    final walletService = WalletService();
    final awarded = await walletService.awardPrize(tournamentId, winnerId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(awarded ? '$prizeAmount KES awarded to winner!' : 'Failed to award prize'),
        backgroundColor: awarded ? Colors.green : Colors.red,
      ),
    );
  }
}
