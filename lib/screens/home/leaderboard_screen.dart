import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leaderboard_entry.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../profile/user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    final lp = context.read<LeaderboardProvider>();
    final auth = context.read<AuthProvider>();
    lp.loadLeaderboard(currentUserId: auth.user?.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Consumer<LeaderboardProvider>(
        builder: (_, lp, __) {
          if (lp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lp.entries.isEmpty) {
            return EmptyState(
              icon: Icons.emoji_events,
              title: 'No leaderboard data yet',
              subtitle: 'Complete tournaments to appear here',
            );
          }
          return Column(
            children: [
              if (lp.currentUserEntry != null && lp.currentUserEntry!.rank > 3)
                _buildCurrentUserCard(lp.currentUserEntry!),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: lp.entries.length,
                  itemBuilder: (_, i) => _LeaderboardRow(
                    entry: lp.entries[i],
                    isCurrentUser: lp.currentUserEntry?.userId == lp.entries[i].userId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentUserCard(LeaderboardEntry entry) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Text('#${entry.rank}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (entry.userTeam != null)
                  Text(entry.userTeam!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.wins}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
              Text('wins', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (entry.prizeMoney > 0) ...[
                const SizedBox(height: 4),
                Text('${entry.prizeMoney} KES',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final rankColors = [Colors.amber, Colors.grey, Colors.brown];

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: entry.userId),
      )),
      borderRadius: BorderRadius.circular(12),
      child: AppCard.compact(
        margin: const EdgeInsets.only(bottom: 8),
        color: isCurrentUser ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: entry.rank <= 3 ? rankColors[entry.rank - 1] : Colors.grey.shade300,
              child: entry.rank <= 3
                  ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
                  : Text('${entry.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.userName,
                      style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600)),
                  if (entry.userTeam != null)
                    Text(entry.userTeam!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.wins} wins', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (entry.prizeMoney > 0)
                  Text('${entry.prizeMoney} KES',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
