import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends ConsumerState<AdminAuditLogsPage> {
  String? _municipalityId;
  String? _actionFilter;

  final _actions = const [
    'CREATE_DEPARTMENT', 'UPDATE_DEPARTMENT', 'DEACTIVATE_DEPARTMENT',
    'INVITE_USER', 'DEACTIVATE_USER', 'REACTIVATE_USER',
    'CREATE_SLA_POLICY', 'UPDATE_SLA_POLICY',
    'CREATE_ESCALATION_RULE',
    'SEND_EMERGENCY_ALERT',
    'CREATE_CATEGORY', 'UPDATE_CATEGORY',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthAuthenticated) {
        _municipalityId = auth.user.municipalityId;
        if (_municipalityId != null) {
          ref.read(adminAuditLogsProvider.notifier).load(_municipalityId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by action',
            onSelected: (v) {
              setState(() => _actionFilter = v);
              if (_municipalityId != null) {
                ref.read(adminAuditLogsProvider.notifier)
                    .load(_municipalityId!, action: v, refresh: true);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String?>(value: null, child: Text('All Actions')),
              ..._actions.map((a) => PopupMenuItem(value: a, child: Text(a))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_actionFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Chip(
                  label: Text(_actionFilter!),
                  onDeleted: () {
                    setState(() => _actionFilter = null);
                    if (_municipalityId != null) {
                      ref.read(adminAuditLogsProvider.notifier)
                          .load(_municipalityId!, refresh: true);
                    }
                  },
                ),
              ]),
            ),
          Expanded(child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Error: $e')),
            data:    (logs) => logs.isEmpty
                ? const Center(child: Text('No audit entries found.'))
                : RefreshIndicator(
                    onRefresh: () async => ref
                        .read(adminAuditLogsProvider.notifier)
                        .refresh(),
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (_, i) => _AuditTile(log: logs[i]),
                    ),
                  ),
          )),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.log});
  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceVariant,
        child: const Icon(Icons.history_rounded),
      ),
      title: Text(log.action,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.performedByName != null)
            Text('By: ${log.performedByName}', style: const TextStyle(fontSize: 12)),
          if (log.entityType != null && log.entityId != null)
            Text('${log.entityType}: ${log.entityId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (log.detail != null)
            Text(log.detail!,
                style: const TextStyle(fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${log.createdAt.toLocal().toString().substring(0, 16)} '
            '${log.ipAddress != null ? '· ${log.ipAddress}' : ''}',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
          ),
        ],
      ),
      isThreeLine: true,
      dense: true,
    );
  }
}
