import 'package:flutter/material.dart';
import '../../services/user_stats_service.dart';
import '../../widgets/app_card.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PlayerStatsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final UserStatsService _statsService = UserStatsService();
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _statsService.getUserStats(widget.userId);
    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userName} Stats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Could not load stats'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildOverview(),
                      const SizedBox(height: 24),
                      if (_stats!.perGame.isNotEmpty) ...[
                        Text('By Game', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._stats!.perGame.entries.map((e) => _buildGameRow(e.value)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverview() {
    final s = _stats!;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Played', value: '${s.tournamentsPlayed}', icon: Icons.play_circle, color: Colors.blue),
                _StatItem(label: 'Won', value: '${s.tournamentsWon}', icon: Icons.emoji_events, color: Colors.amber),
                _StatItem(label: 'Win Rate', value: '${s.winRate.toStringAsFixed(0)}%', icon: Icons.trending_up, color: Colors.green),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text('Total Prize Money: ${s.prizeMoney} KES',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameRow(GameStats g) {
    return AppCard.compact(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.gameName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${g.played} played / ${g.won} won', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${g.winRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${g.prizeMoney} KES', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
