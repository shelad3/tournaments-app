import 'package:flutter/material.dart';

class UpcomingFeaturesScreen extends StatelessWidget {
  const UpcomingFeaturesScreen({super.key});

  static const _planned = [
    _FeatureGroup(
      icon: Icons.people,
      color: Colors.green,
      title: 'Referral Program',
      items: [
        'Refer friends & earn bonus when they join and play',
        'Both referrer and referee get rewarded',
        'Track your referrals and earnings in profile',
        'Withdraw referral earnings to M-Pesa',
      ],
    ),
    _FeatureGroup(
      icon: Icons.share,
      color: Colors.blue,
      title: 'Share & Viral Growth',
      items: [
        'Share tournament as an image to WhatsApp/Instagram',
        'Shareable winner result cards with ranking & prize',
        'Deep links that open the app directly',
        'Public tournament gallery (no login required)',
      ],
    ),
    _FeatureGroup(
      icon: Icons.sports_esports,
      color: Colors.amber,
      title: 'Tournament Enhancements',
      items: [
        'Free-to-play tournaments with small prizes',
        'Team/clan tournaments (2v2, 3v3, 5v5)',
        'Onboarding first-play bonus rewards',
        'Live leaderboard: top players this week/month',
        'Match reminders via SMS + push notification',
      ],
    ),
    _FeatureGroup(
      icon: Icons.payments,
      color: Colors.green,
      title: 'Payments & Rewards',
      items: [
        'In-app M-Pesa STK push (no manual M-Pesa)',
        'Subscription tiers with perks and discounts',
        'Weekly/monthly leaderboard with cash prizes',
        'Promo codes and discount system',
      ],
    ),
    _FeatureGroup(
      icon: Icons.group,
      color: Colors.blue,
      title: 'Social & Community',
      items: [
        'Join our Discord community for exclusive tournaments',
        'In-app voice chat during matches',
        'Clans/teams with shared rankings',
        'Live streaming integration (Twitch/YouTube)',
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
      appBar: AppBar(title: const Text('Roadmap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white.withValues(alpha: 0.9), size: 20),
                    const SizedBox(width: 8),
                    Text('What\'s coming next',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Vote on features by contacting support',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
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
