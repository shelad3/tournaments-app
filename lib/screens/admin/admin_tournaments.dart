import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../widgets/game_selector.dart';

class AdminTournaments extends StatelessWidget {
  const AdminTournaments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tournaments')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').orderBy('createdAt', descending: true).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tournaments = snap.data!.docs;
          if (tournaments.isEmpty) {
            return const Center(child: Text('No tournaments yet', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (_, i) {
              final t = TournamentModel.fromMap(tournaments[i].data() as Map<String, dynamic>, tournaments[i].id);
              final dateFormat = DateFormat('MMM dd, HH:mm');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${t.gameName ?? 'No game'} • ${t.platform ?? 'Any'}\n${dateFormat.format(t.effectiveStartTime)} - ${dateFormat.format(t.effectiveEndTime)} • ${t.isMoney ? '${t.entryFee} KES' : 'Free'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, tournament: t)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(context, tournaments[i].id, t.title)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _delete(BuildContext context, String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('tournaments').doc(id).delete();
    }
  }

  void _showForm(BuildContext context, {TournamentModel? tournament}) {
    final isEdit = tournament != null;
    final titleCtrl = TextEditingController(text: tournament?.title ?? '');
    final descCtrl = TextEditingController(text: tournament?.description ?? '');
    final feeCtrl = TextEditingController(text: tournament?.entryFee.toString() ?? '');
    DateTime signUpEnd = tournament?.signUpEndDate ?? DateTime.now().add(const Duration(days: 7));
    DateTime startTime = tournament?.startTime ?? (tournament?.hostDate ?? DateTime.now().add(const Duration(days: 14)));
    DateTime endTime = tournament?.endTime ?? startTime.add(const Duration(hours: 4));
    bool isMoney = tournament?.isMoney ?? false;
    String? gameCategory = tournament?.gameCategory;
    String? gameName = tournament?.gameName;
    String? platform = tournament?.platform;
    final minCtrl = TextEditingController(text: tournament?.minParticipants?.toString() ?? '');
    final maxCtrl = TextEditingController(text: tournament?.maxParticipants?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Edit Tournament' : 'New Tournament', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                GameSelector(
                  selectedCategory: gameCategory,
                  selectedGame: gameName,
                  selectedPlatform: platform,
                  onCategoryChanged: (v) => setDialogState(() {
                    gameCategory = v;
                    gameName = null;
                  }),
                  onGameChanged: (v) => setDialogState(() => gameName = v),
                  onPlatformChanged: (v) => setDialogState(() => platform = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text('Sign-up end: ${DateFormat('MMM dd').format(signUpEnd)}'),
                        onPressed: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: signUpEnd, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (picked != null) setDialogState(() => signUpEnd = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text('Start: ${DateFormat('MMM dd HH:mm').format(startTime)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: ctx, initialDate: startTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date == null) return;
                          if (!ctx.mounted) return;
                          final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(startTime));
                          if (time != null) setDialogState(() => startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: Text('End: ${DateFormat('MMM dd HH:mm').format(endTime)}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: ctx, initialDate: endTime, firstDate: startTime, lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date == null) return;
                          if (!ctx.mounted) return;
                          final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(endTime));
                          if (time != null) setDialogState(() => endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Paid Tournament'),
                  value: isMoney,
                  onChanged: (v) => setDialogState(() => isMoney = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isMoney) ...[
                  const SizedBox(height: 8),
                  TextField(controller: feeCtrl, decoration: const InputDecoration(labelText: 'Entry Fee (KES)'), keyboardType: TextInputType.number),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: minCtrl,
                  decoration: const InputDecoration(labelText: 'Min Participants (optional)', prefixIcon: Icon(Icons.person_outline, size: 20)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(labelText: 'Max Participants (optional)', prefixIcon: Icon(Icons.people_outline, size: 20)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text(isEdit ? 'Update' : 'Create'),
                    onPressed: () async {
                      final minP = int.tryParse(minCtrl.text.trim());
                      final maxP = int.tryParse(maxCtrl.text.trim());
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'signUpEndDate': signUpEnd,
                        'hostDate': startTime,
                        'entryType': isMoney ? 'money' : 'free',
                        'entryFee': isMoney ? int.tryParse(feeCtrl.text.trim()) ?? 0 : 0,
                        'startTime': startTime,
                        'endTime': endTime,
                        'gameCategory': gameCategory,
                        'gameName': gameName,
                        'platform': platform,
                        'minParticipants': minP,
                        'maxParticipants': maxP,
                        'createdBy': 'admin',
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      if (isEdit) {
                        await FirebaseFirestore.instance.collection('tournaments').doc(tournament.id).update(data);
                      } else {
                        await FirebaseFirestore.instance.collection('tournaments').add(data);
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
