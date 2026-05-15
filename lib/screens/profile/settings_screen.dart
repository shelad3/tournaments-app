import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../services/auth_service.dart';
import '../../services/account_service.dart';
import '../../services/update_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/update_dialog.dart';
import '../login_screen.dart';
import 'privacy_screen.dart';
import 'whats_new_screen.dart';
import 'upcoming_features_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Preferences'),
          AppCard(
            child: Consumer<ThemeProvider>(
              builder: (_, themeProv, __) => SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark theme'),
                value: themeProv.isDarkMode,
                onChanged: (_) => themeProv.toggleTheme(),
                secondary: const Icon(Icons.dark_mode),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Consumer<AppLockProvider>(
              builder: (_, lockProv, __) => SwitchListTile(
                title: const Text('App Lock'),
                subtitle: Text(
                  !lockProv.biometricAvailable
                      ? 'Device security not available'
                      : lockProv.isEnabled
                          ? 'Locked with device security'
                          : 'Secure with biometrics/PIN',
                ),
                value: lockProv.isEnabled,
                onChanged: (v) async {
                  if (!lockProv.biometricAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No biometric or device lock set up on this device')),
                    );
                    return;
                  }
                  if (v) {
                    final ok = await lockProv.authenticate();
                    if (!ok) return;
                  }
                  await lockProv.toggle(v);
                },
                secondary: const Icon(Icons.lock_outline),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (auth.user == null || auth.user!.emailVerified) return const SizedBox.shrink();
              return Column(
                children: [
                  _SectionHeader(title: 'Email Verification'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text('Email not verified', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Verify ${auth.user!.email} to join paid tournaments.', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await auth.sendVerificationEmail();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Verification email sent!')),
                                  );
                                },
                                icon: const Icon(Icons.email, size: 16),
                                label: const Text('Resend', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final verified = await auth.checkEmailVerification();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(verified ? 'Email verified!' : 'Not verified yet. Check your email.'),
                                      backgroundColor: verified ? Colors.green : Colors.orange,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Check', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
          _SectionHeader(title: 'Account'),
          _SettingsButton(
            icon: Icons.lock,
            label: 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 8),
          _SettingsButton(
            icon: Icons.system_update_outlined,
            label: 'Check for Updates',
            onTap: () => _checkUpdates(context),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Information'),
          _SettingsButton(
            icon: Icons.description_outlined,
            label: 'Privacy & Terms',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
          const SizedBox(height: 8),
          _SettingsButton(
            icon: Icons.new_releases_outlined,
            label: "What's New",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsNewScreen())),
          ),
          const SizedBox(height: 8),
          _SettingsButton(
            icon: Icons.rocket_launch_outlined,
            label: 'Upcoming Features',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpcomingFeaturesScreen())),
          ),
          const SizedBox(height: 8),
          _SettingsButton(
            icon: Icons.support_outlined,
            label: 'Contact Support',
            onTap: () => launchUrl(
              Uri.parse('mailto:sheldonramu8@gmail.com?subject=Tournaments%20Support'),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsButton(
            icon: Icons.delete_forever_outlined,
            label: 'Delete Account',
            iconColor: Colors.red,
            labelColor: Colors.red,
            onTap: () => _confirmDeleteAccount(context),
          ),
          const SizedBox(height: 16),
          _SettingsButton(
            icon: Icons.logout,
            label: 'Sign Out',
            iconColor: Colors.red,
            labelColor: Colors.red,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final current = currentCtrl.text.trim();
                      final newPw = newCtrl.text.trim();
                      final confirm = confirmCtrl.text.trim();
                      if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) return;
                      if (newPw != confirm) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (newPw.length < 8 || !RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(newPw)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Password must be 8+ chars with letters and numbers'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      final auth = AuthService();
                      final ok = await auth.changePassword(currentPassword: current, newPassword: newPw);
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
                        );
                      } else {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Current password is incorrect'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkUpdates(BuildContext context) async {
    final service = UpdateService();
    final info = await service.checkForUpdate();
    if (!context.mounted) return;
    if (info != null) {
      showDialog(
        context: context,
        builder: (_) => UpdateDialog(updateInfo: info),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on the latest version")),
      );
    }
  }

  void _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, wallet, and all data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final service = AccountService();
    final deleted = await service.deleteAccount();
    if (!context.mounted) return;

    if (deleted) {
      await context.read<AuthProvider>().signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account. Try again later.'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AuthProvider>().signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _SettingsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: iconColor),
        label: Text(label, style: labelColor != null ? TextStyle(color: labelColor) : null),
        style: labelColor != null ? OutlinedButton.styleFrom(side: BorderSide(color: labelColor!)) : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700)),
    );
  }
}


