import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/loading_indicator.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notifier.markAllRead(),
            child:     const Text('Mark all read'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => ErrorView(
          message: 'Failed to load notifications',
          onRetry: () => notifier.load(refresh: true),
        ),
        data: (items) {
          final list = (items as List<dynamic>);
          if (list.isEmpty) {
            return const EmptyState(
              icon:     Icons.notifications_none_rounded,
              title:    'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }
          return ListView.separated(
            padding:       const EdgeInsets.symmetric(vertical: 8),
            itemCount:     list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.isRead
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    _iconForType(n.type as String),
                    color: n.isRead
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  n.title as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: n.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.body as String,
                        style: theme.textTheme.bodySmall),
                    const Gap(2),
                    Text(
                      AppDateUtils.timeAgo(n.createdAt as DateTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  if (!(n.isRead as bool)) {
                    notifier.markRead(n.id as String);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) => switch (type.toUpperCase()) {
        'ISSUE_UPDATE'   => Icons.update_rounded,
        'STATUS_CHANGE'  => Icons.swap_horiz_rounded,
        'ASSIGNMENT'     => Icons.assignment_turned_in_outlined,
        _                => Icons.notifications_outlined,
      };
}
