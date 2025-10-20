import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Authentication tokens
  Future<void> saveAuthTokens(String accessToken, String refreshToken) async {
    await _prefs.setString(AppConstants.tokenKey, accessToken);
    await _prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  String? getAccessToken() => _prefs.getString(AppConstants.tokenKey);
  String? getRefreshToken() => _prefs.getString(AppConstants.refreshTokenKey);

  Future<void> clearAuthTokens() async {
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
  }

  // User data
  Future<void> saveUserRole(String role) async {
    await _prefs.setString(AppConstants.userRoleKey, role);
  }

  String? getUserRole() => _prefs.getString(AppConstants.userRoleKey);

  Future<void> clearUserData() async {
    await _prefs.remove(AppConstants.userRoleKey);
  }

  // Language settings
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(AppConstants.languageKey, language);
  }

  String getLanguage() => _prefs.getString(AppConstants.languageKey) ?? 'en';

  // Theme settings
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(AppConstants.themeKey, theme);
  }

  String getTheme() => _prefs.getString(AppConstants.themeKey) ?? 'system';

  // Device settings
  Future<void> saveDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    await _prefs.setString('device_settings_$deviceId', jsonEncode(settings));
  }

  Map<String, dynamic>? getDeviceSettings(String deviceId) {
    final settings = _prefs.getString('device_settings_$deviceId');
    if (settings != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(settings);
        return parsed;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Prayer settings
  Future<void> savePrayerSettings(Map<String, dynamic> settings) async {
    await _prefs.setString('prayer_settings', jsonEncode(settings));
  }

  Map<String, dynamic>? getPrayerSettings() {
    final settings = _prefs.getString('prayer_settings');
    if (settings != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(settings);
        return parsed;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // App usage limits
  Future<void> saveAppLimits(String deviceId, Map<String, int> limits) async {
    await _prefs.setString('app_limits_$deviceId', jsonEncode(limits));
  }

  Map<String, int>? getAppLimits(String deviceId) {
    final limits = _prefs.getString('app_limits_$deviceId');
    if (limits != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(limits);
        return parsed.map((k, v) => MapEntry(k, v as int));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Last sync time
  Future<void> saveLastSyncTime(String deviceId, DateTime time) async {
    await _prefs.setString('last_sync_$deviceId', time.toIso8601String());
  }

  DateTime? getLastSyncTime(String deviceId) {
    final timeString = _prefs.getString('last_sync_$deviceId');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Offline data queue
  Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    await _prefs.setString('offline_$key', jsonEncode(data));
  }

  Map<String, dynamic>? getOfflineData(String key) {
    final data = _prefs.getString('offline_$key');
    if (data != null) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(data);
        return parsed;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearOfflineData(String key) async {
    await _prefs.remove('offline_$key');
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Check if first launch
  bool isFirstLaunch() => !_prefs.containsKey('first_launch');

  Future<void> setFirstLaunchCompleted() async {
    await _prefs.setBool('first_launch', false);
  }

  // User preferences
  Future<void> saveUserPreference(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    }
  }

  T? getUserPreference<T>(String key) {
    return _prefs.get(key) as T?;
  }

  Future<void> removeUserPreference(String key) async {
    await _prefs.remove(key);
  }
}
