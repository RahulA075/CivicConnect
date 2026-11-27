import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../presentation/providers/officer_provider.dart';

class OfficerIssueDetailPage extends ConsumerStatefulWidget {
  const OfficerIssueDetailPage({super.key, required this.issueId});
  final String issueId;

  @override
  ConsumerState<OfficerIssueDetailPage> createState() => _State();
}

class _State extends ConsumerState<OfficerIssueDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  IssueEntity? _issue;
  bool _loadingIssue = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadingIssue = true);
    // Load issue via issueRepository
    final r = await ref.read(issueRepositoryProvider).getIssueById(widget.issueId);
    r.fold(
      (_) => setState(() => _loadingIssue = false),
      (i) => setState(() { _issue = i; _loadingIssue = false; }),
    );
    // Load timeline
    ref.read(timelineNotifierProvider.notifier).load(widget.issueId);
    // Load workers
    final deptId       = LocalStorage.getAuthString(StorageKeys.departmentId) ?? '';
    final municipalityId = LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
    if (deptId.isNotEmpty && municipalityId.isNotEmpty) {
      ref.read(workersNotifierProvider.notifier)
          .load(departmentId: deptId, municipalityId: municipalityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingIssue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_issue == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Issue not found')),
      );
    }

    final issue = _issue!;

    return Scaffold(
      appBar: AppBar(
        title: Text(issue.trackingId,
            style: const TextStyle(fontFamily: 'monospace')),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Actions'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DetailsTab(issue: issue),
          _ActionsTab(issue: issue, onDone: _load),
          _TimelineTab(issueId: issue.id),
        ],
      ),
    );
  }
}

// ── Details tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.issue});
  final IssueEntity issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(children: [
          Expanded(
            child: Text(issue.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          StatusBadge.status(issue.status),
        ]),
        const Gap(8),
        if (issue.isOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:        AppColors.statusOverdue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.warning_rounded, color: AppColors.statusOverdue, size: 16),
              Gap(6),
              Text('Overdue', style: TextStyle(color: AppColors.statusOverdue,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        const Gap(12),
        _InfoRow(icon: Icons.category_outlined, label: 'Category', value: issue.categoryName),
        _InfoRow(icon: Icons.priority_high_rounded, label: 'Priority',
            value: issue.priority,
            valueColor: _priorityColor(issue.priority)),
        if (issue.departmentName != null)
          _InfoRow(icon: Icons.business_rounded, label: 'Department',
              value: issue.departmentName!),
        if (issue.assignedTo != null)
          _InfoRow(icon: Icons.person_rounded, label: 'Assigned To',
              value: issue.assignedTo!),
        _InfoRow(icon: Icons.location_on_outlined, label: 'Address',
            value: issue.address.isNotEmpty ? issue.address : '—'),
        _InfoRow(icon: Icons.person_outline_rounded, label: 'Reporter',
            value: issue.reporterName ?? 'Anonymous'),
        _InfoRow(icon: Icons.calendar_today_rounded, label: 'Submitted',
            value: _fmt(issue.createdAt)),
        if (issue.dueDate != null)
          _InfoRow(icon: Icons.schedule_rounded, label: 'SLA Deadline',
              value: _fmt(issue.dueDate!),
              valueColor: issue.isOverdue ? AppColors.statusOverdue : null),
        const Gap(12),
        Text('Description', style: theme.textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(6),
        Text(issue.description, style: theme.textTheme.bodyMedium),
        const Gap(16),
        // Upvotes + comments
        Row(children: [
          _StatChip(icon: Icons.thumb_up_rounded,
              value: '${issue.upvoteCount} upvotes'),
          const Gap(8),
          _StatChip(icon: Icons.comment_outlined,
              value: '${issue.commentCount} comments'),
        ]),
      ],
    );
  }

  Color _priorityColor(String p) => switch (p.toUpperCase()) {
        'LOW'      => AppColors.priorityLow,
        'MEDIUM'   => AppColors.priorityMedium,
        'HIGH'     => AppColors.priorityHigh,
        'CRITICAL' => AppColors.priorityCritical,
        _          => AppColors.priorityMedium,
      };

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const Gap(8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});
  final IconData icon;
  final String   value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14),
          const Gap(5),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}

// ── Actions tab ───────────────────────────────────────────────────────────────

class _ActionsTab extends ConsumerStatefulWidget {
  const _ActionsTab({required this.issue, required this.onDone});
  final IssueEntity  issue;
  final VoidCallback onDone;

