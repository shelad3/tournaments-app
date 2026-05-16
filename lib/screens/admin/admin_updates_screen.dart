import 'package:flutter/material.dart';
import '../../services/update_service.dart';

class AdminUpdatesScreen extends StatefulWidget {
  const AdminUpdatesScreen({super.key});

  @override
  State<AdminUpdatesScreen> createState() => _AdminUpdatesScreenState();
}

class _AdminUpdatesScreenState extends State<AdminUpdatesScreen> {
  final _service = UpdateService();
  UpdateInfo? _updateInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await _service.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateInfo = info;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Updates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _updateInfo == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('App is up to date', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.system_update, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text('v${_updateInfo!.latestVersion} available',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade800)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Build ${_updateInfo!.latestBuildNumber}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('General Changelog', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildChangelog(_updateInfo!.changelog),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Admin-sensitive changes below — not visible to regular users',
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Admin Changelog', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 8),
                    _buildChangelog(_updateInfo!.adminChangelog),
                  ],
                ),
    );
  }

  Widget _buildChangelog(String text) {
    if (text.isEmpty) {
      return const Text('No details', style: TextStyle(color: Colors.grey));
    }
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(' • ', style: TextStyle(color: Colors.grey.shade500)),
            Expanded(child: Text(line, style: const TextStyle(fontSize: 14, height: 1.4))),
          ],
        ),
      )).toList(),
    );
  }
}
