import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tournament_model.dart';

class ResultCard extends StatefulWidget {
  final TournamentModel tournament;
  final String? winnerName;
  final String? winnerPhotoUrl;
  final String prize;

  const ResultCard({
    super.key,
    required this.tournament,
    this.winnerName,
    this.winnerPhotoUrl,
    this.prize = '',
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _capturing = false;

  Future<void> _captureAndShare() async {
    setState(() => _capturing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tournament_result.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '${widget.tournament.title} Results',
          text: 'Check out the ${widget.tournament.title} tournament results!',
        ),
      );
    } catch (_) {}
    setState(() => _capturing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: _buildCard(dateFormat),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _capturing ? null : _captureAndShare,
            icon: _capturing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share),
            label: Text(_capturing ? 'Generating...' : 'Share as Image'),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DateFormat dateFormat) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text('TOURNAMENT RESULTS',
                  style: TextStyle(color: Colors.amber.shade300, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 20),
          Text(widget.tournament.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          if (widget.tournament.gameName != null) ...[
            const SizedBox(height: 6),
            Text(widget.tournament.gameName!,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                const SizedBox(height: 8),
                Text('Winner',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(widget.winnerName ?? 'TBD',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (widget.prize.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.prize,
                      style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoChip(Icons.calendar_today, dateFormat.format(widget.tournament.hostDate)),
              if (widget.tournament.platform != null)
                _infoChip(Icons.devices, widget.tournament.platform!),
              _infoChip(Icons.people, '${widget.tournament.formatLabel}'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videogame_asset, size: 16, color: Colors.blue.shade300),
                const SizedBox(width: 6),
                Text('NativeCodeX',
                    style: TextStyle(color: Colors.blue.shade300, fontSize: 12, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }
}
