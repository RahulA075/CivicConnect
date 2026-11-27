import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../features/issues/domain/entities/nearby_issue_entity.dart';
import '../../../../features/issues/domain/usecases/get_map_issues_usecase.dart';

// ── Map layer enum ────────────────────────────────────────────────────────────

enum MapLayer { markers, heatmap, clusters }

// ── Map filter state ──────────────────────────────────────────────────────────

class MapFilter {
  const MapFilter({
    this.status,
    this.categoryId,
    this.radiusMetres = 5000,
  });
  final String? status;
  final String? categoryId;
  final int     radiusMetres;

  MapFilter copyWith({
    String? status,
    String? categoryId,
    int?    radiusMetres,
    bool    clearStatus   = false,
    bool    clearCategory = false,
  }) =>
      MapFilter(
        status:       clearStatus   ? null : status       ?? this.status,
        categoryId:   clearCategory ? null : categoryId   ?? this.categoryId,
        radiusMetres: radiusMetres ?? this.radiusMetres,
      );
}

// ── Main map state ────────────────────────────────────────────────────────────

class MapState {
  const MapState({
    this.issues         = const [],
    this.markers        = const {},
    this.circles        = const {},
    this.polylines      = const {},
    this.layer          = MapLayer.markers,
    this.filter         = const MapFilter(),
    this.userLocation,
    this.isLoading      = false,
    this.error,
    this.searchQuery    = '',
    this.searchResults  = const [],
    this.selectedIssue,
    this.directionsOrigin,
    this.directionsDestination,
    this.showRadiusCircle = true,
  });

  final List<NearbyIssueEntity> issues;
  final Set<Marker>             markers;
  final Set<Circle>             circles;
  final Set<Polyline>           polylines;
  final MapLayer                layer;
  final MapFilter               filter;
  final LatLng?                 userLocation;
  final bool                    isLoading;
  final String?                 error;
  final String                  searchQuery;
  final List<NearbyIssueEntity> searchResults;
  final NearbyIssueEntity?      selectedIssue;
  final LatLng?                 directionsOrigin;
  final LatLng?                 directionsDestination;
  final bool                    showRadiusCircle;

  MapState copyWith({
    List<NearbyIssueEntity>? issues,
    Set<Marker>?             markers,
    Set<Circle>?             circles,
    Set<Polyline>?           polylines,
    MapLayer?                layer,
    MapFilter?               filter,
    LatLng?                  userLocation,
    bool?                    isLoading,
    String?                  error,
    bool                     clearError    = false,
    String?                  searchQuery,
    List<NearbyIssueEntity>? searchResults,
    NearbyIssueEntity?       selectedIssue,
    bool                     clearSelected = false,
    LatLng?                  directionsOrigin,
    LatLng?                  directionsDestination,
    bool?                    showRadiusCircle,
  }) =>
      MapState(
        issues:        issues       ?? this.issues,
        markers:       markers      ?? this.markers,
        circles:       circles      ?? this.circles,
        polylines:     polylines    ?? this.polylines,
        layer:         layer        ?? this.layer,
        filter:        filter       ?? this.filter,
        userLocation:  userLocation ?? this.userLocation,
        isLoading:     isLoading    ?? this.isLoading,
        error:         clearError   ? null : error ?? this.error,
        searchQuery:   searchQuery  ?? this.searchQuery,
        searchResults: searchResults ?? this.searchResults,
        selectedIssue: clearSelected ? null : selectedIssue ?? this.selectedIssue,
        directionsOrigin:      directionsOrigin      ?? this.directionsOrigin,
        directionsDestination: directionsDestination ?? this.directionsDestination,
        showRadiusCircle:      showRadiusCircle      ?? this.showRadiusCircle,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier(this._useCase) : super(const MapState());

  final GetMapIssuesUseCase _useCase;

  // ── Load issues ──────────────────────────────────────────────────────────

  Future<void> loadIssues({
    required double latitude,
    required double longitude,
  }) async {
    final municipalityId =
        LocalStorage.getAuthString(StorageKeys.municipalityId) ?? '';
    if (municipalityId.isEmpty) return;

    state = state.copyWith(
      isLoading:    true,
      userLocation: LatLng(latitude, longitude),
      clearError:   true,
    );

    final result = await _useCase(
      latitude:       latitude,
      longitude:      longitude,
      municipalityId: municipalityId,
      radiusMetres:   state.filter.radiusMetres,
      status:         state.filter.status,
      categoryId:     state.filter.categoryId,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error:     failure.message,
      ),
      (issues) {
        state = state.copyWith(
          issues:    issues,
          isLoading: false,
        );
        _rebuildOverlays(latitude, longitude);
      },
    );
  }

