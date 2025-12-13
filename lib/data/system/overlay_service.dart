import 'dart:developer' as developer;

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/overlay_data.dart';

/// Handles overlay permissions and showing/hiding overlay windows.
class OverlayService {
  const OverlayService();

  Future<bool> hasOverlayPermission() async {
    try {
      return FlutterOverlayWindow.isPermissionGranted();
    } catch (e, s) {
      developer.log(
        'Failed to check overlay permission',
        name: 'social_media_limiter.overlay',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return false;
    }
  }

  /// Ensures required overlay-related permissions are granted.
  Future<void> ensurePermissions() async {
    try {
      final bool overlayGranted =
          await FlutterOverlayWindow.isPermissionGranted();
      if (!overlayGranted) {
        await FlutterOverlayWindow.requestPermission();
      }

      final PermissionStatus status =
          await Permission.systemAlertWindow.status;
      if (!status.isGranted &&
          await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    } catch (e, s) {
      developer.log(
        'Failed to request overlay permissions',
        name: 'social_media_limiter.overlay',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }

  /// Shows a blocking overlay warning.
  Future<void> showLimitWarning(OverlayData data) async {
    try {
      final bool hasPermission =
          await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        developer.log(
          'Overlay permission not granted; requesting permission',
          name: 'social_media_limiter.overlay',
        );
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      developer.log(
        'Showing overlay for ${data.appName} '
        '(${data.usedMinutes}/${data.limitMinutes} minutes)',
        name: 'social_media_limiter.overlay',
      );

      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        enableDrag: false, // Overlay should not be draggable
        overlayTitle: 'Time Limit Reached',
        overlayContent:
            '${data.appName}|${data.usedMinutes}|${data.limitMinutes}',
        // Use flag that prevents interaction and dragging
        // defaultFlag should work, but we also prevent gestures in the widget
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );
    } catch (e, s) {
      developer.log(
        'Failed to show overlay',
        name: 'social_media_limiter.overlay',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }

  Future<void> closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e, s) {
      developer.log(
        'Failed to close overlay',
        name: 'social_media_limiter.overlay',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }
}


