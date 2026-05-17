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
    'manage_admins',
    'view_participants',
  ];

  static const Map<String, String> permissionLabels = {
    'manage_tournaments': 'Manage Tournaments',
    'manage_messages': 'Manage Announcements',
    'manage_admins': 'Manage Admins',
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
              Color roleColor;
              IconData roleIcon;
              if (admin.isSuperAdmin) {
                roleColor = Colors.amber;
                roleIcon = Icons.star;
              } else if (admin.isSubAdmin) {
                roleColor = Colors.orange;
                roleIcon = Icons.shield_outlined;
              } else {
                roleColor = Colors.blue;
                roleIcon = Icons.admin_panel_settings;
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.2),
                    child: Icon(roleIcon, color: roleColor),
                  ),
                  title: Text(admin.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.email, style: const TextStyle(fontSize: 12)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(admin.roleLabel, style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              admin.isSuperAdmin ? 'All permissions' : admin.permissions.join(', ').replaceAll('_', ' '),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      if (admin.isSubAdmin) ...[
                        if (admin.maxEntryFee != null)
                          Text('Max fee: ${admin.maxEntryFee} KES', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                        if (admin.maxDailyTournaments != null)
                          Text('Max ${admin.maxDailyTournaments} tournaments/day', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                      ],
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
    final selectedPermissions = <String>{'manage_tournaments', 'manage_messages', 'view_participants'};
    bool isSubAdmin = false;
    final maxFeeCtrl = TextEditingController();
    final maxDailyCtrl = TextEditingController();
    bool approvalRequired = false;

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
                  SwitchListTile(
                    title: const Text('Sub Admin (limited)', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Restrict permissions with limits', style: TextStyle(fontSize: 11)),
                    value: isSubAdmin,
                    onChanged: (v) => setDialogState(() => isSubAdmin = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isSubAdmin) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxFeeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max entry fee (KES)',
                        prefixIcon: Icon(Icons.money_off, size: 20),
                        hintText: 'Leave empty for no limit',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxDailyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max tournaments per day',
                        prefixIcon: Icon(Icons.calendar_today, size: 20),
                        hintText: 'e.g. 3',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Require approval for announcements', style: TextStyle(fontSize: 13)),
                      value: approvalRequired,
                      onChanged: (v) => setDialogState(() => approvalRequired = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  const SizedBox(height: 8),
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
                  if (!isSubAdmin) ...[
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
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                child: Text(isSubAdmin ? 'Make Sub Admin' : 'Make Admin'),
                onPressed: () async {
                  if (selectedUsers.isEmpty) return;
                  if (!isSubAdmin && selectedPermissions.isEmpty) return;

                  final role = isSubAdmin ? UserRole.subAdmin : UserRole.admin;
                  final perms = isSubAdmin
                      ? ['manage_tournaments', 'manage_messages', 'view_participants']
                      : selectedPermissions.toList();
                  final maxFee = int.tryParse(maxFeeCtrl.text.trim());
                  final maxDaily = int.tryParse(maxDailyCtrl.text.trim());

                  for (final uid in selectedUsers) {
                    await context.read<AuthProvider>().updateUserRole(
                      uid,
                      role,
                      perms,
                      maxEntryFee: maxFee,
                      maxDailyTournaments: maxDaily,
                      approvalRequired: approvalRequired,
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
