import 'package:flutter/material.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const _versions = [
    _VersionEntry(
      version: '1.4.0',
      date: 'May 2026',
      features: [
        'Admin hierarchy with Sub Admin tiers (entry fee cap, daily limit, announcement approval)',
        'User tier system: Bronze, Silver, Gold, Platinum with upgrade requirements',
        'Prize distribution: set 1st/2nd/3rd place percentage splits in tournament creation',
        'Waiting list: join/leave queue with auto-promote when spots open',
        'Email verification gate before joining paid tournaments',
        'Tier-restricted tournaments with lock badge',
        'Firestore rules fixed for participations, matches, chat, notifications, forum, waiting list',
        'Composite indexes for faster queries',
        'Change password from profile',
        'What\'s New and Upcoming Features pages',
      ],
    ),
    _VersionEntry(
      version: '1.3.0',
      date: 'Apr 2026',
      features: [
        'Tournament history: view past tournaments with win/loss results',
        'Check-in system: check in before tournament starts, admin check-in/undo',
        'Player stats page with win rate and per-game breakdown',
        'Notification bell with unread badge',
        'Match scheduling with proposals and countdown',
        'Forum channels with admin-created channels',
        'Match result reporting with mutual confirmation',
        'Firestore stream timeouts with retry UI',
      ],
    ),
    _VersionEntry(
      version: '1.2.0',
      date: 'Mar 2026',
      features: [
        'Wallet system with M-Pesa deposits and withdrawals',
        'Tournament brackets with single-elimination format',
        'Admin dashboard with tournament management',
        'User profiles with avatar selection and photo upload',
        'Follow system for users',
        'Push notifications for tournaments',
      ],
    ),
    _VersionEntry(
      version: '1.1.0',
      date: 'Feb 2026',
      features: [
        'Game categories and game selector',
        'Platform support for tournaments',
        'Admin announcements system',
        'Leaderboard with player rankings',
        'Dark mode support',
      ],
    ),
    _VersionEntry(
      version: '1.0.0',
      date: 'Jan 2026',
      features: [
        'Initial release',
        'User registration and login',
        'Create and join tournaments',
        'Free and paid tournament entry types',
        'Basic profile management',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _versions.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (_, i) {
          final v = _versions[i];
          final isLatest = i == 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLatest ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v${v.version}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLatest ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(v.date, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  if (isLatest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Latest', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              ...v.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 14, height: 1.4))),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _VersionEntry {
  final String version;
  final String date;
  final List<String> features;
  const _VersionEntry({
    required this.version,
    required this.date,
    required this.features,
  });
}
