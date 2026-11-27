import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

/// Location helpers: permission checks, current position, distance.
abstract final class LocationUtils {
  /// Requests permission then returns the device's current position.
  /// Throws a [LocationException] if permission is denied or service is off.
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Haversine distance in metres between two lat/lng pairs.
  static double distanceInMetres(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Returns true if two points are within [AppConstants.duplicateRadiusM].
  static bool withinDuplicateRadius(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      distanceInMetres(lat1, lng1, lat2, lng2) <=
      AppConstants.duplicateRadiusM;

  static double _toRad(double deg) => deg * (math.pi / 180.0);
}

/// Thrown when location access fails.
class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => 'LocationException: $message';
}
