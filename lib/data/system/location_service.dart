import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location-related operations.
class LocationService {
  const LocationService();

  /// Checks if location permission is granted.
  Future<bool> hasLocationPermission() async {
    final PermissionStatus status =
        await Permission.location.status;
    return status.isGranted;
  }

  /// Requests location permission.
  Future<bool> requestLocationPermission() async {
    final PermissionStatus status =
        await Permission.location.request();
    return status.isGranted;
  }

  /// Gets the current GPS location.
  ///
  /// Returns null if permission is denied or location cannot be determined.
  Future<Position?> getCurrentLocation() async {
    try {
      final bool hasPermission =
          await hasLocationPermission();
      if (!hasPermission) {
        final bool granted =
            await requestLocationPermission();
        if (!granted) {
          developer.log(
            'Location permission denied',
            name: 'prayer_lock.location',
          );
          return null;
        }
      }

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log(
          'Location services are disabled',
          name: 'prayer_lock.location',
        );
        return null;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return position;
    } catch (e, s) {
      developer.log(
        'Failed to get location',
        name: 'prayer_lock.location',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return null;
    }
  }

  /// Gets location coordinates as a tuple.
  ///
  /// Returns null if location cannot be determined.
  Future<({double latitude, double longitude})?> getCoordinates() async {
    final Position? position = await getCurrentLocation();
    if (position == null) {
      return null;
    }
    return (
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

