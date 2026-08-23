import 'dart:io';

import 'package:flutter/services.dart';

class IosScreenTimeSafeguardService {
  static const MethodChannel _channel = MethodChannel('parental_control/ios_screen_time');

  Future<bool> isSelectionConfigured() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('isSafeguardSelectionConfigured') ?? false;
  }

  Future<bool> selectAppsAndCategories() async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('selectSafeguardApps') ?? false;
  }

  Future<bool> syncSleepShield({
    required bool enabled,
    required int startMinutes,
    required int endMinutes,
  }) async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('syncSleepShield', <String, Object>{
          'enabled': enabled,
          'startMinutes': startMinutes,
          'endMinutes': endMinutes,
        }) ??
        false;
  }

  Future<bool> schedulePrayerShields(List<Map<String, String>> windows) async {
    if (!Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>('schedulePrayerShields', windows) ?? false;
  }

  Future<void> clearPrayerShields() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod<void>('clearPrayerShields');
  }
}
