import 'package:flutter/services.dart';
import '../../domain/models/app_info.dart';

/// Service for querying installed applications on the device.
class AppListService {
  static const MethodChannel _channel = MethodChannel('parental_control/apps');

  /// Gets all installed applications.
  Future<List<AppInfo>> getAllInstalledApps({
    bool includeSystemApps = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAllInstalledApps',
        {'includeSystemApps': includeSystemApps},
      );
      if (result == null) return [];
      return result
          .map((map) => AppInfo.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets app info for a specific package name.
  Future<AppInfo?> getAppInfo(String packageName) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getAppInfo',
        {'packageName': packageName},
      );
      if (result == null) return null;
      return AppInfo.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      return null;
    }
  }

  /// Checks if an app is installed.
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        {'packageName': packageName},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

