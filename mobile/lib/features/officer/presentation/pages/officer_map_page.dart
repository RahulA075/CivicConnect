import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/issues/domain/entities/issue_entity.dart';

class OfficerMapPage extends ConsumerStatefulWidget {
  const OfficerMapPage({super.key});

  @override
  ConsumerState<OfficerMapPage> createState() => _State();
}

class _State extends ConsumerState<OfficerMapPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final deptId = LocalStorage.getAuthString(StorageKeys.departmentId) ?? '';
    ref.read(deptIssuesNotifierProvider.notifier)
        .load(departmentId: deptId, refresh: true);
  }

  Set<Marker> _markers(List<IssueEntity> issues) => issues.map((i) {
        final hue = _hue(i.status);
        return Marker(
          markerId:  MarkerId(i.id),
          position:  LatLng(i.latitude, i.longitude),
          icon:      BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title:   i.title,
            snippet: '${i.status} · ${i.trackingId}',
            onTap: () => context.push(Routes.officerIssueDetailPath(i.id)),
          ),
          onTap: () {},
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
    final issues = ref.watch(deptIssuesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Stack(children: [
        issues.when(
          loading: () => GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
              zoom:   AppConstants.defaultZoom,
            ),
            onMapCreated: (_) {},
          ),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final center = list.isNotEmpty
                ? LatLng(list.first.latitude, list.first.longitude)
                : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);
            return GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: center, zoom: AppConstants.defaultZoom),
              markers:              _markers(list),
              myLocationEnabled:    true,
              myLocationButtonEnabled: true,
              onMapCreated:         (c) {},
            );
          },
        ),

        // Loading overlay
        if (issues is AsyncLoading)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),

        // Legend
        Positioned(
          bottom: 24,
          left:   12,
          child: _Legend(),
        ),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: AppColors.statusSubmitted,  label: 'Submitted'),
          _Dot(color: AppColors.statusAssigned,   label: 'Assigned'),
          _Dot(color: AppColors.statusInProgress, label: 'In Progress'),
          _Dot(color: AppColors.statusResolved,   label: 'Resolved'),
          _Dot(color: AppColors.statusOverdue,    label: 'Overdue'),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}
