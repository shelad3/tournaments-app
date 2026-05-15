import 'package:flutter/material.dart';

class UpcomingFeaturesScreen extends StatelessWidget {
  const UpcomingFeaturesScreen({super.key});

  static const _planned = [
    _FeatureGroup(
      icon: Icons.emoji_events,
      color: Colors.amber,
      title: 'Tournament Enhancements',
      items: [
        'Multi-stage tournaments (group stage → playoffs)',
        'Double-elimination bracket option',
        'Team/crew tournaments with roster management',
        'Tournament templates for quick creation',
        'Auto-generate matches as participants join',
      ],
    ),
    _FeatureGroup(
      icon: Icons.payments,
      color: Colors.green,
      title: 'Payments & Rewards',
      items: [
        'Referral rewards: earn bonus when friends join',
        'Weekly/monthly leaderboard with cash prizes',
        'Subscription tiers with perks',
        'Promo codes and discount system',
        'Instant withdrawals to mobile money',
      ],
    ),
    _FeatureGroup(
      icon: Icons.group,
      color: Colors.blue,
      title: 'Social & Community',
      items: [
        'In-app voice chat during tournaments',
        'Clans/teams with shared rankings',
        'Live streaming integration (Twitch/YouTube)',
        'Tournament highlights and replay sharing',
        'Advanced user search and friend recommendations',
      ],
    ),
    _FeatureGroup(
      icon: Icons.analytics,
      color: Colors.purple,
      title: 'Analytics & Insights',
      items: [
        'Personal performance dashboard with charts',
        'Head-to-head statistics against other players',
        'Game-specific heat maps and trends',
        'Tournament engagement metrics for admins',
        'Export stats to share on social media',
      ],
    ),
    _FeatureGroup(
      icon: Icons.security,
      color: Colors.red,
      title: 'Platform & Security',
      items: [
        'Two-factor authentication (2FA)',
        'Session management and device tracking',
        'Report and moderation system',
        'Automated fraud detection for tournaments',
        'GDPR/privacy data export tool',
      ],
    ),
    _FeatureGroup(
      icon: Icons.lightbulb,
      color: Colors.orange,
      title: 'General Improvements',
      items: [
        'Offline mode for browsing tournaments',
        'Calendar sync (Google Calendar, etc.)',
        'Multiple language support',
        'In-app customer support chat',
        'Performance optimizations and reduced APK size',
        'Tablet and landscape layout support',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These features are in development. Vote and suggest ideas by contacting support.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._planned.map((group) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(group.icon, color: group.color, size: 22),
                    const SizedBox(width: 10),
                    Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                ...group.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _FeatureGroup {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
  const _FeatureGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });
}
