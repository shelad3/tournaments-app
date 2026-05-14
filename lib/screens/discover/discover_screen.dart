import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/discover_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../profile/user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.read<DiscoverProvider>().loadFollowing(auth.user!.uid);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DiscoverProvider>().search('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => context.read<DiscoverProvider>().search(v),
            ),
          ),
          Expanded(
            child: Consumer2<DiscoverProvider, AuthProvider>(
              builder: (_, discover, auth, __) {
                if (discover.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_searchController.text.isEmpty) {
                  return EmptyState(
                    icon: Icons.explore,
                    title: 'Discover new people',
                    subtitle: 'Search by name, username, or email',
                  );
                }
                if (discover.searchResults.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search,
                    title: 'No users found',
                    subtitle: 'Try a different search term',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: discover.searchResults.length,
                  itemBuilder: (_, i) {
                    final user = discover.searchResults[i];
                    final isMe = user.uid == auth.user?.uid;
                    return _UserCard(
                      user: user,
                      isFollowing: discover.isFollowing(user.uid),
                      isMe: isMe,
                      onFollow: () => discover.toggleFollow(auth.user!.uid, user.uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isFollowing;
  final bool isMe;
  final VoidCallback onFollow;

  const _UserCard({
    required this.user,
    required this.isFollowing,
    required this.isMe,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.compact(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: user.uid),
      )),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('@${user.username}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (user.favoriteTeam != null)
                  Text(user.favoriteTeam!,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          if (!isMe)
            TextButton(
              onPressed: onFollow,
              style: TextButton.styleFrom(
                backgroundColor: isFollowing
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: isFollowing
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
        ],
      ),
    );
  }
}
