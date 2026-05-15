import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_history_entry.dart';
import '../../services/tournament_history_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';

class TournamentHistoryScreen extends StatefulWidget {
  final String userId;

  const TournamentHistoryScreen({super.key, required this.userId});

  @override
  State<TournamentHistoryScreen> createState() => _TournamentHistoryScreenState();
}

class _TournamentHistoryScreenState extends State<TournamentHistoryScreen> {
  final _service = TournamentHistoryService();
  List<TournamentHistoryEntry>? _entries;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final entries = await _service.getHistory(widget.userId);
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries == null || _entries!.isEmpty
              ? const EmptyState(icon: Icons.history, title: 'No tournament history yet')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries!.length,
                    itemBuilder: (_, i) => _buildEntry(_entries![i]),
                  ),
                ),
    );
  }

  Widget _buildEntry(TournamentHistoryEntry entry) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (entry.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(entry.imageUrl!, width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: entry.won ? Colors.amber.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(entry.won ? Icons.emoji_events : Icons.sports_soccer, color: entry.won ? Colors.amber : Colors.grey, size: 28),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(entry.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  if (entry.gameName.isNotEmpty)
                    Text(entry.gameName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.won ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.won ? 'Won' : 'Lost',
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12,
                      color: entry.won ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                if (entry.prizeMoney > 0) ...[
                  const SizedBox(height: 6),
                  Text('+${entry.prizeMoney} KES',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
