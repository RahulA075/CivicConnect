import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminUsersProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Invite User',
            onPressed: () => _showInviteDialog(context),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (users) => users.isEmpty
            ? const Center(child: Text('No users found.'))
            : RefreshIndicator(
                onRefresh: () async {
                  if (_municipalityId != null) {
                    ref.read(adminUsersProvider.notifier).load(_municipalityId!);
                  }
                },
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) => _UserTile(
                    user: users[i],
                    onDeactivate: () => _toggleUser(users[i], active: false),
                    onReactivate: () => _toggleUser(users[i], active: true),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _toggleUser(AdminUserEntity user, {required bool active}) async {
    final notifier = ref.read(adminUsersProvider.notifier);
    final ok = active
        ? await notifier.reactivate(user.id)
        : await notifier.deactivate(user.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'User ${active ? 'reactivated' : 'deactivated'}'
            : 'Action failed'),
      ));
    }
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    if (_municipalityId == null) return;

    final formKey   = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'FIELD_WORKER';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite User'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (ctx2, setState2) =>
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'FIELD_WORKER',    child: Text('Field Worker')),
                  DropdownMenuItem(value: 'DEPT_SUPERVISOR', child: Text('Dept Supervisor')),
                  DropdownMenuItem(value: 'MUNICIPAL_ADMIN', child: Text('Municipal Admin')),
                ],
                onChanged: (v) => setState2(() => selectedRole = v!),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final ok = await ref.read(adminUsersProvider.notifier).invite({
                'fullName': nameCtrl.text.trim(),
                'email':    emailCtrl.text.trim(),
                'role':     selectedRole,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'User invited!' : 'Failed to invite user'),
                ));
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onDeactivate,
    required this.onReactivate,
  });
  final AdminUserEntity user;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) {
      'SYSTEM_ADMIN'   => Colors.purple,
      'MUNICIPAL_ADMIN'=> Colors.blue,
      'DEPT_SUPERVISOR'=> Colors.teal,
      _                => Colors.grey,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: roleColor.withOpacity(0.15),
        child: Text(user.fullName.isNotEmpty
            ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(user.fullName),
      subtitle: Text('${user.email} · ${user.role.replaceAll('_', ' ')}'),
      trailing: Switch(
        value: user.active,
        onChanged: (v) => v ? onReactivate() : onDeactivate(),
      ),
    );
  }
}
