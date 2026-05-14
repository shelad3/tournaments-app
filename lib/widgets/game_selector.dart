import 'package:flutter/material.dart';
import '../config/game_categories.dart';
import '../config/theme.dart';

class GameSelector extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedGame;
  final String? selectedPlatform;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onGameChanged;
  final ValueChanged<String?> onPlatformChanged;

  const GameSelector({
    super.key,
    this.selectedCategory,
    this.selectedGame,
    this.selectedPlatform,
    required this.onCategoryChanged,
    required this.onGameChanged,
    required this.onPlatformChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentCategory = selectedCategory != null
        ? gameCategories.firstWhere(
            (c) => c.name == selectedCategory,
            orElse: () => gameCategories.first,
          )
        : null;
    final availableGames = currentCategory?.games ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Game', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        AppTheme.gapSm,
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category),
          ),
          items: gameCategories.map((cat) => DropdownMenuItem(
            value: cat.name,
            child: Row(
              children: [
                Icon(cat.icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(cat.name),
              ],
            ),
          )).toList(),
          onChanged: (v) {
            onCategoryChanged(v);
            onGameChanged(null);
          },
        ),
        AppTheme.gapMd,
        DropdownButtonFormField<String>(
          value: selectedGame,
          decoration: const InputDecoration(
            labelText: 'Specific Game',
            prefixIcon: Icon(Icons.videogame_asset),
          ),
          items: availableGames.map((g) => DropdownMenuItem(
            value: g,
            child: Text(g, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: availableGames.isEmpty ? null : onGameChanged,
          disabledHint: const Text('Select a category first'),
        ),
        AppTheme.gapMd,
        DropdownButtonFormField<String>(
          value: selectedPlatform,
          decoration: const InputDecoration(
            labelText: 'Platform',
            prefixIcon: Icon(Icons.devices),
          ),
          items: platforms.map((p) => DropdownMenuItem(
            value: p,
            child: Text(p),
          )).toList(),
          onChanged: onPlatformChanged,
        ),
      ],
    );
  }
}

class FavoriteGamesSelector extends StatefulWidget {
  final List<String> selectedGames;
  final ValueChanged<List<String>> onChanged;

  const FavoriteGamesSelector({
    super.key,
    required this.selectedGames,
    required this.onChanged,
  });

  @override
  State<FavoriteGamesSelector> createState() => _FavoriteGamesSelectorState();
}

class _FavoriteGamesSelectorState extends State<FavoriteGamesSelector> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredGames {
    if (_searchQuery.isEmpty) return allGamesList();
    return allGamesList().where((g) => g.toLowerCase().contains(_searchQuery)).toList();
  }

  void _toggle(String game) {
    final updated = List<String>.from(widget.selectedGames);
    if (updated.contains(game)) {
      updated.remove(game);
    } else {
      updated.add(game);
    }
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search games...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
        AppTheme.gapMd,
        if (widget.selectedGames.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.selectedGames.map((g) => Chip(
              label: Text(g, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _toggle(g),
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
          AppTheme.gapMd,
        ],
        SizedBox(
          height: 300,
          child: ListView(
            children: _filteredGames.map((game) {
              final selected = widget.selectedGames.contains(game);
              return ListTile(
                dense: true,
                title: Text(game, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                trailing: selected
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)
                    : const Icon(Icons.add_circle_outline, size: 20, color: Colors.grey),
                onTap: () => _toggle(game),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
