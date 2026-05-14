import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart';
import '../../models/league_update_model.dart';
import '../../services/league_update_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Updates'),
            Tab(text: 'Announcements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UpdatesTab(),
          _AnnouncementsTab(),
        ],
      ),
    );
  }
}

class _UpdatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Center(child: Text('Sign in to see updates'));
    }

    return StreamBuilder<List<LeagueUpdateModel>>(
      stream: LeagueUpdateService().getUpdates(user),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final updates = snap.data!;
        if (updates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No updates yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Follow tournaments in your favourite games to see updates here',
                    style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: updates.length,
            itemBuilder: (_, i) => _UpdateCard(update: updates[i]),
          ),
        );
      },
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (_, provider, __) {
        if (provider.messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No announcements yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => provider.loadMessages(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.messages.length,
            itemBuilder: (_, i) => _MessageCard(message: provider.messages[i]),
          ),
        );
      },
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final LeagueUpdateModel update;
  const _UpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: update.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(update.icon, color: update.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(update.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(update.body, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (update.gameName != null) ...[
                        Text(update.gameName!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        const SizedBox(width: 8),
                      ],
                      Text(dateFormat.format(update.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final MessageModel message;
  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: message.priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(message.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        if (message.priority != MessagePriority.normal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: message.priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(message.priorityLabel, style: TextStyle(fontSize: 10, color: message.priorityColor, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(message.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(dateFormat.format(message.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(message.title)),
            if (message.priority != MessagePriority.normal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: message.priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(message.priorityLabel, style: TextStyle(fontSize: 11, color: message.priorityColor, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.body, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 16),
              Text(DateFormat('MMM dd, yyyy HH:mm').format(message.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
