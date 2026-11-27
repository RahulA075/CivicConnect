import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminAlertsPage extends ConsumerStatefulWidget {
  const AdminAlertsPage({super.key});

  @override
  ConsumerState<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends ConsumerState<AdminAlertsPage> {
  String? _municipalityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminAlertsProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(adminAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_rounded),
            tooltip: 'New Alert',
            onPressed: () => _showAlertDialog(context),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (alerts) => alerts.isEmpty
            ? const Center(child: Text('No emergency alerts.'))
            : RefreshIndicator(
                onRefresh: () async {
                  if (_municipalityId != null) {
                    ref.read(adminAlertsProvider.notifier)
                        .load(_municipalityId!);
                  }
                },
                child: ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _showAlertDialog(BuildContext context) async {
    if (_municipalityId == null) return;

    final formKey   = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final msgCtrl   = TextEditingController();
    String severity = 'HIGH';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Emergency Alert'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: msgCtrl,
                decoration: const InputDecoration(labelText: 'Message *'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (_, ss) =>
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: const [
                  DropdownMenuItem(value: 'LOW',      child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM',   child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH',     child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) => ss(() => severity = v!),
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
              final ok = await ref.read(adminAlertsProvider.notifier).create({
                'title':    titleCtrl.text.trim(),
                'message':  msgCtrl.text.trim(),
                'severity': severity,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Alert sent!' : 'Failed to send')));
              }
            },
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final EmergencyAlertEntity alert;

  Color _severityColor() => switch (alert.severity) {
        'CRITICAL' => Colors.red.shade700,
        'HIGH'     => Colors.orange.shade700,
        'MEDIUM'   => Colors.amber.shade700,
        _          => Colors.blue.shade700,
      };

  IconData _severityIcon() => switch (alert.severity) {
        'CRITICAL' => Icons.emergency_rounded,
        'HIGH'     => Icons.warning_rounded,
        'MEDIUM'   => Icons.info_rounded,
        _          => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(_severityIcon(), color: color),
        ),
        title: Text(alert.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Chip(
                label: Text(alert.severity,
                    style: TextStyle(color: color, fontSize: 11)),
                backgroundColor: color.withOpacity(0.1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              if (!alert.active)
                Chip(
                  label: const Text('Inactive',
                      style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
            ]),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
