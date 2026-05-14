import 'package:flutter/material.dart';
import '../config/team_names.dart';

class TeamSelector extends StatelessWidget {
  final String? selectedTeam;
  final String? favoriteTeam;
  final ValueChanged<String?> onSelected;

  const TeamSelector({
    super.key,
    this.selectedTeam,
    this.favoriteTeam,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Select your team',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.sports_soccer),
        ),
        child: Text(
          selectedTeam ?? 'Choose a team',
          style: TextStyle(
            color: selectedTeam == null ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            final query = searchController.text.toLowerCase();
            final sorted = List<String>.from(teamNames)..sort((a, b) {
              if (a == favoriteTeam) return -1;
              if (b == favoriteTeam) return 1;
              return a.compareTo(b);
            });
            final filtered = query.isEmpty
                ? sorted
                : sorted.where((t) => t.toLowerCase().contains(query)).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search teams...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No teams found', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final team = filtered[i];
                              final isFavorite = team == favoriteTeam;
                              final isSelected = team == selectedTeam;
                              return ListTile(
                                leading: Icon(
                                  isFavorite ? Icons.star : Icons.sports_soccer,
                                  color: isFavorite ? Colors.amber : Colors.grey,
                                ),
                                title: Text(team, style: TextStyle(fontWeight: isFavorite ? FontWeight.bold : FontWeight.normal)),
                                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                                subtitle: isFavorite ? const Text('Your favorite team', style: TextStyle(fontSize: 11)) : null,
                                onTap: () {
                                  onSelected(team);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
