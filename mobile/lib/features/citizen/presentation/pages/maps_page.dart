import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/issues/domain/entities/nearby_issue_entity.dart';
import '../../../../../features/maps/presentation/providers/maps_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MapsPage — Phase 7 full implementation
// Features: Current Location, Markers, Nearby Complaints, Marker Clustering,
//           Heat Map, Directions, Search Location, Navigation, Issue Radius
// ─────────────────────────────────────────────────────────────────────────────

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});

  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  GoogleMapController? _mapCtrl;
  final _searchCtrl = TextEditingController();
  bool _gpsInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ── GPS init ──────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
      if (!mounted) return;
      _gpsInit = true;
      _animateTo(pos.latitude, pos.longitude);
      await ref.read(mapNotifierProvider.notifier).loadIssues(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
    } catch (_) {}
  }

  void _animateTo(double lat, double lng, {double zoom = AppConstants.defaultZoom}) {
    _mapCtrl?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom),
    );
  }

  void _goToMyLocation() => _initLocation();

  // ── Navigate to issue (directions) ───────────────────────────────────────

  void _navigateToIssue(NearbyIssueEntity issue) {
    final loc = ref.read(mapNotifierProvider).userLocation;
    if (loc == null) return;
    ref.read(mapNotifierProvider.notifier).setDirections(
          origin:      loc,
          destination: LatLng(issue.latitude, issue.longitude),
        );
    _animateTo(issue.latitude, issue.longitude, zoom: 16);
    Navigator.of(context).pop(); // close bottom sheet if open
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String q) {
    ref.read(mapNotifierProvider.notifier).search(q);
  }

  void _onSearchResultTap(NearbyIssueEntity issue) {
    _searchCtrl.clear();
    ref.read(mapNotifierProvider.notifier).clearSearch();
    _animateTo(issue.latitude, issue.longitude, zoom: 17);
    ref.read(mapNotifierProvider.notifier).selectIssue(issue);
    _showIssueBottomSheet(issue);
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _showIssueBottomSheet(NearbyIssueEntity issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _IssueBottomSheet(
        issue:    issue,
        onDetail: () {
          Navigator.of(context).pop();
          context.push(Routes.issueDetailPath(issue.id));
        },
        onNavigate: () => _navigateToIssue(issue),
      ),
    );
  }

  // ── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet() {
    final current = ref.read(mapNotifierProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapFilterSheet(
        current: current,
        onApply: (filter) async {
          Navigator.of(context).pop();
          await ref.read(mapNotifierProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final theme    = Theme.of(context);

    // React to new issues — show snack if error
    ref.listen<MapState>(mapNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final initialPos = CameraPosition(
      target: mapState.userLocation ??
          const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
      zoom: AppConstants.defaultZoom,
    );

    return Scaffold(
      body: Stack(children: [
        // ── Google Map ────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: initialPos,
          markers:               mapState.markers,
          circles:               mapState.circles,
          polylines:             mapState.polylines,
          myLocationEnabled:     true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled:   false,
          mapToolbarEnabled:     false,
          mapType:               MapType.normal,
          onMapCreated: (ctrl) {
            _mapCtrl = ctrl;
            if (!_gpsInit) _initLocation();
          },
          onLongPress: (latlng) async {
            await ref.read(mapNotifierProvider.notifier).loadIssues(
                  latitude: latlng.latitude, longitude: latlng.longitude);
            _animateTo(latlng.latitude, latlng.longitude);
          },
          onTap: (_) {
            ref.read(mapNotifierProvider.notifier).clearSelection();
            ref.read(mapNotifierProvider.notifier).clearSearch();
            _searchCtrl.clear();
          },
        ),

        // ── Search bar ────────────────────────────────────────────────
        Positioned(
          top:   MediaQuery.of(context).padding.top + 8,
          left:  12, right: 12,
          child: _SearchBar(
            controller: _searchCtrl,
            results:    mapState.searchResults,
            onChanged:  _onSearchChanged,
            onResultTap: _onSearchResultTap,
            onClear: () {
              _searchCtrl.clear();
              ref.read(mapNotifierProvider.notifier).clearSearch();
            },
          ),
        ),

        // ── Layer switcher ────────────────────────────────────────────
        Positioned(
          top:   MediaQuery.of(context).padding.top + 72,
          right: 12,
          child: _LayerToggle(
            current: mapState.layer,
            onChanged: (l) =>
                ref.read(mapNotifierProvider.notifier).setLayer(l),
          ),
        ),

        // ── Loading spinner ───────────────────────────────────────────
        if (mapState.isLoading)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),

        // ── Legend ────────────────────────────────────────────────────
        if (mapState.layer == MapLayer.markers)
          Positioned(
            bottom: 120,
            left:   12,
            child: _MapLegend(theme: theme),
          ),

        // ── Issues count badge ────────────────────────────────────────
        Positioned(
          bottom: 120,
          right:  12,
          child: _IssuesBadge(
            count:    mapState.issues.length,
            radius:   mapState.filter.radiusMetres,
            onFilter: _showFilterSheet,
          ),
        ),

        // ── Directions clear button ───────────────────────────────────
        if (mapState.polylines.isNotEmpty)
          Positioned(
            bottom: 176,
            right:  12,
            child: FloatingActionButton.small(
              heroTag:     'clear_dir',
              backgroundColor: Colors.red,
              onPressed: () =>
                  ref.read(mapNotifierProvider.notifier).clearDirections(),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white),
            ),
          ),

        // ── My location FAB ───────────────────────────────────────────
        Positioned(
          bottom: 176,
          left:   12,
          child: FloatingActionButton.small(
            heroTag: 'my_loc',
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),

        // ── Report FAB ────────────────────────────────────────────────
        Positioned(
          bottom: 24,
          right:  12,
          child: FloatingActionButton.extended(
            heroTag:  'report',
            onPressed: () => context.push(Routes.reportIssue),
            icon:     const Icon(Icons.add_rounded),
            label:    const Text('Report Issue'),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar widget
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.results,
    required this.onChanged,
    required this.onResultTap,
    required this.onClear,
  });

  final TextEditingController         controller;
  final List<NearbyIssueEntity>       results;
  final ValueChanged<String>          onChanged;
  final ValueChanged<NearbyIssueEntity> onResultTap;
  final VoidCallback                  onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          elevation:   4,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller:  controller,
            onChanged:   onChanged,
            decoration:  InputDecoration(
              hintText:     'Search issues, addresses…',
              prefixIcon:   const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                    )
                  : null,
              border:      OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled:      true,
              fillColor:   theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        if (results.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final issue = results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  title:    Text(issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(issue.categoryName,
                      style: theme.textTheme.labelSmall),
                  onTap: () => onResultTap(issue),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layer toggle widget
// ─────────────────────────────────────────────────────────────────────────────

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({required this.current, required this.onChanged});

  final MapLayer                  current;
  final ValueChanged<MapLayer>    onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _LayerBtn(
            icon:     Icons.place_rounded,
            tooltip:  'Markers',
            active:   current == MapLayer.markers,
            onTap:    () => onChanged(MapLayer.markers),
          ),
          _LayerBtn(
            icon:     Icons.blur_on_rounded,
            tooltip:  'Heat Map',
            active:   current == MapLayer.heatmap,
            onTap:    () => onChanged(MapLayer.heatmap),
          ),
          _LayerBtn(
            icon:     Icons.grain_rounded,
            tooltip:  'Clusters',
            active:   current == MapLayer.clusters,
            onTap:    () => onChanged(MapLayer.clusters),
          ),
        ],
      ),
    );
  }
}

class _LayerBtn extends StatelessWidget {
  const _LayerBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData  icon;
  final String    tooltip;
  final bool      active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon,
                size:  22,
                color: active
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend widget
// ─────────────────────────────────────────────────────────────────────────────

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:        theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withValues(alpha: 0.1),
                blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status', style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
            const Gap(4),
            _LegendDot(color: AppColors.statusSubmitted,  label: 'Submitted'),
            _LegendDot(color: AppColors.statusAssigned,   label: 'Assigned'),
            _LegendDot(color: AppColors.statusInProgress, label: 'In Progress'),
            _LegendDot(color: AppColors.statusResolved,   label: 'Resolved'),
            _LegendDot(color: AppColors.statusOverdue,    label: 'Overdue'),
          ],
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const Gap(5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Issues badge + filter button
// ─────────────────────────────────────────────────────────────────────────────

class _IssuesBadge extends StatelessWidget {
  const _IssuesBadge({
    required this.count,
    required this.radius,
    required this.onFilter,
  });
  final int     count;
  final int     radius;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded, size: 16,
              color: theme.colorScheme.onPrimaryContainer),
          const Gap(6),
          Text(
            '$count issues · ${(radius / 1000).toStringAsFixed(1)} km',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Issue bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _IssueBottomSheet extends StatelessWidget {
  const _IssueBottomSheet({
    required this.issue,
    required this.onDetail,
    required this.onNavigate,
  });

  final NearbyIssueEntity issue;
  final VoidCallback onDetail;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(issue.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  _StatusChip(status: issue.status),
                ]),
                const Gap(6),
                Row(children: [
                  const Icon(Icons.category_outlined, size: 14),
                  const Gap(4),
                  Text(issue.categoryName,
                      style: theme.textTheme.bodySmall),
                  const Gap(12),
                  const Icon(Icons.arrow_upward_rounded, size: 14),
                  const Gap(4),
                  Text('${issue.upvoteCount} upvotes',
                      style: theme.textTheme.bodySmall),
                ]),
                if (issue.addressText.isNotEmpty) ...[
                  const Gap(4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14),
                    const Gap(4),
                    Expanded(
                      child: Text(issue.addressText,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                if (issue.distanceMetres > 0) ...[
                  const Gap(4),
                  Text(
                    issue.distanceMetres < 1000
                        ? '${issue.distanceMetres.round()} m away'
                        : '${(issue.distanceMetres / 1000).toStringAsFixed(1)} km away',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary),
                  ),
                ],
                const Gap(16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDetail,
                      icon:  const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('View Details'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onNavigate,
                      icon:  const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _chipColor(String s) => switch (s.toUpperCase()) {
        'SUBMITTED'   => AppColors.statusSubmitted,
        'ASSIGNED'    => AppColors.statusAssigned,
        'IN_PROGRESS' => AppColors.statusInProgress,
        'RESOLVED'    => AppColors.statusResolved,
        _             => AppColors.statusOverdue,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Map filter bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MapFilterSheet extends StatefulWidget {
  const _MapFilterSheet({required this.current, required this.onApply});
  final MapFilter current;
  final ValueChanged<MapFilter> onApply;

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late String? _status;
  late double  _radius;

  static const _statuses = [
    'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.current.status;
    _radius = widget.current.radiusMetres.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Filter Map',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() { _status = null; _radius = 5000; });
              },
              child: const Text('Reset'),
            ),
          ]),
          const Gap(12),

          // Status filter
          Text('Status', style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label:    const Text('All'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              ..._statuses.map((s) => FilterChip(
                    label:    Text(s.replaceAll('_', ' ')),
                    selected: _status == s,
                    onSelected: (_) =>
                        setState(() => _status = _status == s ? null : s),
                  )),
            ],
          ),
          const Gap(16),

          // Radius filter
          Text(
            'Search Radius: ${_radius < 1000
                ? '${_radius.round()} m'
                : '${(_radius / 1000).toStringAsFixed(0)} km'}',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Slider(
            value:   _radius,
            min:     500,
            max:     20000,
            divisions: 19,
            label:   _radius < 1000
                ? '${_radius.round()} m'
                : '${(_radius / 1000).toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _radius = v),
          ),
          const Gap(8),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onApply(MapFilter(
                status:       _status,
                radiusMetres: _radius.round(),
              )),
              child: const Text('Apply Filter'),
            ),
          ),
        ],
      ),
    );
  }
}
