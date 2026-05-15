import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import 'admin_tournaments.dart';
import 'admin_messages.dart';
import 'admin_manage_admins.dart';
import 'admin_winners.dart';
import 'admin_super_wallet.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (auth.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Manage Admins',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageAdmins())),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
        builder: (_, tournSnap) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('messages').snapshots(),
          builder: (_, msgSnap) => StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('participations').snapshots(),
            builder: (_, partSnap) => StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (_, userSnap) {
                final tournamentCount = tournSnap.data?.docs.length ?? 0;
                final messageCount = msgSnap.data?.docs.length ?? 0;
                final participantCount = partSnap.data?.docs.length ?? 0;
                final userCount = userSnap.data?.docs.length ?? 0;

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Welcome, ${auth.user?.fullName ?? 'Admin'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: auth.isSuperAdmin
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : auth.isSubAdmin
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auth.user?.roleLabel ?? 'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12,
                                color: auth.isSuperAdmin
                                    ? Colors.amber.shade800
                                    : auth.isSubAdmin
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800,
                              ),
                            ),
                          ),
                          if (auth.isSubAdmin && auth.user != null) ...[
                            const SizedBox(width: 8),
                            if (auth.user!.maxEntryFee != null)
                              _LimitChip(icon: Icons.money_off, label: 'Max ${auth.user!.maxEntryFee} KES'),
                            if (auth.user!.maxDailyTournaments != null)
                              _LimitChip(icon: Icons.calendar_today, label: '${auth.user!.maxDailyTournaments}/day'),
                            if (auth.user!.approvalRequired)
                              _LimitChip(icon: Icons.approval, label: 'Needs approval'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _StatGrid(
                        stats: [
                          _StatCard(icon: Icons.sports_soccer, label: 'Tournaments', count: tournamentCount, color: Colors.blue),
                          _StatCard(icon: Icons.message, label: 'Messages', count: messageCount, color: Colors.orange),
                          _StatCard(icon: Icons.how_to_vote, label: 'Participations', count: participantCount, color: Colors.green),
                          _StatCard(icon: Icons.people, label: 'Users', count: userCount, color: Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (auth.user!.hasPermission('manage_tournaments'))
                        _ActionCard(
                          icon: Icons.add_circle,
                          label: 'Manage Tournaments',
                          desc: auth.isSubAdmin ? 'Create, edit or delete your tournaments' : 'Create, edit or delete tournaments',
                          color: Colors.blue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTournaments())),
                        ),
                      if (auth.user!.hasPermission('manage_messages'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _ActionCard(
                            icon: Icons.add_comment,
                            label: 'Manage Announcements',
                            desc: auth.isSubAdmin && (auth.user?.approvalRequired ?? false)
                                ? 'Create announcements (requires approval)'
                                : 'Create, edit or delete announcements',
                            color: Colors.orange,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMessages())),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _ActionCard(
                          icon: Icons.emoji_events,
                          label: 'Award Tournament Winners',
                          desc: 'Select winners and release prize money',
                          color: Colors.amber,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWinners())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _ActionCard(
                          icon: Icons.account_balance,
                          label: 'Super Wallet',
                          desc: 'View prize pool & platform earnings',
                          color: Colors.green,
                          onTap: () {
                            context.read<WalletProvider>().loadSuperWallet();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSuperWallet()));
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LimitChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<_StatCard> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => stats[i],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text('$count', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.desc, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
