import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../models/user_model.dart';
import '../../models/user_tier.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/game_selector.dart';

class AdminTournaments extends StatelessWidget {
  const AdminTournaments({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSubAdmin = auth.isSubAdmin;
    final userId = auth.user!.uid;

    Query query = FirebaseFirestore.instance.collection('tournaments').orderBy('createdAt', descending: true);
    if (isSubAdmin) {
      query = query.where('createdBy', isEqualTo: userId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tournaments'),
        actions: isSubAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'My Limits',
                  onPressed: () => _showLimits(context, auth.user!),
                ),
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context, auth),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tournaments = snap.data!.docs;
          if (tournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSubAdmin ? Icons.lock_outline : Icons.sports_soccer, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    isSubAdmin ? 'You haven\'t created any tournaments yet' : 'No tournaments yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
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
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, auth, tournament: t)),
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

  void _showLimits(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Admin Limits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.maxEntryFee != null)
              _LimitRow(icon: Icons.money_off, label: 'Max entry fee', value: '${user.maxEntryFee} KES'),
            if (user.maxDailyTournaments != null)
              _LimitRow(icon: Icons.calendar_today, label: 'Max tournaments/day', value: '${user.maxDailyTournaments}'),
            if (user.approvalRequired)
              _LimitRow(icon: Icons.approval, label: 'Announcements', value: 'Need approval'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _LimitRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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

  Future<bool> _checkDailyLimit(BuildContext context, AuthProvider auth) async {
    final user = auth.user!;
    if (user.maxDailyTournaments == null) return true;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('tournaments')
        .where('createdBy', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: endOfDay)
        .get();

    if (snap.docs.length >= user.maxDailyTournaments!) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily limit reached (${user.maxDailyTournaments} tournaments). Wait until tomorrow.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _showForm(BuildContext context, AuthProvider auth, {TournamentModel? tournament}) {
    final isEdit = tournament != null;
    final user = auth.user!;
    final isSubAdmin = auth.isSubAdmin;
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
    String minTier = tournament?.minTier ?? 'bronze';
    final firstPrizeCtrl = TextEditingController(text: tournament?.prizeDistribution[1]?.toString() ?? '100');
    final secondPrizeCtrl = TextEditingController(text: tournament?.prizeDistribution[2]?.toString() ?? '');
    final thirdPrizeCtrl = TextEditingController(text: tournament?.prizeDistribution[3]?.toString() ?? '');

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
                if (isSubAdmin && user.maxEntryFee != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Max entry fee: ${user.maxEntryFee} KES', style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: minTier,
                  decoration: const InputDecoration(
                    labelText: 'Required Tier',
                    prefixIcon: Icon(Icons.stairs, size: 20),
                  ),
                  items: UserTier.values.map((t) => DropdownMenuItem(
                    value: t.name,
                    child: Text('${t.iconPath} ${t.label}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => minTier = v!),
                ),
                const SizedBox(height: 12),
                const Text('Prize Distribution (%)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstPrizeCtrl,
                        decoration: const InputDecoration(labelText: '1st', prefixIcon: Icon(Icons.emoji_events, size: 20)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: secondPrizeCtrl,
                        decoration: const InputDecoration(labelText: '2nd', prefixIcon: Icon(Icons.looks_two, size: 20)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: thirdPrizeCtrl,
                        decoration: const InputDecoration(labelText: '3rd', prefixIcon: Icon(Icons.looks_3, size: 20)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text(isEdit ? 'Update' : 'Create'),
                    onPressed: () async {
                      final fee = int.tryParse(feeCtrl.text.trim()) ?? 0;

                      if (isSubAdmin && !isEdit) {
                        final ok = await _checkDailyLimit(context, auth);
                        if (!ok) return;
                      }

                      if (isSubAdmin && isMoney && user.maxEntryFee != null && fee > user.maxEntryFee!) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Entry fee exceeds your limit of ${user.maxEntryFee} KES'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final minP = int.tryParse(minCtrl.text.trim());
                      final maxP = int.tryParse(maxCtrl.text.trim());
                      final prizeMap = <int, int>{};
                      final f = int.tryParse(firstPrizeCtrl.text.trim());
                      if (f != null && f > 0) prizeMap[1] = f;
                      final s = int.tryParse(secondPrizeCtrl.text.trim());
                      if (s != null && s > 0) prizeMap[2] = s;
                      final t = int.tryParse(thirdPrizeCtrl.text.trim());
                      if (t != null && t > 0) prizeMap[3] = t;
                      if (prizeMap.isEmpty) prizeMap[1] = 100;
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'signUpEndDate': signUpEnd,
                        'hostDate': startTime,
                        'entryType': isMoney ? 'money' : 'free',
                        'entryFee': isMoney ? fee : 0,
                        'startTime': startTime,
                        'endTime': endTime,
                        'gameCategory': gameCategory,
                        'gameName': gameName,
                        'platform': platform,
                        'minParticipants': minP,
                        'maxParticipants': maxP,
                        'minTier': minTier,
                        'prizeDistribution': prizeMap,
                        'createdBy': isSubAdmin ? user.uid : 'admin',
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
