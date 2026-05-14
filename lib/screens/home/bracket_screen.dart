import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bracket_provider.dart';
import '../../providers/tournament_provider.dart';

class BracketScreen extends StatefulWidget {
  final TournamentModel tournament;

  const BracketScreen({super.key, required this.tournament});

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  @override
  void initState() {
    super.initState();
    final bp = context.read<BracketProvider>();
    bp.loadMatches(widget.tournament.id);
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final auth = context.watch<AuthProvider>();
    final bp = context.watch<BracketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${tournament.title} Bracket'),
        actions: [
          if (auth.user?.isAdmin == true && !bp.hasBracket())
            TextButton.icon(
              onPressed: bp.isLoading ? null : () => _generateBracket(context),
              icon: const Icon(Icons.auto_graph),
              label: const Text('Generate'),
            ),
        ],
      ),
      body: bp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !bp.hasBracket()
              ? _emptyBracket(context, auth)
              : _buildBracket(context, bp, auth),
    );
  }

  Widget _emptyBracket(BuildContext context, AuthProvider auth) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          ),
          const SizedBox(height: 20),
          Text('No bracket generated yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Admin can generate from paid participants',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 20),
          if (auth.user?.isAdmin == true)
            ElevatedButton.icon(
              onPressed: () => _generateBracket(context),
              icon: const Icon(Icons.auto_graph),
              label: const Text('Generate Bracket'),
            ),
        ],
      ),
    );
  }

  Future<void> _generateBracket(BuildContext context) async {
    final tournamentProv = context.read<TournamentProvider>();
    final bp = context.read<BracketProvider>();
    final participants = await tournamentProv.getTournamentParticipants(widget.tournament.id);
    if (participants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants to generate bracket from')),
      );
      return;
    }
    await bp.generateBracket(widget.tournament.id, participants);
  }

  Widget _buildBracket(BuildContext context, BracketProvider bp, AuthProvider auth) {
    final rounds = bp.rounds;
    if (rounds.isEmpty) {
      return const Center(child: Text('No matches'));
    }

    const matchHeight = 80.0;
    const matchSpacing = 8.0;
    const roundWidth = 190.0;

    double totalHeight = matchHeight * (1 << (rounds.length - 1)) +
        matchSpacing * ((1 << (rounds.length - 1)) + 1) + 40;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: roundWidth * rounds.length,
        child: SingleChildScrollView(
          child: SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rounds.asMap().entries.map((entry) {
                final roundIdx = entry.key;
                final roundMatches = entry.value;
                final spacing = matchHeight * (1 << roundIdx);

                return SizedBox(
                  width: roundWidth,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _roundColors(roundIdx, rounds.length),
                          ),
                        ),
                        child: Text(
                          _roundLabel(roundIdx, rounds.length),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...roundMatches.asMap().entries.map((me) {
                        final match = me.value;
                        final topPadding = me.key * spacing + (spacing - matchHeight) / 2;
                        return Padding(
                          padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 4),
                          child: _MatchCard(
                            match: match,
                            isAdmin: auth.user?.isAdmin == true,
                            onSetWinner: (winnerId, winnerTeam) {
                              bp.setWinner(
                                  widget.tournament.id, match.id, winnerId, winnerTeam);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _roundColors(int round, int totalRounds) {
    if (round == totalRounds - 1) return [Colors.amber.shade700, Colors.amber.shade800];
    return [Colors.indigo.shade600, Colors.indigo.shade800];
  }

  String _roundLabel(int round, int totalRounds) {
    if (round == totalRounds - 1) return '🏆 Final';
    if (round == totalRounds - 2) return 'Semi-Finals';
    if (round == totalRounds - 3) return 'Quarter-Finals';
    return 'Round ${round + 1}';
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool isAdmin;
  final void Function(String winnerId, String winnerTeam) onSetWinner;

  const _MatchCard({
    required this.match,
    required this.isAdmin,
    required this.onSetWinner,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAdmin && match.participant1Id != null && !match.completed
          ? () => _showWinnerDialog(context)
          : null,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: match.completed ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: match.completed ? Colors.green : Colors.grey.shade300,
            width: match.completed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ParticipantRow(
              teamName: match.participant1Team,
              isWinner: match.winnerId == match.participant1Id,
              isBye: match.participant2Id == null,
            ),
            if (match.hasBothParticipants)
              Container(height: 1, color: Colors.grey.shade200),
            if (match.participant2Id != null)
              _ParticipantRow(
                teamName: match.participant2Team,
                isWinner: match.winnerId == match.participant2Id,
                isBye: false,
              ),
            if (!match.hasBothParticipants && match.participant1Id == null)
              const Expanded(
                child: Center(
                  child: Text('TBD', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWinnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Winner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.participant1Team != null)
              ListTile(
                title: Text(match.participant1Team!),
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                onTap: () {
                  onSetWinner(match.participant1Id!, match.participant1Team!);
                  Navigator.pop(ctx);
                },
              ),
            if (match.participant2Id != null && match.participant2Team != null)
              ListTile(
                title: Text(match.participant2Team!),
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                onTap: () {
                  onSetWinner(match.participant2Id!, match.participant2Team!);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final String? teamName;
  final bool isWinner;
  final bool isBye;

  const _ParticipantRow({
    this.teamName,
    required this.isWinner,
    required this.isBye,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isWinner ? Colors.green.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (isWinner)
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Text(
                teamName ?? 'BYE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                  color: teamName == null
                      ? Colors.orange
                      : isWinner
                          ? Colors.green.shade800
                          : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWinner)
              const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
            if (teamName == null)
              const Icon(Icons.arrow_forward, size: 14, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}
