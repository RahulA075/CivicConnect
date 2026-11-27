import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminCategoriesPage extends ConsumerStatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  ConsumerState<AdminCategoriesPage> createState() =>
      _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends ConsumerState<AdminCategoriesPage> {
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminCategoriesProvider.notifier).load(_municipalityId!);
          ref.read(adminDepartmentsProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync  = ref.watch(adminCategoriesProvider);
    final deptsAsync = ref.watch(adminDepartmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCatDialog(context,
            depts: deptsAsync.value ?? []),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (cats) => cats.isEmpty
            ? const Center(child: Text('No categories yet.'))
            : ListView.builder(
                itemCount: cats.length,
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.category_rounded, color: Colors.blue),
                  ),
                  title: Text(cats[i].name),
                  subtitle: Text(cats[i].departmentName ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _showCatDialog(context,
                        cat: cats[i],
                        depts: deptsAsync.value ?? []),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _showCatDialog(BuildContext context,
      {CategoryEntity? cat, required List<DepartmentEntity> depts}) async {
    if (_municipalityId == null || depts.isEmpty) return;

    final formKey  = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    final descCtrl = TextEditingController(text: cat?.description ?? '');
    final iconCtrl = TextEditingController(text: cat?.iconName ?? '');
    String selectedDept = cat?.departmentId ?? depts.first.id;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cat == null ? 'New Category' : 'Edit Category'),
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
              TextFormField(controller: iconCtrl,
                  decoration: const InputDecoration(labelText: 'Icon Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (ctx2, ss) =>
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  decoration: const InputDecoration(labelText: 'Department *'),
                  items: depts.map((d) => DropdownMenuItem(
                      value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) => ss(() => selectedDept = v!),
                ),
              ),
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
                'iconName':     iconCtrl.text.trim(),
                'departmentId': selectedDept,
              };
              final notifier = ref.read(adminCategoriesProvider.notifier);
              final ok = cat == null
                  ? await notifier.create(data)
                  : await notifier.update(cat.id, data);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Saved' : 'Save failed')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
