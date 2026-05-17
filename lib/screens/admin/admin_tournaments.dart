import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/tournament_model.dart';
import '../../models/tournament_template.dart';
import '../../models/user_model.dart';
import '../../models/user_tier.dart';
import '../../providers/auth_provider.dart';
import '../../services/template_service.dart';
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
      try {
        await FirebaseFirestore.instance.collection('tournaments').doc(id).delete();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
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
    TournamentFormat format = tournament?.format ?? TournamentFormat.singleElimination;
    int groupCount = tournament?.groupCount ?? 4;
    int advancePerGroup = tournament?.advancePerGroup ?? 2;
    bool autoGenerate = tournament?.autoGenerateBracket ?? false;
    String? templateId = tournament?.templateId;
    final passcodeCtrl = TextEditingController(text: tournament?.passcode ?? '');
    bool showTemplateOptions = !isEdit;

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
                DropdownButtonFormField<TournamentFormat>(
                  value: format,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Format',
                    prefixIcon: Icon(Icons.account_tree, size: 20),
                  ),
                  items: TournamentFormat.values.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(_formatLabel(f)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => format = v!),
                ),
                if (format == TournamentFormat.groupStagePlayoffs) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Number of Groups', prefixIcon: Icon(Icons.grid_view, size: 20)),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: groupCount.toString()),
                    onChanged: (v) => groupCount = int.tryParse(v) ?? 4,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Advance per Group', prefixIcon: Icon(Icons.arrow_forward, size: 20)),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: advancePerGroup.toString()),
                    onChanged: (v) => advancePerGroup = int.tryParse(v) ?? 2,
                  ),
                ],
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Auto-generate bracket when full'),
                  subtitle: Text(format == TournamentFormat.groupStagePlayoffs
                      ? 'Generates group stage + playoff bracket automatically'
                      : 'Bracket generates as soon as min participants join'),
                  value: autoGenerate,
                  onChanged: (v) => setDialogState(() => autoGenerate = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (showTemplateOptions) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_copy_outlined, size: 18),
                          label: const Text('Load Template'),
                          onPressed: () => _loadTemplate(context, ctx, setDialogState, (t) {
                            titleCtrl.text = t.name;
                            descCtrl.text = t.description ?? descCtrl.text;
                            gameCategory = t.gameCategory;
                            gameName = t.gameName;
                            platform = t.platform;
                            isMoney = t.entryType == EntryType.money;
                            if (t.entryFee > 0) feeCtrl.text = t.entryFee.toString();
                            minCtrl.text = t.minParticipants?.toString() ?? '';
                            maxCtrl.text = t.maxParticipants?.toString() ?? '';
                            minTier = t.minTier;
                            firstPrizeCtrl.text = t.prizeDistribution[1]?.toString() ?? '100';
                            secondPrizeCtrl.text = t.prizeDistribution[2]?.toString() ?? '';
                            thirdPrizeCtrl.text = t.prizeDistribution[3]?.toString() ?? '';
                            format = t.format;
                            groupCount = t.groupCount;
                            advancePerGroup = t.advancePerGroup;
                            autoGenerate = t.autoGenerateBracket;
                            templateId = t.id;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save as Template'),
                          onPressed: () => _saveAsTemplate(context, ctx, setDialogState, titleCtrl, descCtrl, gameCategory, gameName, platform, isMoney, feeCtrl, minCtrl, maxCtrl, minTier, firstPrizeCtrl, secondPrizeCtrl, thirdPrizeCtrl, format, groupCount, advancePerGroup, autoGenerate, user.uid),
                        ),
                      ),
                    ],
                  ),
                ],
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
                TextField(
                  controller: passcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Passcode (6 digits, optional)',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    hintText: 'Leave empty for public',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
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
                        'prizeDistribution': prizeMap.map((k, v) => MapEntry(k.toString(), v)),
                        'format': format.name,
                        'groupCount': format == TournamentFormat.groupStagePlayoffs ? groupCount : 0,
                        'advancePerGroup': format == TournamentFormat.groupStagePlayoffs ? advancePerGroup : 0,
                        'autoGenerateBracket': autoGenerate,
                        'templateId': templateId,
                        'passcode': passcodeCtrl.text.trim().length == 6 ? passcodeCtrl.text.trim() : null,
                        'createdBy': isSubAdmin ? user.uid : 'admin',
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      try {
                        if (isEdit) {
                          await FirebaseFirestore.instance.collection('tournaments').doc(tournament.id).update(data);
                        } else {
                          await FirebaseFirestore.instance.collection('tournaments').add(data);
                        }
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                        );
                        return;
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

  String _formatLabel(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.singleElimination: return 'Single Elimination';
      case TournamentFormat.groupStagePlayoffs: return 'Group Stage → Playoffs';
      case TournamentFormat.doubleElimination: return 'Double Elimination';
    }
  }

  void _loadTemplate(BuildContext context, BuildContext dialogContext, StateSetter setDialogState, void Function(TournamentTemplate) onLoad) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tournament_templates').orderBy('createdAt', descending: true).snapshots(),
            builder: (_, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final templates = snap.data!.docs;
              if (templates.isEmpty) return const Center(child: Text('No templates saved yet'));
              final items = <TournamentTemplate>[];
              for (final doc in templates) {
                try {
                  items.add(TournamentTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id));
                } catch (_) {}
              }
              if (items.isEmpty) return const Center(child: Text('No templates saved yet'));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final t = items[i];
                  return ListTile(
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.entryTypeLabel} • ${t.formatLabel}'),
                    trailing: const Icon(Icons.check_circle_outline),
                    onTap: () {
                      onLoad(t);
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _saveAsTemplate(
    BuildContext context,
    BuildContext dialogContext,
    StateSetter setDialogState,
    TextEditingController titleCtrl,
    TextEditingController descCtrl,
    String? gameCategory,
    String? gameName,
    String? platform,
    bool isMoney,
    TextEditingController feeCtrl,
    TextEditingController minCtrl,
    TextEditingController maxCtrl,
    String minTier,
    TextEditingController firstPrizeCtrl,
    TextEditingController secondPrizeCtrl,
    TextEditingController thirdPrizeCtrl,
    TournamentFormat format,
    int groupCount,
    int advancePerGroup,
    bool autoGenerate,
    String userId,
  ) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Template Name', hintText: 'e.g. Weekly FIFA Cup'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
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
              final service = TemplateService();
              await service.saveTemplate(TournamentTemplate(
                id: '',
                name: name,
                description: descCtrl.text.trim(),
                gameCategory: gameCategory,
                gameName: gameName,
                platform: platform,
                entryType: isMoney ? EntryType.money : EntryType.free,
                entryFee: isMoney ? (int.tryParse(feeCtrl.text.trim()) ?? 0) : 0,
                minParticipants: minP,
                maxParticipants: maxP,
                minTier: minTier,
                prizeDistribution: prizeMap,
                format: format,
                groupCount: groupCount,
                advancePerGroup: advancePerGroup,
                autoGenerateBracket: autoGenerate,
                createdBy: userId,
              ));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template saved!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

