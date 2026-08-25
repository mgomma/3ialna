import 'package:shared_preferences/shared_preferences.dart';

/// Parent-controlled, on-device pause state for the currently active child.
/// No child names, message contents, recordings, or remote payloads are stored.
class DevicePauseState {
  const DevicePauseState({
    required this.until,
    required this.reason,
    required this.childId,
  });

  final DateTime until;
  final String reason;
  final String childId;

  bool get isActive => DateTime.now().isBefore(until);
  int get remainingMinutes =>
      (until.difference(DateTime.now()).inMinutes + 1).clamp(0, 24 * 60);
}

class DevicePauseService {
  const DevicePauseService();

  static const String _untilKey = 'flutter.device_pause_until';
  static const String _reasonKey = 'flutter.device_pause_reason';
  static const String _childIdKey = 'flutter.device_pause_child_id';

  Future<DevicePauseState?> loadActive() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int untilMillis = preferences.getInt(_untilKey) ?? 0;
    if (untilMillis <= DateTime.now().millisecondsSinceEpoch) {
      await clear();
      return null;
    }
    return DevicePauseState(
      until: DateTime.fromMillisecondsSinceEpoch(untilMillis),
      reason: preferences.getString(_reasonKey) ?? 'family_time',
      childId: preferences.getString(_childIdKey) ?? '',
    );
  }

  Future<DevicePauseState> pause({
    required String reason,
    required int minutes,
    required String childId,
  }) async {
    final int safeMinutes = minutes.clamp(1, 24 * 60);
    final DateTime until = DateTime.now().add(Duration(minutes: safeMinutes));
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_untilKey, until.millisecondsSinceEpoch);
    await preferences.setString(_reasonKey, reason);
    await preferences.setString(_childIdKey, childId);
    return DevicePauseState(until: until, reason: reason, childId: childId);
  }

  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_untilKey);
    await preferences.remove(_reasonKey);
    await preferences.remove(_childIdKey);
  }
}
