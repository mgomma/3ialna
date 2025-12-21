import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app blocking with timestamps.
class AppBlockingService {
  static const String _keyBlockedApps = 'blocked_apps_with_timestamps';
  static const String _keyBlockDuration = 'block_duration_minutes';
  static const String _keyOverlayShown = 'overlay_shown_sessions';

  /// Default block duration in minutes.
  static const int defaultBlockDuration = 30;

  /// Blocks an app for a specified duration.
  Future<void> blockApp(String packageName, {int? durationMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    final duration = durationMinutes ?? 
        prefs.getInt(_keyBlockDuration) ?? defaultBlockDuration;

    // Store the duration for this block
    await prefs.setInt(_keyBlockDuration, duration);

    final blockedApps = await getBlockedApps();
    blockedApps[packageName] = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(
      _keyBlockedApps,
      jsonEncode(blockedApps),
    );
  }

  /// Unblocks an app immediately.
  Future<void> unblockApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedApps = await getBlockedApps();
    blockedApps.remove(packageName);

    await prefs.setString(
      _keyBlockedApps,
      jsonEncode(blockedApps),
    );
  }

  /// Gets all blocked apps with their block timestamps.
  Future<Map<String, int>> getBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBlockedApps);
    if (jsonString == null || jsonString.isEmpty) return {};

    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return map.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  /// Checks if an app is currently blocked.
  Future<bool> isAppBlocked(String packageName) async {
    final blockedApps = await getBlockedApps();
    if (!blockedApps.containsKey(packageName)) return false;

    final blockTimestamp = blockedApps[packageName]!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    final blockDuration = (prefs.getInt(_keyBlockDuration) ?? defaultBlockDuration) * 60 * 1000;

    // Check if block has expired
    if (now - blockTimestamp > blockDuration) {
      await unblockApp(packageName);
      return false;
    }

    return true;
  }

  /// Gets remaining block time in minutes.
  Future<int> getRemainingBlockTime(String packageName) async {
    final blockedApps = await getBlockedApps();
    final blockTimestamp = blockedApps[packageName];
    if (blockTimestamp == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    final blockDuration = (prefs.getInt(_keyBlockDuration) ?? defaultBlockDuration) * 60 * 1000;
    final elapsed = now - blockTimestamp;
    final remaining = blockDuration - elapsed;

    return remaining > 0 ? ((remaining / 1000 / 60).ceil()) : 0;
  }

  /// Sets the default block duration in minutes.
  Future<void> setBlockDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBlockDuration, minutes);
  }

  /// Gets the default block duration in minutes.
  Future<int> getBlockDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBlockDuration) ?? defaultBlockDuration;
  }

  /// Marks overlay as shown for a specific app in this session.
  Future<void> markOverlayShown(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getOverlayShownSessions();
    sessions.add(packageName);
    await prefs.setStringList(_keyOverlayShown, sessions.toList());
  }

  /// Checks if overlay was already shown for an app in this session.
  Future<bool> wasOverlayShown(String packageName) async {
    final sessions = await getOverlayShownSessions();
    return sessions.contains(packageName);
  }

  /// Clears overlay shown sessions (call this when app restarts or daily reset).
  Future<void> clearOverlayShownSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOverlayShown);
  }

  /// Gets list of apps for which overlay was shown this session.
  Future<Set<String>> getOverlayShownSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyOverlayShown) ?? [];
    return list.toSet();
  }

  /// Cleans up expired blocks.
  Future<void> cleanupExpiredBlocks() async {
    final blockedApps = await getBlockedApps();
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    final blockDuration = (prefs.getInt(_keyBlockDuration) ?? defaultBlockDuration) * 60 * 1000;

    final expired = <String>[];
    for (final entry in blockedApps.entries) {
      if (now - entry.value > blockDuration) {
        expired.add(entry.key);
      }
    }

    for (final packageName in expired) {
      await unblockApp(packageName);
    }
  }
}

