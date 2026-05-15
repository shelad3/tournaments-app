import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/tournament_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/message_provider.dart';
import '../providers/forum_provider.dart';
import '../providers/notification_provider.dart';
import '../services/fcm_service.dart';
import '../services/fcm_service.dart' show firebaseMessagingBackgroundHandler;
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'home/home_screen.dart';
import 'wallet/wallet_screen.dart';
import 'messages/messages_screen.dart';
import 'forum/forum_screen.dart';
import 'discover/discover_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/admin_dashboard.dart';
import 'lock_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _lastVisibleNav = 0;
  bool _initialResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_initialResume) {
        _initialResume = false;
        return;
      }
      final lockProv = context.read<AppLockProvider>();
      if (lockProv.isEnabled) {
        lockProv.lock();
      }
    }
  }

  void _initServices() {
    final fcm = FcmService();
    fcm.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _initFcm(fcm);
    final tournamentProv = context.read<TournamentProvider>();
    tournamentProv.loadTournaments();
    final messageProv = context.read<MessageProvider>();
    messageProv.loadMessages();
    final forumProv = context.read<ForumProvider>();
    forumProv.loadChannels();
    final walletProv = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      walletProv.loadWallet(auth.user!.uid);
      walletProv.loadTransactions(auth.user!.uid);
      tournamentProv.loadUserParticipations(auth.user!.uid);
      fcm.saveTokenToFirestore(auth.user!.uid);
      context.read<NotificationProvider>().loadNotifications(auth.user!.uid);
    }
    _checkForUpdate();
  }

  void _checkForUpdate() async {
    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdate();
    if (!mounted || updateInfo == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  Future<void> _initFcm(FcmService fcm) async {
    await fcm.requestPermission();
    fcm.onForegroundMessage((message) {
      if (message.notification == null) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${message.notification!.title}: ${message.notification!.body}'),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  List<Widget> _screens(bool isAdmin) => [
    const HomeScreen(),
    const WalletScreen(),
    const MessagesScreen(),
    const ForumScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
    if (isAdmin) const AdminDashboard(),
  ];

  List<int> _visibleScreenIndices(bool isAdmin) => [
    0, // Home
    1, // Wallet
    4, // Discover
    5, // Profile
    if (isAdmin) 6, // Admin
  ];

  int _navToScreen(int navIdx, bool isAdmin) =>
      _visibleScreenIndices(isAdmin)[navIdx];

  int _screenToNav(int screenIdx, bool isAdmin) =>
      _visibleScreenIndices(isAdmin).indexOf(screenIdx);

  static const _navData = [
    (Icons.home_rounded, Icons.home_rounded, 'Home'),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.explore_rounded, Icons.explore_rounded, 'Discover'),
    (Icons.person_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _adminNavData = (Icons.admin_panel_settings_rounded, Icons.admin_panel_settings_rounded, 'Admin');

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.message_rounded)),
              title: const Text('Messages'),
              subtitle: const Text('View announcements'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().switchTo(2);
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.forum_rounded)),
              title: const Text('Forum'),
              subtitle: const Text('Discuss with the community'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().switchTo(3);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockProv = context.watch<AppLockProvider>();
    if (lockProv.isEnabled && !lockProv.isAuthenticated) {
      return const LockScreen();
    }

    final tabProv = context.watch<TabProvider>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;
    final screens = _screens(isAdmin);
    final screenIdx = tabProv.currentIndex.clamp(0, screens.length - 1);
    final navIdx = _screenToNav(screenIdx, isAdmin);
    if (navIdx >= 0) _lastVisibleNav = navIdx;

    if (tabProv.currentIndex >= screens.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabProv.switchTo(0);
      });
    }

    return Scaffold(
      body: IndexedStack(index: screenIdx, children: screens),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _navData.length; i++)
              _NavBarItem(
                icon: _navData[i].$1,
                label: _navData[i].$3,
                selected: _lastVisibleNav == i,
                onTap: () => tabProv.switchTo(_navToScreen(i, isAdmin)),
              ),
            _NavFab(onTap: () => _showMoreOptions(context)),
            if (isAdmin)
              _NavBarItem(
                icon: _adminNavData.$1,
                label: _adminNavData.$3,
                selected: _lastVisibleNav == _navData.length,
                onTap: () => tabProv.switchTo(_navToScreen(_navData.length, isAdmin)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Colors.blue
        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _NavFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NavFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? const Color(0xFF1A237E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
      ),
    );
  }
}
