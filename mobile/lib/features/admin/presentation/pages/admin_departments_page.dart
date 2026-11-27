import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminDepartmentsPage extends ConsumerStatefulWidget {
  const AdminDepartmentsPage({super.key});

  @override
  ConsumerState<AdminDepartmentsPage> createState() =>
      _AdminDepartmentsPageState();
}

class _AdminDepartmentsPageState extends ConsumerState<AdminDepartmentsPage> {
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminDepartmentsProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeptDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Department'),
      ),
      body: deptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (depts) => depts.isEmpty
            ? const Center(child: Text('No departments yet.'))
            : RefreshIndicator(
                onRefresh: () async {
                  if (_municipalityId != null) {
                    ref.read(adminDepartmentsProvider.notifier)
                        .load(_municipalityId!);
                  }
                },
                child: ListView.builder(
                  itemCount: depts.length,
                  itemBuilder: (_, i) => _DeptTile(
                    dept: depts[i],
                    onEdit: () => _showDeptDialog(context, dept: depts[i]),
                    onDeactivate: () => _deactivate(depts[i].id),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _deactivate(String id) async {
    final ok = await ref.read(adminDepartmentsProvider.notifier).deactivate(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Department deactivated' : 'Failed')));
    }
  }

  Future<void> _showDeptDialog(BuildContext context,
      {DepartmentEntity? dept}) async {
    if (_municipalityId == null) return;

    final formKey     = GlobalKey<FormState>();
    final nameCtrl    = TextEditingController(text: dept?.name ?? '');
    final descCtrl    = TextEditingController(text: dept?.description ?? '');
    final emailCtrl   = TextEditingController(text: dept?.contactEmail ?? '');
    final phoneCtrl   = TextEditingController(text: dept?.contactPhone ?? '');
    final colorCtrl   = TextEditingController(text: dept?.colorHex ?? '#1565C0');
    final iconCtrl    = TextEditingController(text: dept?.iconName ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dept == null ? 'New Department' : 'Edit Department'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2),
              TextFormField(controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Email')),
              TextFormField(controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone')),
              TextFormField(controller: iconCtrl,
                  decoration: const InputDecoration(labelText: 'Icon Name')),
              TextFormField(controller: colorCtrl,
                  decoration: const InputDecoration(labelText: 'Color Hex')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final data = {
                'name':         nameCtrl.text.trim(),
                'description':  descCtrl.text.trim(),
                'contactEmail': emailCtrl.text.trim(),
                'contactPhone': phoneCtrl.text.trim(),
                'iconName':     iconCtrl.text.trim(),
                'colorHex':     colorCtrl.text.trim(),
              };
              final notifier = ref.read(adminDepartmentsProvider.notifier);
              final ok = dept == null
                  ? await notifier.create(data)
                  : await notifier.update(dept.id, data);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Saved' : 'Save failed')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  const _DeptTile(
      {required this.dept, required this.onEdit, required this.onDeactivate});
  final DepartmentEntity dept;
  final VoidCallback     onEdit;
  final VoidCallback     onDeactivate;

  @override
  Widget build(BuildContext context) {
    final color = dept.colorHex != null
        ? Color(int.parse(dept.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.blue;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(Icons.business_rounded, color: color),
      ),
      title: Text(dept.name),
      subtitle: Text(dept.description ?? ''),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'deactivate') onDeactivate();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit',       child: Text('Edit')),
          PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
        ],
      ),
    );
  }
}
