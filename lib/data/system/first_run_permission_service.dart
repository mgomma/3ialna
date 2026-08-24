import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Checks and opens only the operating-system settings required for first-run
/// parental controls. It stores no location, usage, child, or recording data.
class FirstRunPermissionService {
  const FirstRunPermissionService();

  static const MethodChannel _channel =
      MethodChannel('parental_control/onboarding');

  Future<bool> hasLocationPermission() async {
    final PermissionStatus status = await Permission.location.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestLocationPermission() {
    return Permission.location.request();
  }

  Future<bool> openLocationSettings() async {
    return openAppSettings();
  }

  Future<bool> hasUsageAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openUsageAccessSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openUsageAccessSettings') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
