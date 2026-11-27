import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/analytics_entity.dart';

class OfficerDashboardPage extends ConsumerStatefulWidget {
  const OfficerDashboardPage({super.key});
  @override
  ConsumerState<OfficerDashboardPage> createState() => _State();
}

class _State extends ConsumerState<OfficerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final municipalityId =
        LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
    final departmentId =
        LocalStorage.getAuthString(StorageKeys.departmentId);
    if (municipalityId.isEmpty) return;
    ref.read(analyticsNotifierProvider.notifier)
        .load(municipalityId, departmentId: departmentId);
    ref.read(deptIssuesNotifierProvider.notifier)
        .load(departmentId: departmentId ?? '', refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user      = authState is AuthAuthenticated ? authState.user : null;
    final analytics = ref.watch(analyticsNotifierProvider);
    final issues    = ref.watch(deptIssuesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(Routes.officerNotifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Welcome ─────────────────────────────────────────────
            _WelcomeBanner(name: user?.fullName ?? 'Officer', role: user?.role ?? ''),
            const Gap(16),

            // ── KPI cards ───────────────────────────────────────────
            analytics.when(
              loading: () => const _KpiSkeleton(),
              error:   (e, _) => _ErrorTile(message: e.toString()),
              data:    (s) => _KpiGrid(summary: s),
            ),
            const Gap(16),

            // ── Overdue banner ──────────────────────────────────────
            analytics.whenData((s) => s.totalOverdue > 0
                ? _OverdueBanner(count: s.totalOverdue)
                : const SizedBox.shrink()).valueOrNull ?? const SizedBox.shrink(),

            // ── Recent issues ───────────────────────────────────────
            Row(children: [
              Text('Recent Issues',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(Routes.officerIssues),
                child: const Text('See all'),
              ),
            ]),
            issues.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => _ErrorTile(message: e.toString()),
              data: (list) => list.isEmpty
                  ? const _EmptyState(message: 'No issues in your queue')
                  : Column(
                      children: list.take(5).map((issue) => _DashIssueRow(
                            issue:  issue,
                            onTap: () => context.push(
                                Routes.officerIssueDetailPath(issue.id)),
                          )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'O',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const Gap(12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $name',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            Text(role.replaceAll('_', ' '),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85))),
          ],
        )),
      ]),
    );
  }
}

// ── KPI grid ──────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});
  final DashboardSummaryEntity summary;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap:   true,
        physics:      const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          _KpiCard(label: 'Open',        value: '${summary.totalOpen}',
              color: AppColors.statusSubmitted),
          _KpiCard(label: 'In Progress', value: '${summary.totalInProgress}',
              color: AppColors.statusInProgress),
          _KpiCard(label: 'Resolved',    value: '${summary.totalResolved}',
              color: AppColors.statusResolved),
          _KpiCard(label: 'Overdue',     value: '${summary.totalOverdue}',
              color: AppColors.statusOverdue),
        ],
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 130,
      child: Center(child: CircularProgressIndicator()));
}

// ── Overdue banner ────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.statusOverdue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.statusOverdue.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.statusOverdue, size: 20),
          const Gap(8),
          Expanded(
            child: Text('$count issue${count > 1 ? 's' : ''} overdue — action required',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.statusOverdue, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

// ── Dashboard issue row ───────────────────────────────────────────────────────

class _DashIssueRow extends StatelessWidget {
  const _DashIssueRow({required this.issue, required this.onTap});
  final dynamic issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: _StatusDot(status: issue.status as String),
        title: Text(issue.title as String,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${issue.categoryName}  ·  ${issue.trackingId}',
            style: theme.textTheme.labelSmall),
        trailing: issue.isOverdue
            ? const Icon(Icons.warning_rounded,
                color: AppColors.statusOverdue, size: 18)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return CircleAvatar(
      radius: 6,
      backgroundColor: color,
    );
  }

  Color _color(String s) => switch (s.toUpperCase()) {
        'SUBMITTED'   => AppColors.statusSubmitted,
        'ASSIGNED'    => AppColors.statusAssigned,
        'IN_PROGRESS' => AppColors.statusInProgress,
        'RESOLVED'    => AppColors.statusResolved,
        _             => AppColors.statusOverdue,
      };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const Gap(8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.grey)),
          ]),
        ),
      );
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(message,
            style: Theme.of(context).textTheme.bodySmall),
      );
}
