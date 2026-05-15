import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_stats_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserStatsService _service = UserStatsService();
  UserModel? _user;
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await _service.getUser(widget.userId);
    final stats = await _service.getUserStats(widget.userId);
    if (mounted) setState(() {
      _user = user;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_user?.username ?? 'User Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('User not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: _user!.photoUrl != null
                ? NetworkImage(_user!.photoUrl!)
                : null,
            child: _user!.photoUrl == null
                ? Text(_user!.fullName.isNotEmpty
                    ? _user!.fullName[0].toUpperCase()
                    : '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 16),
          Text(_user!.fullName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('@${_user!.username}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          if (_user!.favoriteTeam != null) ...[
            const SizedBox(height: 8),
            Chip(
              avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
              label: Text(_user!.favoriteTeam!),
            ),
          ],
          const SizedBox(height: 8),
          Text(_user!.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildStats(),
          if (_user!.isAdmin) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                _user!.roleLabel,
                style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(
          icon: Icons.sports_soccer,
          label: 'Played',
          value: '${_stats?.tournamentsPlayed ?? 0}',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.emoji_events,
          label: 'Won',
          value: '${_stats?.tournamentsWon ?? 0}',
          color: Colors.amber,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.monetization_on,
          label: 'Prize',
          value: '${_stats?.prizeMoney ?? 0} KES',
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
