import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for handling local notifications.
class NotificationService {
  NotificationService() {
    _initialize();
  }

  static const AndroidInitializationSettings
      _androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  static const DarwinInitializationSettings
      _iosInitializationSettings =
      DarwinInitializationSettings();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: _androidInitializationSettings,
      iOS: _iosInitializationSettings,
    );

    await _notifications.initialize(
      initializationSettings,
    );

    _initialized = true;
  }

  /// Checks if notification permission is granted.
  Future<bool> hasNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      return false;
    }
    return await Permission.notification.isGranted;
  }

  /// Requests notification permission.
  Future<bool> requestNotificationPermission() async {
    final PermissionStatus status =
        await Permission.notification.request();
    return status.isGranted;
  }

  /// Schedules a notification at a specific time.
  ///
  /// Returns the notification ID, or null if scheduling failed.
  Future<int?> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final bool hasPermission =
          await hasNotificationPermission();
      if (!hasPermission) {
        final bool granted =
            await requestNotificationPermission();
        if (!granted) {
          developer.log(
            'Notification permission denied',
            name: 'prayer_lock.notification',
          );
          return null;
        }
      }

      await _initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'prayer_lock_channel',
        'Prayer Lock Notifications',
        channelDescription:
            'Notifications for prayer time locks',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails();

      const NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      return id;
    } catch (e, s) {
      developer.log(
        'Failed to schedule notification',
        name: 'prayer_lock.notification',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return null;
    }
  }

  /// Cancels a scheduled notification by ID.
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e, s) {
      developer.log(
        'Failed to cancel notification',
        name: 'prayer_lock.notification',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e, s) {
      developer.log(
        'Failed to cancel all notifications',
        name: 'prayer_lock.notification',
        error: e,
        stackTrace: s,
        level: 1000,
      );
    }
  }

  /// Converts DateTime to TZDateTime for scheduling.
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}

