import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminManageAdmins extends StatefulWidget {
  const AdminManageAdmins({super.key});

  @override
  State<AdminManageAdmins> createState() => _AdminManageAdminsState();
}

class _AdminManageAdminsState extends State<AdminManageAdmins> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().loadAllUsers();
  }

  static const List<String> allPermissions = [
    'manage_tournaments',
    'manage_messages',
    'view_participants',
  ];

  static const Map<String, String> permissionLabels = {
    'manage_tournaments': 'Manage Tournaments',
    'manage_messages': 'Manage Announcements',
    'view_participants': 'View Participants',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () => _addAdmin(context),
      ),
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          final admins = auth.allUsers.where((u) => u.isAdmin).toList();
          if (admins.isEmpty) {
            return const Center(child: Text('No admins yet', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            itemBuilder: (_, i) {
              final admin = admins[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: admin.isSuperAdmin ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                    child: Icon(admin.isSuperAdmin ? Icons.star : Icons.admin_panel_settings,
                        color: admin.isSuperAdmin ? Colors.amber : Colors.blue),
                  ),
                  title: Text(admin.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.email, style: const TextStyle(fontSize: 12)),
                      Text(admin.isSuperAdmin ? 'Super Admin' : admin.permissions.join(', ').replaceAll('_', ' '),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  trailing: admin.isSuperAdmin
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeAdmin(context, admin),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addAdmin(BuildContext context) {
    final searchCtrl = TextEditingController();
    final selectedUsers = <String>{};
    final selectedPermissions = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) {
          final allUsers = context.read<AuthProvider>().allUsers;
          final query = searchCtrl.text.toLowerCase();
          final filtered = query.isEmpty
              ? allUsers
              : allUsers.where((u) =>
                  u.fullName.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query) ||
                  u.username.toLowerCase().contains(query)).toList();

          return AlertDialog(
            title: const Text('Add Admin'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text('Select users:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                        : ListView(
                            children: filtered.map((u) => CheckboxListTile(
                              title: Text(u.fullName, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('${u.email} • @${u.username}', style: const TextStyle(fontSize: 11)),
                              value: selectedUsers.contains(u.uid),
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) {
                                    selectedUsers.add(u.uid);
                                  } else {
                                    selectedUsers.remove(u.uid);
                                  }
                                });
                              },
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            )).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...allPermissions.map((perm) => CheckboxListTile(
                    title: Text(permissionLabels[perm] ?? perm, style: const TextStyle(fontSize: 14)),
                    value: selectedPermissions.contains(perm),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) {
                          selectedPermissions.add(perm);
                        } else {
                          selectedPermissions.remove(perm);
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                child: const Text('Make Admin'),
                onPressed: () async {
                  if (selectedUsers.isEmpty || selectedPermissions.isEmpty) return;
                  for (final uid in selectedUsers) {
                    await context.read<AuthProvider>().updateUserRole(
                      uid,
                      UserRole.admin,
                      selectedPermissions.toList(),
                    );
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeAdmin(BuildContext context, UserModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Remove admin privileges from ${admin.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AuthProvider>().updateUserRole(admin.uid, UserRole.user, []);
    }
  }
}
