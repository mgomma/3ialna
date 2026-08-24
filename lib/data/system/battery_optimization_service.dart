import 'package:flutter/services.dart';

/// Android-only access to the system Battery Optimization review screen.
///
/// This deliberately opens the general system list rather than requesting a
/// direct Doze exemption, which remains the parent's decision.
class BatteryOptimizationService {
  const BatteryOptimizationService();

  static const MethodChannel _channel =
      MethodChannel('parent_voice_notifications');

  Future<bool> isIgnoringBatteryOptimizations() async {
    return await _channel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations',
        ) ??
        false;
  }

  Future<void> openSystemSettings() =>
      _channel.invokeMethod<void>('openBatteryOptimizationSettings');
}
