import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/schedule.dart';

/// Service for storing and retrieving parental control settings.
class ParentalControlStorageService {
  static const String _keyBlockedApps = 'parental_control_blocked_apps';
  static const String _keyTimeLimits = 'parental_control_time_limits';
  static const String _keySchedule = 'parental_control_schedule';
  static const String _keyParentPin = 'parental_control_parent_pin';
  static const String _keyKioskModeEnabled = 'parental_control_kiosk_mode_enabled';

  /// Gets the list of blocked app package names.
  Future<List<String>> getBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBlockedApps);
    if (jsonString == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// Sets the list of blocked app package names.
  Future<void> setBlockedApps(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBlockedApps, jsonEncode(packageNames));
  }

  /// Adds an app to the blocked list.
  Future<void> blockApp(String packageName) async {
    final blocked = await getBlockedApps();
    if (!blocked.contains(packageName)) {
      blocked.add(packageName);
      await setBlockedApps(blocked);
    }
  }

  /// Removes an app from the blocked list.
  Future<void> unblockApp(String packageName) async {
    final blocked = await getBlockedApps();
    blocked.remove(packageName);
    await setBlockedApps(blocked);
  }

  /// Checks if an app is blocked.
  Future<bool> isAppBlocked(String packageName) async {
    final blocked = await getBlockedApps();
    return blocked.contains(packageName);
  }

  /// Gets time limits for apps (in minutes).
  Future<Map<String, int>> getTimeLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyTimeLimits);
    if (jsonString == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return map.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  /// Sets time limits for apps (in minutes).
  Future<void> setTimeLimits(Map<String, int> limits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimeLimits, jsonEncode(limits));
  }

  /// Sets time limit for a specific app (in minutes).
  Future<void> setAppTimeLimit(String packageName, int minutes) async {
    final limits = await getTimeLimits();
    limits[packageName] = minutes;
    await setTimeLimits(limits);
  }

  /// Removes time limit for an app.
  Future<void> removeAppTimeLimit(String packageName) async {
    final limits = await getTimeLimits();
    limits.remove(packageName);
    await setTimeLimits(limits);
  }

  /// Gets the time limit for an app (in minutes), returns null if not set.
  Future<int?> getAppTimeLimit(String packageName) async {
    final limits = await getTimeLimits();
    return limits[packageName];
  }

  /// Gets the schedule settings.
  Future<Schedule> getSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySchedule);
    if (jsonString == null) {
      return const Schedule(
        enabled: false,
        startTime: '09:00',
        endTime: '21:00',
        activeDays: [1, 2, 3, 4, 5, 6, 0],
      );
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return Schedule.fromMap(map);
    } catch (e) {
      return const Schedule(
        enabled: false,
        startTime: '09:00',
        endTime: '21:00',
        activeDays: [1, 2, 3, 4, 5, 6, 0],
      );
    }
  }

  /// Sets the schedule settings.
  Future<void> setSchedule(Schedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySchedule, jsonEncode(schedule.toMap()));
  }

  /// Gets the hashed parent PIN.
  Future<String?> getParentPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyParentPin);
  }

  /// Sets the hashed parent PIN.
  Future<void> setParentPin(String hashedPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParentPin, hashedPin);
  }

  /// Checks if parent PIN is set.
  Future<bool> hasParentPin() async {
    final pin = await getParentPin();
    return pin != null && pin.isNotEmpty;
  }

  /// Gets kiosk mode enabled state.
  Future<bool> isKioskModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKioskModeEnabled) ?? false;
  }

  /// Sets kiosk mode enabled state.
  Future<void> setKioskModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKioskModeEnabled, enabled);
  }
}

