import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/tournament_service.dart';
import '../notifications/notification_screen.dart';
import '../../models/tournament_model.dart';
import '../../config/game_categories.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'tournament_detail_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, notifProv, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  )),
                ),
                if (notifProv.unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${notifProv.unreadCount > 9 ? '9+' : notifProv.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Leaderboard',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const LeaderboardScreen(),
            )),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tournaments...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              _buildFilterRow(),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tournaments'),
                  Tab(text: 'Registered'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (!auth.isLoggedIn || auth.user!.emailVerified) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verify your email to join paid tournaments.',
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await auth.sendVerificationEmail();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification email sent! Check your inbox.')),
                        );
                      },
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text('Resend', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
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
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text('Check', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTournaments(),
                _buildRegisteredTournaments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TournamentModel> _applyFilters(List<TournamentModel> list) {
    var result = list;
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();
    }
    if (_selectedCategory != null) {
      result = result.where((t) => t.gameCategory == _selectedCategory).toList();
    }
    return result;
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'All',
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ...gameCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _CategoryChip(
              label: cat.name,
              icon: cat.icon,
              selected: _selectedCategory == cat.name,
              onTap: () => setState(() {
                _selectedCategory = _selectedCategory == cat.name ? null : cat.name;
              }),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAllTournaments() {
    return Consumer2<TournamentProvider, AuthProvider>(
      builder: (_, provider, auth, __) {
        if (!provider.hasLoaded) {
          return const ShimmerList(itemHeight: 180);
        }
        if (provider.error != null && provider.tournaments.isEmpty) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: 'Connection error',
            subtitle: provider.error,
            action: ElevatedButton.icon(
              onPressed: () => provider.loadTournaments(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          );
        }
        final filtered = _applyFilters(provider.tournaments);
        if (filtered.isEmpty) {
          return EmptyState(
            icon: _searchQuery.isEmpty && _selectedCategory == null ? Icons.sports_soccer : Icons.search_off,
            title: _searchQuery.isEmpty && _selectedCategory == null ? 'No tournaments yet' : 'No tournaments matching your filters',
            subtitle: _searchQuery.isEmpty ? 'Check back later for new tournaments' : null,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => provider.loadTournaments(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _TournamentCard(
              tournament: filtered[i],
              isRegistered: auth.isLoggedIn ? provider.isRegistered(filtered[i].id) : false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisteredTournaments() {
    return Consumer2<TournamentProvider, AuthProvider>(
      builder: (_, provider, auth, __) {
        final mine = provider.myTournaments;
        if (!provider.hasLoaded || !provider.userParticipationsLoaded) {
          return const ShimmerList(itemHeight: 180);
        }
        final filtered = _applyFilters(mine);
        if (filtered.isEmpty) {
          return EmptyState(
            icon: _searchQuery.isEmpty && _selectedCategory == null ? Icons.sports_soccer : Icons.search_off,
            title: _searchQuery.isEmpty && _selectedCategory == null ? 'No registered tournaments yet' : 'No registered tournaments matching your filters',
            subtitle: _searchQuery.isEmpty ? 'Register for a tournament to see it here' : null,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => provider.loadTournaments(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _RegisteredTournamentCard(tournament: filtered[i]),
          ),
        );
      },
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final bool isRegistered;
  const _TournamentCard({required this.tournament, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final startTime = tournament.effectiveStartTime;
    final timeLeft = startTime.difference(DateTime.now());
    final isPast = timeLeft.isNegative;
    final canSignUp = DateTime.now().isBefore(tournament.signUpEndDate);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                tournament.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 160, child: Center(child: Icon(Icons.sports_soccer, size: 48))),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(tournament.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: tournament.isMoney ? '${tournament.entryFee} KES' : 'Free',
                color: tournament.isMoney ? Colors.green : Colors.blue,
                icon: tournament.isMoney ? Icons.monetization_on : Icons.card_giftcard,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (tournament.gameName != null) ...[
                Icon(Icons.videogame_asset, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(tournament.gameName!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(width: 12),
              ],
              if (tournament.platform != null) ...[
                Icon(Icons.devices, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(tournament.platform!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<int>(
            stream: TournamentService().acceptedCountStream(tournament.id),
            builder: (_, snap) {
              final count = snap.data;
              if (count == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('$count registered', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  if (tournament.maxParticipants != null)
                    Text(' / ${tournament.maxParticipants}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  if (tournament.isMoney && count > 0) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.monetization_on, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text('Prize: ${tournament.entryFee * count} KES',
                        style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text('Sign up by: ${dateFormat.format(tournament.signUpEndDate)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text('${dateFormat.format(startTime)} ${timeFormat.format(startTime)} - ${timeFormat.format(tournament.effectiveEndTime)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
          if (!isPast && timeLeft.inDays <= 14) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    _formatCountdown(timeLeft),
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (canSignUp && !isRegistered) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
                ),
                child: const Text('Register Now'),
              ),
            ),
          ],
          if (!canSignUp && !isRegistered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StatusBadge.red('Sign-up closed'),
            ),
          if (isRegistered && isPast)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StatusBadge.blue('Completed'),
            ),
          if (isRegistered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  StatusBadge.green('Registered'),
                  const SizedBox(width: 8),
                  if (tournament.isMoney) StatusBadge(
                    label: 'Paid',
                    color: Colors.green,
                    icon: Icons.paid,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h until start';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m until start';
    if (d.inMinutes > 0) return '${d.inMinutes}m until start';
    return 'Starting now';
  }
}

class _RegisteredTournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const _RegisteredTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final startTime = tournament.effectiveStartTime;
    final timeLeft = startTime.difference(DateTime.now());
    final isPast = timeLeft.isNegative;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: tournament)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                tournament.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 160, child: Center(child: Icon(Icons.sports_soccer, size: 48))),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusBadge.green('Registered'),
              const SizedBox(width: 8),
              if (tournament.isMoney)
                StatusBadge(
                  label: '${tournament.entryFee} KES',
                  color: Colors.green,
                  icon: Icons.paid,
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tournament.isMoney ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tournament.isMoney ? '${tournament.entryFee} KES' : 'Free',
                  style: TextStyle(
                    color: tournament.isMoney ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tournament.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (tournament.gameName != null) ...[
                Icon(Icons.videogame_asset, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(tournament.gameName!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(width: 12),
              ],
              if (tournament.platform != null) ...[
                Icon(Icons.devices, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(tournament.platform!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<int>(
            stream: TournamentService().acceptedCountStream(tournament.id),
            builder: (_, snap) {
              final count = snap.data;
              if (count == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('$count registered', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  if (tournament.maxParticipants != null)
                    Text(' / ${tournament.maxParticipants}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  if (tournament.isMoney && count > 0) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.monetization_on, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text('Prize: ${tournament.entryFee * count} KES',
                        style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          if (!isPast && timeLeft.inDays <= 30)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    _formatCountdown(timeLeft),
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (!isPast && timeLeft.inDays > 30)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('${dateFormat.format(startTime)} ${timeFormat.format(startTime)} - ${timeFormat.format(tournament.effectiveEndTime)}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
          if (isPast)
            StatusBadge.grey('Ended'),
        ],
      ),
    );
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h remaining';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m remaining';
    if (d.inMinutes > 0) return '${d.inMinutes}m remaining';
    return 'Starting soon';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: selected ? 1 : 0.7)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