  @override
  ConsumerState<_ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends ConsumerState<_ActionsTab> {
  String?  _selectedWorkerId;
  String?  _selectedStatus;
  String   _note = '';
  final _noteCtrl = TextEditingController();

  static const _statusOptions = [
    'IN_PROGRESS', 'RESOLVED', 'ASSIGNED', 'CLOSED', 'REOPENED',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final workers = ref.watch(workersNotifierProvider);
    final action  = ref.watch(officerActionsNotifierProvider);
    final isLoading = action is OfficerActionLoading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Accept / Reject ────────────────────────────────────────
        if (widget.issue.status == 'SUBMITTED' ||
            widget.issue.status == 'ASSIGNED') ...[
          Text('Quick Actions',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Gap(10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () => _reject(context),
                icon:  const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
            const Gap(10),
            Expanded(
              child: AppButton(
                label:     'Accept',
                isLoading: isLoading,
                icon: const Icon(Icons.check_rounded, size: 18),
                onPressed: () => _accept(context),
              ),
            ),
          ]),
          const Divider(height: 28),
        ],

        // ── Assign worker ──────────────────────────────────────────
        Text('Assign to Worker',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(10),
        workers.when(
          loading: () => const LinearProgressIndicator(),
          error:   (e, _) => Text('$e',
              style: const TextStyle(color: Colors.red)),
          data: (list) => list.isEmpty
              ? const Text('No workers available',
                  style: TextStyle(color: Colors.grey))
              : DropdownButtonFormField<String>(
                  initialValue: _selectedWorkerId,
                  hint: const Text('Select worker'),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()),
                  items: list.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Row(children: [
                          CircleAvatar(radius: 12,
                              child: Text(w.fullName[0])),
                          const Gap(8),
                          Expanded(child: Text(w.fullName,
                              overflow: TextOverflow.ellipsis)),
                        ]),
                      )).toList(),
                  onChanged: (v) => setState(() => _selectedWorkerId = v),
                ),
        ),
        const Gap(10),
        AppButton(
          label:     'Assign',
          isLoading: isLoading,
          icon:  const Icon(Icons.person_add_rounded, size: 18),
          onPressed: _selectedWorkerId == null ? null : () => _assign(context),
        ),
        const Divider(height: 28),

        // ── Update status / progress ───────────────────────────────
        Text('Update Status',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(10),
        DropdownButtonFormField<String>(
          initialValue: _selectedStatus,
          hint: const Text('Choose new status'),
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: _statusOptions.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.replaceAll('_', ' ')),
              )).toList(),
          onChanged: (v) => setState(() => _selectedStatus = v),
        ),
        const Gap(10),
        TextField(
          controller: _noteCtrl,
          maxLines:   3,
          decoration: const InputDecoration(
            hintText: 'Progress note / update details…',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _note = v,
        ),
        const Gap(10),
        AppButton(
          label:     'Upload Progress',
          isLoading: isLoading,
          icon:  const Icon(Icons.upload_rounded, size: 18),
          onPressed: _selectedStatus == null ? null : () => _updateStatus(context),
        ),

        // ── Feedback ───────────────────────────────────────────────
        if (action is OfficerActionFailure) ...[
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text((action).failure.message,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ],
    );
  }

  Future<void> _accept(BuildContext context) async {
    await ref.read(officerActionsNotifierProvider.notifier)
        .accept(widget.issue.id);
    if (!mounted) return;
    _feedback(context);
  }

  void _reject(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Issue'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Reason…',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(officerActionsNotifierProvider.notifier)
                  .reject(widget.issue.id, ctrl.text.trim());
              if (mounted) _feedback(context);
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _assign(BuildContext context) async {
    await ref.read(officerActionsNotifierProvider.notifier)
        .assign(widget.issue.id, _selectedWorkerId!, note: _note.trim());
    if (!mounted) return;
    _feedback(context);
  }

  Future<void> _updateStatus(BuildContext context) async {
    await ref.read(officerActionsNotifierProvider.notifier)
        .updateStatus(widget.issue.id, _selectedStatus!, note: _note.trim());
    if (!mounted) return;
    _feedback(context);
  }

  void _feedback(BuildContext context) {
    final s = ref.read(officerActionsNotifierProvider);
    if (s is OfficerActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action completed successfully')));
      widget.onDone();
    } else if (s is OfficerActionFailure) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((s).failure.message),
          backgroundColor: Colors.red));
    }
    ref.read(officerActionsNotifierProvider.notifier).reset();
  }
}

// ── Timeline tab ──────────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab({required this.issueId});
  final String issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineNotifierProvider);
    final theme    = Theme.of(context);

    return timeline.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('$e')),
      data: (history) => history.isEmpty
          ? const Center(child: Text('No history yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (_, i) {
                final h      = history[i];
                final isLast = i == history.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Timeline line + dot ──────────────────────
                      Column(children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color:        _statusColor(h.newStatus),
                            shape:        BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                                width: 2,
                                color: theme.colorScheme.outlineVariant),
                          ),
                      ]),
                      const Gap(12),
                      // ── Content ──────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusColor(h.newStatus)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    h.newStatus.replaceAll('_', ' '),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: _statusColor(h.newStatus),
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const Spacer(),
                                Text(_fmtTime(h.createdAt),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant)),
                              ]),
                              if (h.changedByName != null) ...[
                                const Gap(3),
                                Text('by ${h.changedByName}'
                                    '${h.changedByRole != null ? ' (${h.changedByRole!.replaceAll('_', ' ')})' : ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant)),
                              ],
                              if (h.note != null && h.note!.isNotEmpty) ...[
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(h.note!,
                                      style: theme.textTheme.bodySmall),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _statusColor(String? s) => switch ((s ?? '').toUpperCase()) {
        'SUBMITTED'   => AppColors.statusSubmitted,
        'ASSIGNED'    => AppColors.statusAssigned,
        'IN_PROGRESS' => AppColors.statusInProgress,
        'RESOLVED'    => AppColors.statusResolved,
        'VERIFIED'    => AppColors.statusResolved,
        'REJECTED'    => AppColors.statusOverdue,
        'CLOSED'      => AppColors.statusClosed,
        _             => AppColors.statusSubmitted,
      };

  String _fmtTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
