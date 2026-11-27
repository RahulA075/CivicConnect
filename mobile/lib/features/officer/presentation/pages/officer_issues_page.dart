import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../presentation/providers/officer_provider.dart';

class OfficerIssuesPage extends ConsumerStatefulWidget {
  const OfficerIssuesPage({super.key});
  @override
  ConsumerState<OfficerIssuesPage> createState() => _State();
}

class _State extends ConsumerState<OfficerIssuesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String? _statusFilter;

  static const _statuses = [
    null, 'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED',
  ];
  static const _labels = [
    'All', 'Submitted', 'Assigned', 'In Progress', 'Resolved',
  ];

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

  void _load() {
    final deptId = LocalStorage.getAuthString(StorageKeys.departmentId) ?? '';
    ref.read(deptIssuesNotifierProvider.notifier)
        .load(departmentId: deptId, status: _statusFilter, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final issues = ref.watch(deptIssuesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Complaints'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded),   text: 'List'),
            Tab(icon: Icon(Icons.map_rounded),     text: 'Map'),
          ],
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by status',
            onSelected: (v) {
              setState(() => _statusFilter = v);
              _load();
            },
            itemBuilder: (_) => List.generate(
              _statuses.length,
              (i) => PopupMenuItem<String?>(
                value: _statuses[i],
                child: Text(_labels[i]),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── List view ──────────────────────────────────────────────
          issues.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('$e')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No issues found'))
                : RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => _IssueListTile(
                        issue:     list[i],
                        onTap:     () => context.push(
                            Routes.officerIssueDetailPath(list[i].id)),
                        onAccept:  () => _quickAccept(list[i].id),
                        onReject:  () => _showRejectDialog(list[i].id),
                      ),
                    ),
                  ),
          ),

          // ── Map view ───────────────────────────────────────────────
          issues.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('$e')),
            data: (list) => _IssueMapView(issues: list),
          ),
        ],
      ),
    );
  }

  Future<void> _quickAccept(String issueId) async {
    await ref.read(officerActionsNotifierProvider.notifier).accept(issueId);
    if (!mounted) return;
    final s = ref.read(officerActionsNotifierProvider);
    if (s is OfficerActionSuccess) {
      _showSnack('Issue accepted → In Progress');
      _load();
    } else if (s is OfficerActionFailure) {
      _showSnack(s.failure.message, error: true);
    }
    ref.read(officerActionsNotifierProvider.notifier).reset();
  }

  void _showRejectDialog(String issueId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Issue'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection…',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(officerActionsNotifierProvider.notifier)
                  .reject(issueId, ctrl.text.trim());
              _showSnack('Issue rejected');
              _load();
              ref.read(officerActionsNotifierProvider.notifier).reset();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : null,
      ));
}

// ── List tile ─────────────────────────────────────────────────────────────────

class _IssueListTile extends StatelessWidget {
  const _IssueListTile({
    required this.issue,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final IssueEntity  issue;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final canAct  = issue.status == 'SUBMITTED' || issue.status == 'ASSIGNED';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(issue.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              StatusBadge.status(issue.status),
              if (issue.isOverdue) ...[
                const Gap(4),
                const Icon(Icons.warning_rounded,
                    size: 16, color: AppColors.statusOverdue),
              ],
            ]),
            const Gap(4),
            Row(children: [
              Icon(Icons.category_outlined, size: 13,
                  color: theme.colorScheme.onSurfaceVariant),
              const Gap(4),
              Text(issue.categoryName,
                  style: theme.textTheme.labelSmall),
              const Gap(12),
              Icon(Icons.location_on_outlined, size: 13,
                  color: theme.colorScheme.onSurfaceVariant),
              const Gap(4),
              Expanded(
                child: Text(issue.address,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall),
              ),
            ]),
            if (issue.dueDate != null) ...[
              const Gap(4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 13,
                    color: issue.isOverdue ? AppColors.statusOverdue
                        : theme.colorScheme.onSurfaceVariant),
                const Gap(4),
                Text(
                  'Due ${_fmt(issue.dueDate!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: issue.isOverdue
                          ? AppColors.statusOverdue : null),
                ),
              ]),
            ],
            if (canAct) ...[
              const Gap(8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ── Map view ──────────────────────────────────────────────────────────────────

class _IssueMapView extends StatefulWidget {
  const _IssueMapView({required this.issues});
  final List<IssueEntity> issues;

  @override
  State<_IssueMapView> createState() => _IssueMapViewState();
}

class _IssueMapViewState extends State<_IssueMapView> {

  Set<Marker> _buildMarkers(BuildContext context) => widget.issues.map((i) {
        final hue = _hue(i.status);
        return Marker(
          markerId: MarkerId(i.id),
          position: LatLng(i.latitude, i.longitude),
          icon:     BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title:   i.title,
            snippet: '${i.status} · ${i.trackingId}',
          ),
        );
      }).toSet();

  double _hue(String status) => switch (status.toUpperCase()) {
        'SUBMITTED'   => BitmapDescriptor.hueBlue,
        'ASSIGNED'    => BitmapDescriptor.hueViolet,
        'IN_PROGRESS' => BitmapDescriptor.hueOrange,
        'RESOLVED'    => BitmapDescriptor.hueGreen,
        _             => BitmapDescriptor.hueRed,
      };

  @override
  Widget build(BuildContext context) {
    final center = widget.issues.isNotEmpty
        ? LatLng(widget.issues.first.latitude, widget.issues.first.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 13),
      markers:              _buildMarkers(context),
      myLocationEnabled:    true,
      myLocationButtonEnabled: true,
      onMapCreated:         (c) {},
    );
  }
}
