import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// A notification action that opens 3ialna and plays a locally stored parent
/// recording. Its generic notification copy avoids exposing a task label on a
/// child device's lock screen.
class VoiceReminderAction {
  const VoiceReminderAction({
    required this.kind,
    required this.recordingKey,
  });

  static const String playActionId = 'play_parent_voice';

  final String kind;
  final String recordingKey;

  String get payload => 'voice-reminder-v1|$kind|$recordingKey';

  static VoiceReminderAction? tryParse(String? payload) {
    if (payload == null) return null;
    final List<String> parts = payload.split('|');
    if (parts.length != 3 || parts.first != 'voice-reminder-v1') return null;
    final String kind = parts[1];
    final String recordingKey = parts[2];
    if ((kind != 'task' && kind != 'prayer') || recordingKey.isEmpty) return null;
    return VoiceReminderAction(kind: kind, recordingKey: recordingKey);
  }
}

/// Shared local-notification gateway for prayers and parent task reminders.
class NotificationService {
  NotificationService._();

  factory NotificationService() => instance;

  static final NotificationService instance = NotificationService._();
  static const int _taskReminderBaseId = 20000;
  static const int _notificationIdsPerTaskSlot = 24;
  static const String _voiceReminderCategory = 'parent_voice_reminder';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<VoiceReminderAction> _voiceActions =
      StreamController<VoiceReminderAction>.broadcast();

  VoiceReminderAction? _pendingVoiceAction;
  bool _initialized = false;

  Stream<VoiceReminderAction> get voiceActions => _voiceActions.stream;

  VoiceReminderAction? takePendingVoiceAction() {
    final VoiceReminderAction? action = _pendingVoiceAction;
    _pendingVoiceAction = null;
    return action;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _voiceReminderCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              VoiceReminderAction.playActionId,
              'Play parent voice',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    await _notifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    final NotificationAppLaunchDetails? launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    final NotificationResponse? launchResponse = launchDetails?.notificationResponse;
    if ((launchDetails?.didNotificationLaunchApp ?? false) && launchResponse != null) {
      _handleNotificationResponse(launchResponse);
    }
    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final VoiceReminderAction? action =
        VoiceReminderAction.tryParse(response.payload);
    if (action == null) return;
    _pendingVoiceAction = action;
    _voiceActions.add(action);
  }

  Future<bool> hasNotificationPermission() async {
    if (await Permission.notification.isDenied) return false;
    return Permission.notification.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> _ensurePermission() async {
    if (await hasNotificationPermission()) return true;
    return requestNotificationPermission();
  }

  /// Retains the existing prayer-notification scheduling behavior.
  Future<int?> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    VoiceReminderAction? voiceAction,
  }) async {
    try {
      if (!await _ensurePermission()) {
        developer.log('Notification permission denied', name: '3ialna.notification');
        return null;
      }
      await initialize();
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        _notificationDetails(withVoiceAction: voiceAction != null),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: voiceAction?.payload,
      );
      return id;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to schedule notification',
        name: '3ialna.notification',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Creates daily clock-time occurrences at every one or two hours. This
  /// survives app closure without requiring automatic background audio.
  Future<bool> scheduleVoiceReminder({
    required int notificationSlot,
    required int repeatHours,
    required VoiceReminderAction action,
  }) async {
    if (notificationSlot < 0 || (repeatHours != 1 && repeatHours != 2)) return false;
    try {
      if (!await _ensurePermission()) return false;
      await initialize();
      await cancelVoiceReminder(notificationSlot);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final int firstHour = (now.hour + 1) % 24;
      for (int offset = 0; offset < 24; offset += repeatHours) {
        final int hour = (firstHour + offset) % 24;
        tz.TZDateTime scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
        );
        if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
        await _notifications.zonedSchedule(
          _taskReminderBaseId + notificationSlot * _notificationIdsPerTaskSlot + offset,
          '3ialna reminder',
          'Open 3ialna to play the parent voice note.',
          scheduled,
          _notificationDetails(withVoiceAction: true),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: action.payload,
        );
      }
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to schedule repeating voice reminder',
        name: '3ialna.notification',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  Future<void> cancelVoiceReminder(int notificationSlot) async {
    if (notificationSlot < 0) return;
    try {
      await initialize();
      for (int offset = 0; offset < _notificationIdsPerTaskSlot; offset++) {
        await _notifications.cancel(
          _taskReminderBaseId + notificationSlot * _notificationIdsPerTaskSlot + offset,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to cancel repeating voice reminder',
        name: '3ialna.notification',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await initialize();
      await _notifications.cancel(id);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to cancel notification',
        name: '3ialna.notification',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  NotificationDetails _notificationDetails({required bool withVoiceAction}) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      withVoiceAction ? 'parent_voice_reminders' : 'prayer_lock_channel',
      withVoiceAction ? 'Parent voice reminders' : 'Prayer Lock Notifications',
      channelDescription: withVoiceAction
          ? 'Parent-controlled reminders that open 3ialna to play a local voice note'
          : 'Notifications for prayer time locks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: withVoiceAction
          ? const <AndroidNotificationAction>[
              AndroidNotificationAction(
                VoiceReminderAction.playActionId,
                'Play parent voice',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ]
          : const <AndroidNotificationAction>[],
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: withVoiceAction ? _voiceReminderCategory : null,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) =>
      tz.TZDateTime.from(dateTime, tz.local);
}