  // ── Rebuild map overlays based on current layer ──────────────────────────

  void _rebuildOverlays(double lat, double lng) {
    switch (state.layer) {
      case MapLayer.markers:
        _buildMarkers();
      case MapLayer.heatmap:
        _buildHeatmap();
      case MapLayer.clusters:
        _buildClusters(lat, lng);
    }
    _buildRadiusCircle(lat, lng);
  }

  // ── Markers layer ────────────────────────────────────────────────────────

  void _buildMarkers() {
    final markers = state.issues.map((issue) {
      final hue = _statusHue(issue.status);
      return Marker(
        markerId:  MarkerId(issue.id),
        position:  LatLng(issue.latitude, issue.longitude),
        icon:      BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title:   issue.title,
          snippet: '${issue.status} · ${issue.categoryName} · ↑${issue.upvoteCount}',
        ),
        onTap: () => _selectIssue(issue),
      );
    }).toSet();

    state = state.copyWith(markers: markers);
  }

  // ── Heatmap layer (simulated via semi-transparent circles) ───────────────

  void _buildHeatmap() {
    final circles = <Circle>{};

    for (final issue in state.issues) {
      final intensity = math.min(issue.upvoteCount / 20.0, 1.0);
      final color = Color.lerp(
        Colors.green.withValues(alpha: 0.25),
        Colors.red.withValues(alpha: 0.55),
        intensity,
      )!;

      circles.add(Circle(
        circleId:   CircleId('heat_${issue.id}'),
        center:     LatLng(issue.latitude, issue.longitude),
        radius:     80 + (issue.upvoteCount * 5.0).clamp(0, 200),
        fillColor:  color,
        strokeWidth: 0,
        strokeColor: Colors.transparent,
      ));
    }

    // Clear markers when in heatmap mode
    state = state.copyWith(markers: {}, circles: circles);
  }

  // ── Cluster layer (grid-based clustering) ───────────────────────────────

  void _buildClusters(double centerLat, double centerLng) {
    const gridSize = 0.01; // ~1 km grid cells
    final Map<String, List<NearbyIssueEntity>> buckets = {};

    for (final issue in state.issues) {
      final gridLat = (issue.latitude  / gridSize).floor() * gridSize;
      final gridLng = (issue.longitude / gridSize).floor() * gridSize;
      final key     = '${gridLat}_$gridLng';
      (buckets[key] ??= []).add(issue);
    }

    final markers = <Marker>{};
    for (final entry in buckets.entries) {
      final group = entry.value;
      final avgLat = group.map((i) => i.latitude).reduce((a, b) => a + b) /
          group.length;
      final avgLng = group.map((i) => i.longitude).reduce((a, b) => a + b) /
          group.length;

      if (group.length == 1) {
        final issue = group.first;
        markers.add(Marker(
          markerId:  MarkerId('c_${issue.id}'),
          position:  LatLng(avgLat, avgLng),
          icon:      BitmapDescriptor.defaultMarkerWithHue(
              _statusHue(issue.status)),
          infoWindow: InfoWindow(
            title:   issue.title,
            snippet: issue.status,
          ),
          onTap: () => _selectIssue(issue),
        ));
      } else {
        // Cluster bubble — use a custom badge marker
        markers.add(Marker(
          markerId:   MarkerId('cluster_${entry.key}'),
          position:   LatLng(avgLat, avgLng),
          icon:       BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title:   '${group.length} issues',
            snippet: 'Tap to zoom in',
          ),
        ));
      }
    }

    state = state.copyWith(markers: markers, circles: {});
  }

  // ── Radius circle ────────────────────────────────────────────────────────

  void _buildRadiusCircle(double lat, double lng) {
    if (!state.showRadiusCircle) {
      state = state.copyWith(circles: state.layer == MapLayer.heatmap
          ? state.circles
          : {});
      return;
    }

    final radiusCircle = Circle(
      circleId:    const CircleId('radius'),
      center:      LatLng(lat, lng),
      radius:      state.filter.radiusMetres.toDouble(),
      fillColor:   Colors.blue.withValues(alpha: 0.05),
      strokeColor: Colors.blue.withValues(alpha: 0.3),
      strokeWidth: 1,
    );

    // Merge with heatmap circles if needed
    if (state.layer == MapLayer.heatmap) {
      final merged = Set<Circle>.from(state.circles)..add(radiusCircle);
      state = state.copyWith(circles: merged);
    } else {
      state = state.copyWith(circles: {radiusCircle});
    }
  }

  // ── Layer switching ──────────────────────────────────────────────────────

  void setLayer(MapLayer layer) {
    state = state.copyWith(layer: layer);
    final loc = state.userLocation;
    if (loc != null) _rebuildOverlays(loc.latitude, loc.longitude);
  }

  // ── Filter ───────────────────────────────────────────────────────────────

  Future<void> applyFilter(MapFilter filter) async {
    state = state.copyWith(filter: filter);
    final loc = state.userLocation;
    if (loc != null) await loadIssues(latitude: loc.latitude, longitude: loc.longitude);
  }

  // ── Search (local, by title / address) ──────────────────────────────────

  void search(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: []);
      return;
    }
    final q = query.toLowerCase();
    final results = state.issues
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.addressText.toLowerCase().contains(q) ||
            i.categoryName.toLowerCase().contains(q) ||
            i.trackingId.toLowerCase().contains(q))
        .take(10)
        .toList();
    state = state.copyWith(searchQuery: query, searchResults: results);
  }

  void clearSearch() =>
      state = state.copyWith(searchQuery: '', searchResults: []);

  // ── Issue selection (for bottom sheet detail) ────────────────────────────

  void _selectIssue(NearbyIssueEntity issue) =>
      state = state.copyWith(selectedIssue: issue);

  void selectIssue(NearbyIssueEntity issue) =>
      state = state.copyWith(selectedIssue: issue);

  void clearSelection() =>
      state = state.copyWith(clearSelected: true);

  // ── Directions (draws polyline between origin and destination) ───────────

  void setDirections({
    required LatLng origin,
    required LatLng destination,
  }) {
    // Straight-line polyline (real turn-by-turn needs Directions API)
    final polyline = Polyline(
      polylineId: const PolylineId('directions'),
      points:     [origin, destination],
      color:      Colors.blue,
      width:      4,
      patterns:   [PatternItem.dash(20), PatternItem.gap(10)],
    );
    state = state.copyWith(
      directionsOrigin:      origin,
      directionsDestination: destination,
      polylines: {polyline},
    );
  }

  void clearDirections() =>
      state = state.copyWith(
        polylines:             {},
        directionsOrigin:      state.userLocation,
        directionsDestination: null,
      );

  // ── Radius circle visibility ──────────────────────────────────────────────

  void toggleRadiusCircle() {
    state = state.copyWith(showRadiusCircle: !state.showRadiusCircle);
    final loc = state.userLocation;
    if (loc != null) _buildRadiusCircle(loc.latitude, loc.longitude);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _statusHue(String status) => switch (status.toUpperCase()) {
        'SUBMITTED'   => BitmapDescriptor.hueBlue,
        'ASSIGNED'    => BitmapDescriptor.hueViolet,
        'IN_PROGRESS' => BitmapDescriptor.hueOrange,
        'RESOLVED'    => BitmapDescriptor.hueGreen,
        'VERIFIED'    => BitmapDescriptor.hueCyan,
        _             => BitmapDescriptor.hueRed,
      };
}

// ── Provider ──────────────────────────────────────────────────────────────────

// Exposed via providers.dart — declared here for export
