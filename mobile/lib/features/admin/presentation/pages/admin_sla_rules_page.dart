import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminSlaRulesPage extends ConsumerStatefulWidget {
  const AdminSlaRulesPage({super.key});

  @override
  ConsumerState<AdminSlaRulesPage> createState() => _AdminSlaRulesPageState();
}

class _AdminSlaRulesPageState extends ConsumerState<AdminSlaRulesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminSlaPoliciesProvider.notifier).load(_municipalityId!);
          ref.read(adminEscalationRulesProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Policies & Escalation Rules'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'SLA Policies'), Tab(text: 'Escalation Rules')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_SlaPoliciesTab(municipalityId: _municipalityId),
                   _EscalationRulesTab(municipalityId: _municipalityId)],
      ),
    );
  }
}

// ── SLA Policies tab ──────────────────────────────────────────────────────────

class _SlaPoliciesTab extends ConsumerWidget {
  const _SlaPoliciesTab({required this.municipalityId});
  final String? municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSlaPoliciesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'sla_fab',
        onPressed: () => _showSlaDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (policies) => policies.isEmpty
            ? const Center(child: Text('No SLA policies configured.'))
            : ListView.builder(
                itemCount: policies.length,
                itemBuilder: (_, i) => _SlaPolicyTile(
                  policy: policies[i],
                  onEdit: () => _showSlaDialog(context, ref, policy: policies[i]),
                  onDeactivate: () async {
                    await ref.read(adminSlaPoliciesProvider.notifier)
                        .deactivate(policies[i].id);
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _showSlaDialog(BuildContext context, WidgetRef ref,
      {SlaPolicyEntity? policy}) async {
    if (municipalityId == null) return;

    final formKey   = GlobalKey<FormState>();
    final resCtrl   = TextEditingController(
        text: policy?.resolutionHours.toString() ?? '48');
    final warnCtrl  = TextEditingController(
        text: policy?.warningHours.toString() ?? '36');
    final escCtrl   = TextEditingController(
        text: policy?.escalationHours.toString() ?? '48');
    String priority = policy?.priority ?? 'MEDIUM';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(policy == null ? 'New SLA Policy' : 'Edit SLA Policy'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            StatefulBuilder(builder: (_, ss) =>
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW',      child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM',   child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH',     child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) => ss(() => priority = v!),
              ),
            ),
            TextFormField(controller: resCtrl,
                decoration: const InputDecoration(labelText: 'Resolution Hours'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: warnCtrl,
                decoration: const InputDecoration(labelText: 'Warning Hours'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: escCtrl,
                decoration: const InputDecoration(labelText: 'Escalation Hours'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final data = {
                'priority':        priority,
                'resolutionHours': int.parse(resCtrl.text),
                'warningHours':    int.parse(warnCtrl.text),
                'escalationHours': int.parse(escCtrl.text),
              };
              final notifier = ref.read(adminSlaPoliciesProvider.notifier);
              policy == null
                  ? await notifier.create(data)
                  : await notifier.update(policy.id, data);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SlaPolicyTile extends StatelessWidget {
  const _SlaPolicyTile(
      {required this.policy, required this.onEdit, required this.onDeactivate});
  final SlaPolicyEntity policy;
  final VoidCallback    onEdit;
  final VoidCallback    onDeactivate;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.rule_rounded)),
        title: Text('${policy.priority} — ${policy.categoryName ?? 'All Categories'}'),
        subtitle: Text(
            'Resolution: ${policy.resolutionHours}h  '
            'Warning: ${policy.warningHours}h  '
            'Escalation: ${policy.escalationHours}h'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'deactivate') onDeactivate();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
          ],
        ),
      );
}

// ── Escalation Rules tab ──────────────────────────────────────────────────────

class _EscalationRulesTab extends ConsumerWidget {
  const _EscalationRulesTab({required this.municipalityId});
  final String? municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminEscalationRulesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'esc_fab',
        onPressed: () => _showEscDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (rules) => rules.isEmpty
            ? const Center(child: Text('No escalation rules configured.'))
            : ListView.builder(
                itemCount: rules.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.arrow_upward_rounded)),
                  title: Text(
                      'After ${rules[i].triggerAfterHours}h → ${rules[i].escalateToRole.replaceAll('_', ' ')}'),
                  subtitle: Text(rules[i].departmentName ?? 'All departments'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: () async {
                      await ref.read(adminEscalationRulesProvider.notifier)
                          .deactivate(rules[i].id);
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _showEscDialog(BuildContext context, WidgetRef ref) async {
    if (municipalityId == null) return;

    final formKey   = GlobalKey<FormState>();
    final hoursCtrl = TextEditingController(text: '72');
    final msgCtrl   = TextEditingController();
    String role = 'MUNICIPAL_ADMIN';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Escalation Rule'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: hoursCtrl,
                decoration: const InputDecoration(
                    labelText: 'Trigger After (hours)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            StatefulBuilder(builder: (_, ss) =>
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Escalate To'),
                items: const [
                  DropdownMenuItem(value: 'DEPT_SUPERVISOR', child: Text('Dept Supervisor')),
                  DropdownMenuItem(value: 'MUNICIPAL_ADMIN', child: Text('Municipal Admin')),
                  DropdownMenuItem(value: 'SYSTEM_ADMIN',    child: Text('System Admin')),
                ],
                onChanged: (v) => ss(() => role = v!),
              ),
            ),
            TextFormField(controller: msgCtrl,
                decoration: const InputDecoration(
                    labelText: 'Notification Message (optional)'),
                maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              await ref.read(adminEscalationRulesProvider.notifier).create({
                'triggerAfterHours':   int.parse(hoursCtrl.text),
                'escalateToRole':      role,
                'notificationMessage': msgCtrl.text.trim(),
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
