import 'package:flutter/services.dart';

/// Service for managing Kiosk Mode (Lock Task Mode) functionality.
class KioskService {
  static const MethodChannel _channel = MethodChannel('parental_control/kiosk');

  /// Checks if the app is a device owner.
  Future<bool> isDeviceOwner() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceOwner');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if device admin is enabled.
  Future<bool> isDeviceAdminEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Requests device admin permission from the user.
  Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      throw Exception('Failed to request device admin: $e');
    }
  }

  /// Starts kiosk mode (lock task mode).
  Future<bool> startKioskMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('startKioskMode');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stops kiosk mode (lock task mode).
  Future<bool> stopKioskMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopKioskMode');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if kiosk mode is currently active.
  Future<bool> isKioskModeActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isKioskModeActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sets lock task packages (device owner only).
  Future<bool> setLockTaskPackages() async {
    try {
      final result = await _channel.invokeMethod<bool>('setLockTaskPackages');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

