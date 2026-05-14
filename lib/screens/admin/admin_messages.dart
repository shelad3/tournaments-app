import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';

class AdminMessages extends StatelessWidget {
  const AdminMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final msgs = snap.data!.docs;
          if (msgs.isEmpty) {
            return const Center(child: Text('No announcements', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = MessageModel.fromMap(msgs[i].data() as Map<String, dynamic>, msgs[i].id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: m.priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m.priorityLabel} • ${DateFormat('MMM dd').format(m.createdAt)}', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, message: m)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(context, msgs[i].id, m.title)),
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

  void _showForm(BuildContext context, {MessageModel? message}) {
    final isEdit = message != null;
    final titleCtrl = TextEditingController(text: message?.title ?? '');
    final bodyCtrl = TextEditingController(text: message?.body ?? '');
    MessagePriority priority = message?.priority ?? MessagePriority.normal;

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
                Text(isEdit ? 'Edit Announcement' : 'New Announcement', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    child: Text(isEdit ? 'Update' : 'Create'),
                    onPressed: () async {
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'body': bodyCtrl.text.trim(),
                        'priority': priority.name,
                        'createdBy': 'admin',
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      if (isEdit) {
                        await FirebaseFirestore.instance.collection('messages').doc(message.id).update(data);
                      } else {
                        await FirebaseFirestore.instance.collection('messages').add(data);
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
