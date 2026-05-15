import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';

class AdminMessages extends StatefulWidget {
  const AdminMessages({super.key});

  @override
  State<AdminMessages> createState() => _AdminMessagesState();
}

class _AdminMessagesState extends State<AdminMessages> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuperAdmin = auth.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        bottom: isSuperAdmin
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending Approval'),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      ),
      body: isSuperAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _MessagesList(showPending: false),
                _MessagesList(showPending: true),
              ],
            )
          : const _MessagesList(showPending: false),
    );
  }

  void _showForm(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isSubAdmin = auth.isSubAdmin;
    final needsApproval = auth.user?.approvalRequired ?? false;

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    MessagePriority priority = MessagePriority.normal;

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
                Text('New Announcement', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (needsApproval)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('This will be submitted for approval', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 5),
                const SizedBox(height: 12),
                DropdownButtonFormField<MessagePriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: MessagePriority.normal, child: Text('Normal')),
                    DropdownMenuItem(value: MessagePriority.important, child: Text('Important')),
                    DropdownMenuItem(value: MessagePriority.urgent, child: Text('Urgent')),
                  ],
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text(needsApproval ? 'Submit for Approval' : 'Create'),
                    onPressed: () async {
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'body': bodyCtrl.text.trim(),
                        'priority': priority.name,
                        'createdBy': isSubAdmin ? auth.user!.uid : 'admin',
                        'status': needsApproval ? 'pending' : 'approved',
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      await FirebaseFirestore.instance.collection('messages').add(data);
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

class _MessagesList extends StatelessWidget {
  final bool showPending;
  const _MessagesList({required this.showPending});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSubAdmin = auth.isSubAdmin;
    final userId = auth.user!.uid;

    Query query = FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true);

    if (showPending) {
      query = query.where('status', isEqualTo: 'pending');
    } else if (isSubAdmin) {
      query = query.where('createdBy', isEqualTo: userId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final msgs = snap.data!.docs;
        if (msgs.isEmpty) {
          return EmptyState(
            icon: showPending ? Icons.approval : Icons.message,
            title: showPending ? 'No pending approvals' : 'No announcements',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final m = MessageModel.fromMap(msgs[i].data() as Map<String, dynamic>, msgs[i].id);
            final data = msgs[i].data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'approved';
            final isPending = status == 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange : m.priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                subtitle: Text('${m.priorityLabel} • ${DateFormat('MMM dd').format(m.createdAt)}', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending && auth.isSuperAdmin)
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _approve(context, msgs[i].id),
                      ),
                    if (!isPending || auth.isSuperAdmin)
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(context, msgs[i].id, m.title)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _delete(BuildContext context, String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('messages').doc(id).delete();
    }
  }

  void _approve(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('messages').doc(id).update({
      'status': 'approved',
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement approved'), backgroundColor: Colors.green),
    );
  }
}
