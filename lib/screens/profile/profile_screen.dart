import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/user_stats_service.dart';
import '../../services/tier_service.dart';
import '../../services/account_service.dart';
import '../../services/referral_service.dart';
import '../../models/user_tier.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/game_selector.dart';
import '../../widgets/team_selector.dart';
import '../login_screen.dart';
import 'tournament_history_screen.dart';
import 'player_stats_screen.dart';
import 'settings_screen.dart';

class AvatarData {
  final IconData icon;
  final Color color;
  final String label;

  const AvatarData({required this.icon, required this.color, required this.label});
}

const List<AvatarData> builtInAvatars = [
  AvatarData(icon: Icons.person, color: Colors.blue, label: 'Blue'),
  AvatarData(icon: Icons.person, color: Colors.red, label: 'Red'),
  AvatarData(icon: Icons.person, color: Colors.green, label: 'Green'),
  AvatarData(icon: Icons.person, color: Colors.purple, label: 'Purple'),
  AvatarData(icon: Icons.person, color: Colors.orange, label: 'Orange'),
  AvatarData(icon: Icons.person, color: Colors.teal, label: 'Teal'),
  AvatarData(icon: Icons.person, color: Colors.pink, label: 'Pink'),
  AvatarData(icon: Icons.person, color: Colors.indigo, label: 'Indigo'),
  AvatarData(icon: Icons.sports_soccer, color: Colors.blue, label: 'Soccer'),
  AvatarData(icon: Icons.star, color: Colors.amber, label: 'Star'),
  AvatarData(icon: Icons.flash_on, color: Colors.yellow, label: 'Flash'),
  AvatarData(icon: Icons.favorite, color: Colors.red, label: 'Heart'),
  AvatarData(icon: Icons.diamond, color: Colors.cyan, label: 'Diamond'),
  AvatarData(icon: Icons.shield, color: Colors.grey, label: 'Shield'),
  AvatarData(icon: Icons.fireplace, color: Colors.deepOrange, label: 'Fire'),
  AvatarData(icon: Icons.rocket_launch, color: Colors.indigo, label: 'Rocket'),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _statsService = UserStatsService();
  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  UserStats? _stats;
  bool _loadingStats = true;
  List<String> _editFavoriteGames = [];
  String? _editFavoriteTeam;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      _loadStats(auth.user!.uid);
      _editFavoriteGames = List.from(auth.user!.favoriteGames);
      _editFavoriteTeam = auth.user!.favoriteTeam;
    }
  }

  Future<void> _loadStats(String userId) async {
    final stats = await _statsService.getUserStats(userId);
    if (mounted) setState(() {
      _stats = stats;
      _loadingStats = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static int? _parseAvatarIndex(String? photoUrl) {
    if (photoUrl == null || !photoUrl.startsWith('avatar:')) return null;
    return int.tryParse(photoUrl.substring(7));
  }

  static bool _isBuiltInAvatar(String? photoUrl) => photoUrl?.startsWith('avatar:') ?? false;

  Widget _buildAvatarWidget(String? photoUrl, double radius, BuildContext context) {
    final index = _parseAvatarIndex(photoUrl);
    if (index != null && index >= 0 && index < builtInAvatars.length) {
      final avatar = builtInAvatars[index];
      return CircleAvatar(
        radius: radius,
        backgroundColor: avatar.color.withValues(alpha: 0.15),
        child: Icon(avatar.icon, size: radius, color: avatar.color),
      );
    }
    if (photoUrl != null && !_isBuiltInAvatar(photoUrl)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: radius, color: Colors.grey),
    );
  }

  void _startEditing() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameController.text = user.fullName;
    _usernameController.text = user.username;
    _phoneController.text = user.phoneNumber;
    setState(() {
      _isEditing = true;
      _editFavoriteGames = List.from(user.favoriteGames);
      _editFavoriteTeam = user.favoriteTeam;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await _userService.updateUser(auth.user!.uid, {
      'fullName': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'favoriteGames': _editFavoriteGames,
      'favoriteTeam': _editFavoriteTeam,
    });
    if (auth.user != null) {
      await _loadStats(auth.user!.uid);
      await auth.refreshUser();
    }
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Choose Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _pickAndUploadImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _pickAndUploadImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Built-in Avatars', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: builtInAvatars.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final auth = context.read<AuthProvider>();
                    await _userService.updateUser(auth.user!.uid, {
                      'photoUrl': 'avatar:$i',
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar updated!'), backgroundColor: Colors.green),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: builtInAvatars[i].color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: builtInAvatars[i].color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(builtInAvatars[i].icon, size: 32, color: builtInAvatars[i].color),
                        const SizedBox(height: 4),
                        Text(builtInAvatars[i].label, style: TextStyle(fontSize: 10, color: builtInAvatars[i].color, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    final auth = context.read<AuthProvider>();
    final url = await _userService.uploadProfileImage(auth.user!.uid, image);
    if (!mounted) return;
    if (url == 'TOO_LARGE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large. Max 5MB.'), backgroundColor: Colors.red),
      );
    } else if (url != null) {
      await _userService.updateUser(auth.user!.uid, {'photoUrl': url});
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Try a smaller image or check your connection.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
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
    if (confirmed != true || !mounted) return;

    final service = AccountService();
    final deleted = await service.deleteAccount();
    if (!mounted) return;

    if (deleted) {
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
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

  Future<void> _logout() async {
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
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              )
            else
              TextButton(
                onPressed: _saveProfile,
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final user = auth.user;
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _showAvatarPicker : null,
                      child: _buildAvatarWidget(user.photoUrl, 50, context),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarPicker,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showAvatarPicker,
                  icon: const Icon(Icons.face, size: 16),
                  label: const Text('Change Avatar', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),
              if (_isEditing) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TeamSelector(
                  selectedTeam: _editFavoriteTeam,
                  favoriteTeam: user.favoriteTeam,
                  onSelected: (t) => setState(() => _editFavoriteTeam = t),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'Favorite Games'),
                const SizedBox(height: 8),
                FavoriteGamesSelector(
                  selectedGames: _editFavoriteGames,
                  onChanged: (games) => setState(() => _editFavoriteGames = games),
                ),
                const SizedBox(height: 24),
              ] else ...[
                AppCard(
                  child: Column(
                    children: [
                      _ProfileTile(label: 'Name', value: user.fullName),
                      const Divider(),
                      _ProfileTile(label: 'Username', value: '@${user.username}'),
                      const Divider(),
                      _ProfileTile(label: 'Email', value: user.email),
                      const Divider(),
                      _ProfileTile(label: 'Phone', value: user.phoneNumber),
                    ],
                  ),
                ),
                if (user.isAdmin) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isSuperAdmin
                            ? Colors.amber.withValues(alpha: 0.15)
                            : user.isSubAdmin
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isSuperAdmin ? Icons.star : Icons.admin_panel_settings,
                            size: 16,
                            color: user.isSuperAdmin ? Colors.amber : user.isSubAdmin ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(user.roleLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13,
                                color: user.isSuperAdmin ? Colors.amber.shade800 : user.isSubAdmin ? Colors.orange.shade800 : Colors.blue.shade800,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_loadingStats)
                  const Center(child: CircularProgressIndicator())
                else if (_stats != null)
                  Column(
                    children: [
                      Row(
                        children: [
                          StatCard(icon: Icons.sports_soccer, label: 'Played', value: '${_stats!.tournamentsPlayed}', color: Colors.blue),
                          const SizedBox(width: 12),
                          StatCard(icon: Icons.emoji_events, label: 'Won', value: '${_stats!.tournamentsWon}', color: Colors.amber),
                          const SizedBox(width: 12),
                          StatCard(icon: Icons.monetization_on, label: 'Prize', value: '${_stats!.prizeMoney} KES', color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PlayerStatsScreen(
                              userId: user.uid,
                              userName: user.username ?? user.fullName,
                            ),
                          )),
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: const Text('View Detailed Stats'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => TournamentHistoryScreen(userId: user.uid),
                          )),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Tournament History'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReferralSection(user),
                      const SizedBox(height: 16),
                      _buildTierSection(user),
                    ],
                  ),
                if (user.favoriteTeam != null) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text('Favorite Team'),
                      subtitle: Text(user.favoriteTeam!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (user.favoriteGames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Favorite Games', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: user.favoriteGames.map((g) => Chip(
                            label: Text(g, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (!_isEditing) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTierSection(UserModel user) {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    final tierService = TierService();
    final accountAge = DateTime.now().difference(user.createdAt).inDays;
    final currentTier = tierService.calculateTier(
      stats: stats,
      accountAgeDays: accountAge,
      emailVerified: user.emailVerified,
    );
    final nextTier = currentTier.next;
    final progress = tierService.progressToNext(stats, accountAge, user.emailVerified);
    final reqs = tierService.getRequirementsForNext(stats, accountAge, user.emailVerified);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(currentTier.iconPath, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${currentTier.label} Tier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (nextTier != currentTier)
                    Text('Next: ${nextTier.label}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
          if (nextTier != currentTier) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Requirements for next tier:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            ...reqs.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(r.met ? Icons.check_circle : Icons.circle_outlined, size: 16, color: r.met ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(r.label, style: TextStyle(fontSize: 13, color: r.met ? Colors.green : Colors.grey.shade700)),
                  const Spacer(),
                  Text('${r.current}/${r.target}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildReferralSection(UserModel user) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text('Refer & Earn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Share your code and earn bonuses when friends join!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.referralCode.isNotEmpty ? user.referralCode : '---',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: user.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: Icon(Icons.copy, size: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Join me on NativeCodeX Tournaments! Use my referral code: ${user.referralCode}\n\nDownload: https://github.com/shelad3/tournaments-app/releases',
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ReferralStat(icon: Icons.people, label: 'Referred', value: '${user.referralCount}', color: Colors.blue),
              const SizedBox(width: 12),
              _ReferralStat(icon: Icons.monetization_on, label: 'Earned', value: '${user.referralEarnings} KES', color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ReferralStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
