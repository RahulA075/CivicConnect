import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/analytics_entity.dart';

class OfficerAnalyticsPage extends ConsumerStatefulWidget {
  const OfficerAnalyticsPage({super.key});

  @override
  ConsumerState<OfficerAnalyticsPage> createState() => _State();
}

class _State extends ConsumerState<OfficerAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mId = LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
      final dId = LocalStorage.getAuthString(StorageKeys.departmentId);
      if (mId.isEmpty) return;
      ref.read(analyticsNotifierProvider.notifier).load(mId, departmentId: dId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(analyticsNotifierProvider);
    final notifier = ref.read(analyticsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final mId =
                  LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
              final dId =
                  LocalStorage.getAuthString(StorageKeys.departmentId);
              notifier.load(mId, departmentId: dId);
            },
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (summary) {
          final trend = notifier.trendData;
          return RefreshIndicator(
            onRefresh: () async {
              final mId =
                  LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
              final dId =
                  LocalStorage.getAuthString(StorageKeys.departmentId);
              await notifier.load(mId, departmentId: dId);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status overview ────────────────────────────────
                Text('Status Overview',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(12),
                _StatusBreakdownChart(summary: summary),
                const Gap(20),

                // ── 30-day trend ───────────────────────────────────
                Text('30-Day Trend',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(12),
                trend.isEmpty
                    ? const _EmptyCard(label: 'No trend data available')
                    : _TrendChart(points: trend),
                const Gap(20),

                // ── Department breakdown ───────────────────────────
                Text('Department Performance',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(12),
                if (summary.departmentStats.isEmpty)
                  const _EmptyCard(label: 'No department data')
                else
                  ...summary.departmentStats
                      .map((d) => _DeptStatCard(stat: d)),

                const Gap(20),

                // ── Citizen rating ─────────────────────────────────
                _RatingCard(rating: summary.avgCitizenRating),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Status breakdown ──────────────────────────────────────────────────────────

class _StatusBreakdownChart extends StatelessWidget {
  const _StatusBreakdownChart({required this.summary});
  final DashboardSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (summary.totalOpen + summary.totalInProgress +
            summary.totalResolved + summary.totalClosed)
        .toDouble();

    final bars = [
      _Bar('Open',        summary.totalOpen,        AppColors.statusSubmitted),
      _Bar('In Progress', summary.totalInProgress,  AppColors.statusInProgress),
      _Bar('Resolved',    summary.totalResolved,     AppColors.statusResolved),
      _Bar('Overdue',     summary.totalOverdue,      AppColors.statusOverdue),
      _Bar('Closed',      summary.totalClosed,       AppColors.statusClosed),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: bars.map((b) {
            final frac = total > 0 ? b.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    SizedBox(
                      width: 90,
                      child: Text(b.label,
                          style: theme.textTheme.labelSmall),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:           frac,
                          backgroundColor: b.color.withValues(alpha: 0.15),
                          color:           b.color,
                          minHeight:       10,
                        ),
                      ),
                    ),
                    const Gap(8),
                    SizedBox(
                      width: 32,
                      child: Text('${b.value}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right),
                    ),
                  ]),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Bar {
  const _Bar(this.label, this.value, this.color);
  final String label;
  final int    value;
  final Color  color;
}

// ── Trend chart (simple bar) ──────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});
  final List<TrendPointEntity> points;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    // Show last 14 days for readability
    final visible  = points.length > 14 ? points.sublist(points.length - 14) : points;
    final maxVal   = visible
        .map((p) => p.submitted)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visible.map((p) {
                  final hSub = maxVal > 0 ? (p.submitted / maxVal) * 100 : 0.0;
                  final hRes = maxVal > 0 ? (p.resolved  / maxVal) * 100 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: hSub.clamp(2.0, 100.0),
                            color: AppColors.statusSubmitted.withValues(alpha: 0.7),
                          ),
                          const Gap(2),
                          Container(
                            height: hRes.clamp(2.0, 100.0),
                            color: AppColors.statusResolved.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Legend(color: AppColors.statusSubmitted, label: 'Submitted'),
              const Gap(16),
              _Legend(color: AppColors.statusResolved,  label: 'Resolved'),
            ]),
            const Gap(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dayLabel(visible.first.day),
                    style: theme.textTheme.labelSmall),
                Text(_dayLabel(visible.last.day),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime d) => '${d.day}/${d.month}';
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, color: color),
        const Gap(5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]);
}

// ── Department stat card ──────────────────────────────────────────────────────

class _DeptStatCard extends StatelessWidget {
  const _DeptStatCard({required this.stat});
  final DeptStatEntity stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.departmentName,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Gap(8),
            Row(children: [
              _DeptStat(label: 'Open',    value: '${stat.openCount}'),
              _DeptStat(label: 'Overdue', value: '${stat.overdueCount}',
                  color: stat.overdueCount > 0
                      ? AppColors.statusOverdue : null),
              _DeptStat(label: 'SLA',
                  value: '${stat.slaCompliancePct.toStringAsFixed(0)}%',
                  color: stat.slaCompliancePct < 70
                      ? AppColors.statusOverdue : AppColors.statusResolved),
              _DeptStat(label: 'Avg Hrs',
                  value: stat.avgResolutionHours.toStringAsFixed(1)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DeptStat extends StatelessWidget {
  const _DeptStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      );
}

// ── Rating card ───────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
          const Gap(12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rating == 0 ? 'No ratings yet'
                : rating.toStringAsFixed(1),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('Avg Citizen Satisfaction',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}

// ── Empty card ────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey)),
          ),
        ),
      );
}
