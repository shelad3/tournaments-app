import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _service = UpdateService();
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _error = null;
    });

    final path = await _service.downloadApk(
      widget.updateInfo.apkUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (path == null) {
      if (mounted) setState(() {
        _error = 'Download failed';
        _downloading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _downloading = false);
      final installed = await _service.installApk(path);
      if (installed) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Update Available'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.updateInfo.latestVersion} is available',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (widget.updateInfo.changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                widget.updateInfo.changelog,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () {
            _service.markBuildDismissed(widget.updateInfo.latestBuildNumber);
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        if (!_downloading)
          ElevatedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now'),
          ),
      ],
    );
  }
}
