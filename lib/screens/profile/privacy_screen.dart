import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Terms of Service'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PolicyView(),
            _TermsView(),
          ],
        ),
      ),
    );
  }
}

class _PolicyView extends StatelessWidget {
  const _PolicyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text(
          'Last updated: May 2026\n\n'
          '1. Information We Collect\n'
          'We collect information you provide when creating an account: name, email, username, '
          'phone number, and profile information. We also collect tournament participation data, '
          'transactions, and chat messages.\n\n'
          '2. How We Use Your Information\n'
          'We use your information to provide tournament management services, process payments, '
          'send notifications, and improve the app experience.\n\n'
          '3. Data Storage\n'
          'Your data is stored securely on Firebase (Google Cloud Platform). We implement '
          'industry-standard security measures.\n\n'
          '4. Data Sharing\n'
          'We do not sell your personal data. We share only what is necessary for payment '
          'processing (M-Pesa) with Safaricom.\n\n'
          '5. Your Rights\n'
          'You can request account deletion at any time. Contact sheldonramu8@gmail.com for '
          'data deletion requests.\n\n'
          '6. Contact\n'
          'sheldonramu8@gmail.com',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class _TermsView extends StatelessWidget {
  const _TermsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Terms of Service', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text(
          'Last updated: May 2026\n\n'
          '1. Acceptance\n'
          'By using Tournaments, you agree to these terms. If you do not agree, do not use the app.\n\n'
          '2. Account\n'
          'You are responsible for maintaining your account credentials. You must provide accurate '
          'information.\n\n'
          '3. Payments\n'
          'All tournament fees are non-refundable. Prizes are credited to your in-app wallet and '
          'can be withdrawn to your registered M-Pesa number. Minimum withdrawal is 50 KES.\n\n'
          '4. Fair Play\n'
          'Cheating, exploiting bugs, or creating multiple accounts may result in account suspension.\n\n'
          '5. Limitation of Liability\n'
          'We are not liable for any losses arising from use of the app, including but not limited '
          'to tournament disputes or payment issues.\n\n'
          '6. Changes\n'
          'We may update these terms. Continued use after changes constitutes acceptance.\n\n'
          '7. Contact\n'
          'sheldonramu8@gmail.com',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}
