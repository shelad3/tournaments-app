import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/place_model.dart';

class AdminPlaces extends StatelessWidget {
  const AdminPlaces({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Game Places')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('places').orderBy('name').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No places added yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add game venues where tournaments are held', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final p = PlaceModel.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.location, style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showForm(context, place: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(context, docs[i].id, p.name),
                      ),
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

  void _delete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Delete "$name"? Users associated with this place will lose the connection.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('places').doc(id).delete();
    }
  }

  void _showForm(BuildContext context, {PlaceModel? place}) {
    final isEdit = place != null;
    final nameCtrl = TextEditingController(text: place?.name ?? '');
    final locCtrl = TextEditingController(text: place?.location ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Place' : 'Add Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Place Name', hintText: 'e.g. Nairobi School'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Nairobi, Kenya'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final loc = locCtrl.text.trim();
              if (name.isEmpty || loc.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Fill in all fields'), backgroundColor: Colors.red),
                );
                return;
              }
              final data = {
                'name': name,
                'location': loc,
                'createdAt': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await FirebaseFirestore.instance.collection('places').doc(place.id).update(data);
              } else {
                await FirebaseFirestore.instance.collection('places').add(data);
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
