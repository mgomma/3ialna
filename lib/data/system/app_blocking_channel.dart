import 'package:flutter/services.dart';

/// Service for communicating with native Android code to block apps.
class AppBlockingChannel {
  static const MethodChannel _channel = MethodChannel('app_blocking/block');

  /// Blocks an app and closes it immediately.
  Future<bool> blockApp(String packageName, {int durationMinutes = 30}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'blockApp',
        {
          'packageName': packageName,
          'durationMinutes': durationMinutes,
        },
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Closes the current app and returns to home screen.
  Future<bool> closeAppAndGoHome() async {
    try {
      final result = await _channel.invokeMethod<bool>('closeAppAndGoHome');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

