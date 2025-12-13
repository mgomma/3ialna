import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper for checking AccessibilityService status and opening settings.
class AccessibilityServiceHelper {
  static const MethodChannel _channel = MethodChannel('app_blocking/accessibility');

  /// Checks if AccessibilityService is enabled.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } on MissingPluginException {
      // Method channel not available (e.g., in overlay or after hot reload)
      debugPrint('Method channel not available for checking AccessibilityService');
      return false;
    } catch (e) {
      debugPrint('Error checking AccessibilityService: $e');
      return false;
    }
  }

  /// Opens Accessibility settings to enable the service.
  /// Uses method channel first, with fallback to permission_handler.
  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) {
      debugPrint('Not on Android, cannot open Accessibility settings');
      return;
    }

    try {
      // Try method channel first (works in main app)
      await _channel.invokeMethod('openAccessibilitySettings');
      debugPrint('Successfully opened Accessibility settings via method channel');
      return;
    } on MissingPluginException {
      // Method channel not available (e.g., in overlay or after hot reload)
      debugPrint('Method channel not available, using permission_handler fallback');
      await _openAccessibilitySettingsFallback();
    } on PlatformException catch (e) {
      // Method channel failed, try fallback
      debugPrint('Method channel failed: ${e.message}, using fallback');
      await _openAccessibilitySettingsFallback();
    } catch (e) {
      debugPrint('Unexpected error opening Accessibility settings: $e');
      // Last resort: try fallback
      await _openAccessibilitySettingsFallback();
    }
  }

  /// Fallback: Opens app settings using permission_handler.
  /// This works from any context (main app or overlay).
  /// Note: This opens general app settings, not specifically Accessibility settings.
  /// User will need to navigate to Accessibility from there.
  Future<void> _openAccessibilitySettingsFallback() async {
    try {
      // Open app settings - user can navigate to Accessibility from there
      final opened = await openAppSettings();
      if (opened) {
        debugPrint('Opened app settings successfully');
      } else {
        debugPrint('Failed to open app settings');
      }
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }
}

