import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';
import '../../models/participation_model.dart';
import '../../models/match_model.dart';
import '../../models/match_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/bracket_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/check_in_service.dart';
import '../../utils/avatar_helper.dart';
import '../profile/user_profile_screen.dart';
import 'tournament_chat_screen.dart';
import 'bracket_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _vote;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, int> _counts = {};
  ParticipationModel? _existingParticipation;
  Timer? _timer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final tournamentProv = context.read<TournamentProvider>();
    if (auth.isLoggedIn) {
      _existingParticipation = await tournamentProv.getUserParticipation(
        auth.user!.uid, widget.tournament.id);
      setState(() {});
    }
    final counts = await tournamentProv.loadParticipantCounts(widget.tournament.id);
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _accept() async {
    final auth = context.read<AuthProvider>();
    final tournamentProv = context.read<TournamentProvider>();
    final walletProv = context.read<WalletProvider>();

    if (!auth.isLoggedIn) return;

    if (_existingParticipation != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already registered for this tournament!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await tournamentProv.participate(
      userId: auth.user!.uid,
      tournamentId: widget.tournament.id,
      vote: _vote ?? 'yes',
      reason: _vote == 'no' ? _reasonController.text.trim() : null,
    );

    if (!success) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already registered for this tournament!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (widget.tournament.isMoney) {
      final totalFee = widget.tournament.totalFee;
      final userBalance = walletProv.balance;
      if (userBalance >= totalFee) {
        final paid = await walletProv.payTournamentFee(auth.user!.uid, widget.tournament.id);
        if (!mounted) return;
        if (paid) {
          await tournamentProv.acceptParticipation(auth.user!.uid, widget.tournament.id, paid: true);
          setState(() {
            _isSubmitting = false;
            _existingParticipation = ParticipationModel(
              id: '',
              userId: auth.user!.uid,
              tournamentId: widget.tournament.id,
              vote: _vote ?? 'yes',
              accepted: true,
              paid: true,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paid $totalFee KES. Registered successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        context.read<TabProvider>().switchTo(1);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Need $totalFee KES. Deposit in Wallet tab (min ${WalletService.minDepositPerTransaction} KES)')),
        );
      }
    } else {
      await tournamentProv.acceptParticipation(auth.user!.uid, widget.tournament.id);
      setState(() {
        _isSubmitting = false;
        _existingParticipation = ParticipationModel(
          id: '',
          userId: auth.user!.uid,
          tournamentId: widget.tournament.id,
          vote: _vote ?? 'yes',
          accepted: true,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered for tournament!')),
      );
      Navigator.pop(context);
    }
  }

  void _shareTournament(BuildContext context) {
    final tournament = widget.tournament;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final text = '''
Join me in ${tournament.title}!
${tournament.description}
📅 ${dateFormat.format(tournament.effectiveStartTime)} ${timeFormat.format(tournament.effectiveStartTime)} - ${timeFormat.format(tournament.effectiveEndTime)}
⏰ Sign up by: ${dateFormat.format(tournament.signUpEndDate)}
${tournament.isMoney ? '💰 Entry: ${tournament.entryFee} KES' : '🎫 Free Entry'}
''';
    Share.share(text.trim(), subject: tournament.title);
  }

  Future<void> _reportResult(MatchModel match, String result) async {
    final auth = context.read<AuthProvider>();
    final bracketProv = context.read<BracketProvider>();
    if (!auth.isLoggedIn) return;

    await bracketProv.reportResult(
      tournamentId: widget.tournament.id,
      match: match,
      userId: auth.user!.uid,
      result: result,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result reported'), backgroundColor: Colors.green),
    );
  }

  Future<void> _proposeTime(MatchModel match) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final auth = context.read<AuthProvider>();
    final bracketProv = context.read<BracketProvider>();

    await bracketProv.proposeTime(
      tournamentId: widget.tournament.id,
      matchId: match.id,
      userId: auth.user!.uid,
      time: scheduled,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time proposed! Waiting for opponent to confirm.'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _confirmTime(MatchModel match) async {
    if (match.proposedTime == null) return;
    final bracketProv = context.read<BracketProvider>();

    await bracketProv.confirmTime(
      tournamentId: widget.tournament.id,
      matchId: match.id,
      time: match.proposedTime!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match time confirmed!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _cancelProposal(MatchModel match) async {
    final bracketProv = context.read<BracketProvider>();
    await bracketProv.cancelProposal(
      tournamentId: widget.tournament.id,
      matchId: match.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final canSignUp = DateTime.now().isBefore(tournament.signUpEndDate);
    final isRegistered = _existingParticipation?.accepted == true;
    final startTime = tournament.effectiveStartTime;
    final timeLeft = startTime.difference(DateTime.now());
    final isPast = timeLeft.isNegative;
    final isActive = !isPast && !canSignUp;

    final isEnded = DateTime.now().isAfter(tournament.effectiveEndTime);
    final canCheckIn = !canSignUp && !isEnded;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _shareTournament(context),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Bracket',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BracketScreen(tournament: tournament),
            )),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Players'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TournamentChatScreen(
            tournamentId: tournament.id,
            tournamentTitle: tournament.title,
          ),
        )),
        child: const Icon(Icons.chat),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(tournament, dateFormat, timeFormat, canSignUp, isRegistered, startTime, timeLeft, isPast),
          _buildPlayersTab(isActive, canCheckIn),
        ],
      ),
    );
  }

  Widget _buildInfoTab(
    TournamentModel tournament,
    DateFormat dateFormat,
    DateFormat timeFormat,
    bool canSignUp,
    bool isRegistered,
    DateTime startTime,
    Duration timeLeft,
    bool isPast,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                tournament.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Icon(Icons.sports_soccer, size: 64))),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(tournament.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (isRegistered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Registered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (tournament.description.isNotEmpty) ...[
            Text(tournament.description, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (tournament.gameName != null || tournament.platform != null) ...[
            Row(
              children: [
                if (tournament.gameName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videogame_asset, size: 16, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(tournament.gameName!, style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (tournament.platform != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.devices, size: 16, color: Colors.teal),
                        const SizedBox(width: 4),
                        Text(tournament.platform!, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _InfoRow(icon: Icons.calendar_today, label: 'Sign up deadline:', value: dateFormat.format(tournament.signUpEndDate)),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.access_time,
            label: 'Time:',
            value: '${dateFormat.format(startTime)} ${timeFormat.format(startTime)} - ${timeFormat.format(tournament.effectiveEndTime)}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: tournament.isMoney ? Icons.monetization_on : Icons.card_giftcard,
            label: 'Entry:',
            value: tournament.isMoney ? '${tournament.entryFee} KES (Fee: ${tournament.totalFee} KES)' : 'Free Entry',
          ),
          if (tournament.isMoney) ...[
            const SizedBox(height: 4),
            Text('* Service charge of ${tournament.totalFee - tournament.entryFee} KES included',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          const SizedBox(height: 16),

          if (!isPast && timeLeft.inDays <= 30)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _formatCountdown(timeLeft),
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('This tournament has ended', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          StreamBuilder<int>(
            stream: context.read<TournamentProvider>().acceptedParticipantCountStream(tournament.id),
            builder: (_, snap) {
              final registered = snap.data ?? _counts['total'] ?? 0;
              final max = tournament.maxParticipants;
              final min = tournament.minParticipants;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Participants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Text('$registered', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                              const SizedBox(height: 4),
                              Text(max != null ? 'Registered / $max' : 'Registered', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      if (tournament.isMoney) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              children: [
                                Text('${tournament.entryFee * registered} KES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                const SizedBox(height: 4),
                                const Text('Prize Pool', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (min != null && registered < min && canSignUp)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('$min participants needed to start', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                  if (max != null && registered >= max && canSignUp)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Tournament is full!', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          if (canSignUp && !isRegistered) ...[
            Text('Vote', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _VoteButton(
                  label: 'Yes',
                  icon: Icons.thumb_up,
                  selected: _vote == 'yes',
                  color: Colors.green,
                  onTap: () => setState(() => _vote = 'yes'),
                ),
                const SizedBox(width: 16),
                _VoteButton(
                  label: 'No',
                  icon: Icons.thumb_down,
                  selected: _vote == 'no',
                  color: Colors.red,
                  onTap: () => setState(() => _vote = 'no'),
                ),
              ],
            ),
            if (_vote == 'no') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for declining',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Accept Tournament', style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else if (isRegistered) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text('You are registered for this tournament', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Sign-up period has ended', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayersTab(bool isActive, bool canCheckIn) {
    final auth = context.watch<AuthProvider>();
    return Consumer<TournamentProvider>(
      builder: (_, prov, __) {
        return StreamBuilder<List<ParticipationModel>>(
          stream: prov.getParticipantsStream(widget.tournament.id),
          builder: (_, snap) {
            final participants = snap.data ?? [];
            if (participants.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No participants yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              );
            }

            final myParticipation = auth.isLoggedIn
                ? participants.where((p) => p.userId == auth.user!.uid).firstOrNull
                : null;
            final isAdmin = auth.isAdmin;

            return Consumer<BracketProvider>(
              builder: (_, bracketProv, __) {
                final matches = bracketProv.matches
                    .where((m) => m.round == 0)
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: participants.length + (isActive && matches.isNotEmpty ? matches.length : 0),
                  itemBuilder: (_, i) {
                    if (i < participants.length) {
                      return _buildPlayerCard(participants[i], myParticipation, canCheckIn, isAdmin);
                    }
                    final matchIdx = i - participants.length;
                    if (matchIdx < matches.length) {
                      return _buildMatchCard(matches[matchIdx], isActive);
                    }
                    return null;
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerCard(ParticipationModel participant, ParticipationModel? myParticipation, bool canCheckIn, bool isAdmin) {
    final isMe = myParticipation?.userId == participant.userId;
    final showCheckIn = (isMe || isAdmin) && canCheckIn;

    void doCheckIn() async {
      final service = CheckInService();
      final ok = participant.checkedIn
          ? await service.undoCheckIn(participant.userId, widget.tournament.id)
          : await service.checkIn(participant.userId, widget.tournament.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? participant.checkedIn ? 'Check-in undone' : 'Checked in successfully!'
            : 'Failed'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: context.read<TournamentProvider>().getUserProfile(participant.userId),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['fullName'] as String? ?? 'Unknown';
        final photoUrl = data?['photoUrl'] as String?;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: AvatarHelper.buildCircleAvatar(photoUrl, 20),
            title: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (participant.checkedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Checked in', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            subtitle: Text(
              participant.paid ? 'Paid' : 'Free entry',
              style: TextStyle(color: participant.paid ? Colors.green : Colors.grey, fontSize: 12),
            ),
            trailing: showCheckIn
                ? TextButton(
                    onPressed: doCheckIn,
                    child: Text(
                      participant.checkedIn ? 'Undo' : 'Check In',
                      style: TextStyle(fontWeight: FontWeight.w600, color: participant.checkedIn ? Colors.red : Colors.green),
                    ),
                  )
                : participant.checkedIn
                    ? const Icon(Icons.check_circle, size: 18, color: Colors.green)
                    : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: participant.userId),
            )),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(MatchModel match, bool isActive) {
    final auth = context.read<AuthProvider>();
    final userId = auth.user!.uid;
    final isMyMatch = userId == match.participant1Id || userId == match.participant2Id;
    final iAmProposer = match.proposedBy == userId;
    final opponentProposed = match.proposedBy != null && !iAmProposer;

    if (!match.hasBothParticipants || match.isBye) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_esports, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text('Match', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(match.participant1Id ?? 'TBD', style: const TextStyle(fontSize: 13)),
            Text('vs', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(match.participant2Id ?? 'TBD', style: const TextStyle(fontSize: 13)),

            if (match.hasScheduledTime) ...[
              const SizedBox(height: 8),
              _ScheduleCountdown(scheduledTime: match.scheduledTime!),
            ],

            if (match.completed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: match.winnerId != null ? Colors.green : Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    match.winnerId != null ? 'Winner decided' : match.reportStatus == MatchReportStatus.disputed ? 'Disputed - admin review' : 'Draw',
                    style: TextStyle(
                      fontSize: 12,
                      color: match.winnerId != null ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            if (match.scheduleStatus == 'proposed' && opponentProposed && isMyMatch && !match.completed) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opponent proposed: ${_formatScheduleTime(match.proposedTime!)}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _cancelProposal(match),
                          child: const Text('Decline', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _confirmTime(match),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Accept', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (isActive && isMyMatch && !match.completed) ...[
              const SizedBox(height: 12),

              if (match.scheduleStatus == 'none')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _proposeTime(match),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Schedule Match'),
                  ),
                ),

              if (iAmProposer && match.scheduleStatus == 'proposed')
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty, size: 16, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Waiting for opponent to confirm ${_formatScheduleTime(match.proposedTime!)}',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _cancelProposal(match),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultButton(
                    label: 'I Won',
                    icon: Icons.thumb_up,
                    color: Colors.green,
                    onTap: () => _reportResult(match, 'won'),
                  ),
                  _ResultButton(
                    label: 'I Lost',
                    icon: Icons.thumb_down,
                    color: Colors.red,
                    onTap: () => _reportResult(match, 'lost'),
                  ),
                  _ResultButton(
                    label: 'Draw',
                    icon: Icons.handshake,
                    color: Colors.orange,
                    onTap: () => _reportResult(match, 'draw'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatScheduleTime(DateTime time) {
    final format = DateFormat('MMM dd, HH:mm');
    return format.format(time);
  }

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h ${d.inMinutes.remainder(60)}m until start';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m until start';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s until start';
    return 'Starting now';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: selected ? color.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: selected ? color : Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCountdown extends StatefulWidget {
  final DateTime scheduledTime;
  const _ScheduleCountdown({required this.scheduledTime});

  @override
  State<_ScheduleCountdown> createState() => _ScheduleCountdownState();
}

class _ScheduleCountdownState extends State<_ScheduleCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.scheduledTime.difference(DateTime.now());
    final isPast = diff.isNegative;

    if (isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm, size: 14, color: Colors.red.shade700),
            const SizedBox(width: 6),
            Text('Match time passed! Play your match and report result.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    String text;
    if (diff.inDays > 0) {
      text = '${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m until match';
    } else if (diff.inHours > 0) {
      text = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m until match';
    } else if (diff.inMinutes > 0) {
      text = '${diff.inMinutes}m ${diff.inSeconds.remainder(60)}s until match';
    } else {
      text = 'Match starting now!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}
