import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/notifications/domain/entities/notification_entity.dart';

class OfficerNotificationsPage extends ConsumerStatefulWidget {
  const OfficerNotificationsPage({super.key});

  @override
  ConsumerState<OfficerNotificationsPage> createState() => _State();
}

class _State extends ConsumerState<OfficerNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsNotifierProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          // state is AsyncValue<dynamic> so we cast
          final items = (data as List?)
                  ?.whereType<NotificationEntity>()
                  .toList() ??
              [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: Colors.grey),
                  Gap(12),
                  Text('No notifications',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(notificationsNotifierProvider.notifier)
                    .load(refresh: true),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _typeColor(n.eventType).withValues(alpha: 0.15),
                    child: Icon(_typeIcon(n.eventType),
                        color: _typeColor(n.eventType), size: 20),
                  ),
                  title: Text(
                    n.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.body.isNotEmpty)
                        Text(n.body,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      Text(
                        _fmtDate(n.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  tileColor: n.isRead
                      ? null
                      : theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.15),
                  onTap: () {
                    if (!n.isRead) {
                      ref
                          .read(notificationsNotifierProvider.notifier)
                          .markRead(n.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(String type) => switch (type.toUpperCase()) {
        'ISSUE_ASSIGNED' || 'ASSIGNMENT' => AppColors.statusAssigned,
        'STATUS_CHANGE'  || 'ISSUE_UPDATE' => AppColors.statusInProgress,
        'OVERDUE'                         => AppColors.statusOverdue,
        'ISSUE_RESOLVED'                  => AppColors.statusResolved,
        _                                 => AppColors.primary,
      };

  IconData _typeIcon(String type) => switch (type.toUpperCase()) {
        'ISSUE_ASSIGNED' || 'ASSIGNMENT'   => Icons.assignment_ind_rounded,
        'STATUS_CHANGE'  || 'ISSUE_UPDATE' => Icons.update_rounded,
        'OVERDUE'                          => Icons.warning_amber_rounded,
        'ISSUE_RESOLVED'                   => Icons.check_circle_outline_rounded,
        _                                  => Icons.notifications_rounded,
      };

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
