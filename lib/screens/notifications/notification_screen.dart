import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tournament_model.dart';
import '../../widgets/empty_state.dart';
import '../home/tournament_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, prov, __) {
              if (prov.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: auth.isLoggedIn
                    ? () => prov.markAllAsRead(auth.user!.uid)
                    : null,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              subtitle: 'You\'ll see updates about tournaments, matches, and more here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: prov.notifications.length,
            itemBuilder: (_, i) => _NotificationTile(
              notification: prov.notifications[i],
              onTap: () {
                prov.markAsRead(prov.notifications[i].id);
                final n = prov.notifications[i];
                if (n.relatedId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TournamentDetailScreen(
                      tournament: TournamentModel(
                        id: n.relatedId!,
                        title: n.title,
                        description: '',
                        createdBy: '',
                        signUpEndDate: DateTime.now(),
                        hostDate: DateTime.now(),
                        createdAt: DateTime.now(),
                        entryType: EntryType.free,
                        entryFee: 0,
                      ),
                    ),
                  ));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _iconForType(String type) {
    switch (type) {
      case 'match_scheduled': return Icons.schedule;
      case 'match_result': return Icons.emoji_events;
      case 'tournament_start': return Icons.play_circle;
      case 'tournament_end': return Icons.check_circle;
      case 'new_tournament': return Icons.add_circle;
      case 'new_follower': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'match_scheduled': return Colors.blue;
      case 'match_result': return Colors.amber;
      case 'tournament_start': return Colors.green;
      case 'tournament_end': return Colors.teal;
      case 'new_tournament': return Colors.indigo;
      case 'new_follower': return Colors.pink;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('MMM dd, HH:mm');
    final isRead = notification.read;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorForType(notification.type).withValues(alpha: 0.15),
          child: Icon(_iconForType(notification.type), color: _colorForType(notification.type), size: 20),
        ),
        title: Text(notification.title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(timeFormat.format(notification.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: isRead ? null : Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        ),
        onTap: onTap,
      ),
    );
  }
}
