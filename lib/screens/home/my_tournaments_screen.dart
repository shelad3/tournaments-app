import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tournament_model.dart';
import 'tournament_detail_screen.dart';

class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tournaments')),
      body: Consumer2<TournamentProvider, AuthProvider>(
        builder: (_, provider, auth, __) {
          final mine = provider.myTournaments;
          if (mine.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No registered tournaments yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => provider.loadTournaments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              itemBuilder: (_, i) => _RegisteredTournamentCard(tournament: mine[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RegisteredTournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const _RegisteredTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startTime = tournament.startTime ?? tournament.hostDate;
    final timeLeft = startTime.difference(DateTime.now());
    final isPast = timeLeft.isNegative;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tournament.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  tournament.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 160, child: Center(child: Icon(Icons.sports_soccer, size: 48))),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Registered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tournament.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tournament.isMoney ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.isMoney ? '${tournament.entryFee} KES' : 'Free',
                          style: TextStyle(
                            color: tournament.isMoney ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isPast && timeLeft.inDays <= 30)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            _formatCountdown(timeLeft),
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  if (!isPast && timeLeft.inDays > 30)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Starts: ${dateFormat.format(startTime)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  if (isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Ended', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h remaining';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m remaining';
    if (d.inMinutes > 0) return '${d.inMinutes}m remaining';
    return 'Starting soon';
  }
}
