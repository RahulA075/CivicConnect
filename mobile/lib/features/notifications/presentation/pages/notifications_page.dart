import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsNotifierProvider.notifier).markAllRead();
              ref.read(unreadCountProvider.notifier).reset();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(notificationsNotifierProvider.notifier).load(refresh: true),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _NotifTile(
                notification: items[i],
                onTap: () => _onTap(context, ref, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTap(BuildContext ctx, WidgetRef ref, NotificationEntity n) {
    if (!n.isRead) {
      ref.read(notificationsNotifierProvider.notifier).markRead(n.id);
      ref.read(unreadCountProvider.notifier).decrement();
    }
    if (n.issueId != null) {
      ctx.push(Routes.issueDetailPath(n.issueId!));
    }
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification, required this.onTap});
  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _iconColor(notification.eventType);
    final icon  = _icon(notification.eventType);
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Icon ──────────────────────────────────────────────────
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTime(notification.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _TypeChip(eventType: notification.eventType),
              ],
            ),
          ),

          // ── Unread dot ────────────────────────────────────────────
          if (unread)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
        ]),
      ),
    );
  }

  Color _iconColor(String type) => switch (type) {
        NotifType.emergencyAlert => Colors.red.shade700,
        NotifType.nearbyIssue   => Colors.teal.shade600,
        NotifType.announcement  => Colors.purple.shade600,
        NotifType.statusChange  => Colors.blue.shade700,
        NotifType.assignment    => Colors.orange.shade700,
        _                       => Colors.grey.shade600,
      };

  IconData _icon(String type) => switch (type) {
        NotifType.emergencyAlert => Icons.emergency_rounded,
        NotifType.nearbyIssue   => Icons.location_on_rounded,
        NotifType.announcement  => Icons.campaign_rounded,
        NotifType.statusChange  => Icons.update_rounded,
        NotifType.assignment    => Icons.assignment_ind_rounded,
        NotifType.issueSubmitted => Icons.check_circle_outline_rounded,
        _                       => Icons.notifications_rounded,
      };

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    if (diff.inDays    < 7)  return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Type chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.eventType});
  final String eventType;

  @override
  Widget build(BuildContext context) {
    final label = switch (eventType) {
      NotifType.emergencyAlert  => 'Emergency',
      NotifType.nearbyIssue     => 'Nearby',
      NotifType.announcement    => 'Announcement',
      NotifType.statusChange    => 'Status Update',
      NotifType.issueSubmitted  => 'Submitted',
      NotifType.assignment      => 'Assigned',
      _                         => 'General',
    };

    final color = switch (eventType) {
      NotifType.emergencyAlert  => Colors.red,
      NotifType.nearbyIssue     => Colors.teal,
      NotifType.announcement    => Colors.purple,
      NotifType.statusChange    => Colors.blue,
      _                         => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color.shade700,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text("You're all caught up!",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
}
