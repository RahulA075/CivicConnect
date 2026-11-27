import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../features/ai/presentation/widgets/issue_ai_summary_card.dart';

class IssueDetailPage extends ConsumerWidget {
  const IssueDetailPage({super.key, required this.issueId});
  final String issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find from cached feed/my-issues first, else fetch
    final feedItems = ref.watch(feedNotifierProvider).valueOrNull ?? [];
    final myItems   = ref.watch(myIssuesNotifierProvider).valueOrNull ?? [];
    final all       = [...feedItems, ...myItems];
    final cached    = all.cast<dynamic>().where((i) => i.id == issueId).firstOrNull;

    if (cached == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Issue Detail')),
        body: const LoadingIndicator(),
      );
    }

    final issue = cached;
    final theme  = Theme.of(context);
    final isBookmarked =
        ref.watch(bookmarkNotifierProvider).contains(issueId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar + image ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: issue.imageUrls.isNotEmpty ? 240 : 0,
            pinned: true,
            title: Text(issue.trackingId,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            actions: [
              IconButton(
                icon: Icon(isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded),
                onPressed: () => ref
                    .read(bookmarkNotifierProvider.notifier)
                    .toggle(issueId),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => Share.share(
                    'Track issue ${issue.trackingId} on CivicConnect'),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome_outlined),
                tooltip: 'AI Analysis',
                onPressed: () => context.push(
                  Routes.aiInsightsPath(issueId),
                  extra: {'trackingId': issue.trackingId},
                ),
              ),
            ],
            flexibleSpace: issue.imageUrls.isNotEmpty
                ? FlexibleSpaceBar(
                    background: PageView.builder(
                      itemCount: issue.imageUrls.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: issue.imageUrls[i],
                        fit:      BoxFit.cover,
                      ),
                    ),
                  )
                : null,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Status + priority ──────────────────────────────
                Row(children: [
                  StatusBadge.status(issue.status),
                  const Gap(8),
                  StatusBadge.priority(issue.priority),
                  if (issue.isOverdue) ...[
                    const Gap(8),
                    StatusBadge(
                        label: 'OVERDUE', color: AppColors.statusOverdue),
                  ],
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(AppDateUtils.formatDate(issue.createdAt),
                        style: theme.textTheme.labelSmall),
                    if (issue.resolvedAt != null)
                      Text(
                        'Resolved ${AppDateUtils.timeAgo(issue.resolvedAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.statusResolved),
                      ),
                  ]),
                ]),
                const Gap(16),

                // ── Title ────────────────────────────────────────────
                Text(issue.title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(8),

                // ── Category + department ─────────────────────────────
                _InfoRow(
                    icon: Icons.category_outlined,
                    text: issue.categoryName),
                if (issue.departmentName != null)
                  _InfoRow(
                      icon: Icons.business_outlined,
                      text: issue.departmentName!),
                if (issue.address.isNotEmpty)
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: issue.address),
                const Gap(12),

                // ── Description ────────────────────────────────────────
                Text('Description',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Gap(6),
                Text(issue.description, style: theme.textTheme.bodyMedium),
                const Gap(12),

                // ── AI Analysis Summary ─────────────────────────────────
                IssueAiSummaryCard(issueId: issueId),
                const Gap(8),

                // ── Stats ───────────────────────────────────────────────
                _StatsRow(issue: issue),
                const Gap(16),

                // ── Tracking ID copy ────────────────────────────────────
                _TrackingRow(trackingId: issue.trackingId),
                const Gap(16),

                // ── Timeline placeholder ────────────────────────────────
                Text('Status Timeline',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Gap(8),
                _TimelineItem(
                  status:    issue.status,
                  timestamp: issue.createdAt,
                  note:      'Issue submitted',
                  isLast:    true,
                ),
                if (issue.resolvedAt != null)
                  _TimelineItem(
                    status:    'RESOLVED',
                    timestamp: issue.resolvedAt!,
                    note:      'Issue resolved',
                    isLast:    false,
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const Gap(8),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ]),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.issue});
  final dynamic issue;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Stat(icon: Icons.thumb_up_outlined,
            value: '${issue.upvoteCount}', label: 'Upvotes'),
      _Stat(icon: Icons.comment_outlined,
            value: '${issue.commentCount}', label: 'Comments'),
      if (issue.dueDate != null)
        _Stat(
            icon: AppDateUtils.isOverdue(issue.dueDate!)
                ? Icons.warning_amber_rounded
                : Icons.timer_outlined,
            value: AppDateUtils.formatDate(issue.dueDate!),
            label: 'SLA Deadline'),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String   value;
  final String   label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Icon(icon, color: theme.colorScheme.primary),
      const Gap(4),
      Text(value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _TrackingRow extends StatelessWidget {
  const _TrackingRow({required this.trackingId});
  final String trackingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Icons.receipt_long_outlined,
            color: theme.colorScheme.onPrimaryContainer),
        const Gap(8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tracking ID',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            Text(trackingId,
                style: theme.textTheme.titleSmall?.copyWith(
                    color:      theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.copy_rounded,
              color: theme.colorScheme.onPrimaryContainer),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: trackingId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tracking ID copied')),
            );
          },
        ),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.status,
    required this.timestamp,
    required this.note,
    required this.isLast,
  });

  final String   status;
  final DateTime timestamp;
  final String   note;
  final bool     isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
        ),
        if (!isLast)
          Container(width: 2, height: 32, color: theme.colorScheme.outline),
      ]),
      const Gap(12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note, style: theme.textTheme.bodySmall
              ?.copyWith(fontWeight: FontWeight.w600)),
          Text(AppDateUtils.formatDateTime(timestamp),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Gap(8),
        ]),
      ),
    ]);
  }
}
