import 'dart:async';
import 'dart:developer' as developer;

import '../../data/local/settings_service.dart';
import '../../domain/models/overlay_data.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import 'notification_service.dart';
import 'parent_voice_notification_service.dart';
import 'overlay_service.dart';
import 'ios_screen_time_safeguard_service.dart';
import 'prayer_time_service.dart';
import 'prayer_voice_reminder_schedule.dart';

  /// Scheduler that manages prayer time locks and notifications.
class PrayerLockScheduler {
  PrayerLockScheduler({
    required PrayerTimeService prayerTimeService,
    required NotificationService notificationService,
    required OverlayService overlayService,
    SettingsService? settingsService,
  })  : _prayerTimeService = prayerTimeService,
        _notificationService = notificationService,
        _overlayService = overlayService,
        _settingsService = settingsService;

  final PrayerTimeService _prayerTimeService;
  final NotificationService _notificationService;
  final OverlayService _overlayService;
  final SettingsService? _settingsService;

  Timer? _monitoringTimer;
  Timer? _checkTimer;
  bool _isActive = false;
  PrayerLockSettings? _currentSettings;
  final Map<Prayer, Timer> _activeLocks = {};

  /// Starts the scheduler with the given settings.
  Future<void> start(PrayerLockSettings settings) async {
    if (!settings.enabled) {
      await stop(cancelBackgroundPrayerVoice: true);
      return;
    }

    if (settings.latitude == null ||
        settings.longitude == null) {
      developer.log(
        'Cannot start prayer lock scheduler: location not set',
        name: 'prayer_lock.scheduler',
      );
      return;
    }

    _currentSettings = settings;
    _isActive = true;

    await _scheduleLocksAndNotifications(settings);
    _startMonitoring();
    _startContinuousChecking(settings);
  }

  /// Stops the scheduler and cancels all scheduled locks and notifications.
  Future<void> stop({bool cancelBackgroundPrayerVoice = false}) async {
    _isActive = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _checkTimer?.cancel();
    _checkTimer = null;
    for (final Timer timer in _activeLocks.values) {
      timer.cancel();
    }
    _activeLocks.clear();
    for (final Prayer prayer in Prayer.values) {
      await _notificationService.cancelNotification(_getNotificationId(prayer));
    }
    if (cancelBackgroundPrayerVoice) {
      await ParentVoiceNotificationService(
        recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
      ).cancelPrayerBackgroundPlayback();
    }
    await _releasePrayerOverlay();
    await IosScreenTimeSafeguardService().clearPrayerShields();
    _currentSettings = null;
  }

  /// Schedules locks and notifications for all prayers.
  Future<void> _scheduleLocksAndNotifications(
    PrayerLockSettings settings,
  ) async {
    final DateTime now = DateTime.now();
    final Map<Prayer, DateTime>? prayerTimes =
        _prayerTimeService.calculatePrayerTimes(now, settings);

    if (prayerTimes == null) {
      return;
    }

    await IosScreenTimeSafeguardService().schedulePrayerShields(
      prayerTimes.entries
          .where((MapEntry<Prayer, DateTime> entry) => entry.value.isAfter(now))
          .map((MapEntry<Prayer, DateTime> entry) {
        final DateTime end = entry.value.add(Duration(
          minutes: settings.getLockDuration(entry.key, entry.value),
        ));
        return <String, String>{
          'id': entry.key.name,
          'start': entry.value.toIso8601String(),
          'end': end.toIso8601String(),
        };
      }).toList(growable: false),
    );

    // Cancel only prayer notifications. Parent task reminders use a separate ID range.
    for (final Prayer prayer in Prayer.values) {
      await _notificationService.cancelNotification(_getNotificationId(prayer));
    }

    final ParentVoiceNotificationService prayerVoiceService =
        ParentVoiceNotificationService(
      recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
    );
    await prayerVoiceService.cancelPrayerBackgroundPlayback();
    bool automaticVoiceScheduled = false;
    if (settings.voiceNotificationsEnabled) {
      automaticVoiceScheduled = await prayerVoiceService
          .schedulePrayerBackgroundPlayback(
        PrayerVoiceReminderSchedule.upcomingTimes(
          prayerTimeService: _prayerTimeService,
          settings: settings,
          now: now,
        ),
      );
    }
    await prayerVoiceService.dispose();

    // First, check if we're currently in a lock period and save it immediately
    bool foundActiveLock = false;
    for (final MapEntry<Prayer, DateTime> entry in prayerTimes.entries) {
      final Prayer prayer = entry.key;
      final DateTime prayerTime = entry.value;
      final int lockDuration = settings.getLockDuration(prayer, prayerTime);
      final DateTime lockEndTime = prayerTime.add(Duration(minutes: lockDuration));

      // Check if we're currently in this lock period
      if (now.isAfter(prayerTime) && now.isBefore(lockEndTime)) {
        // We're in this lock period - save it immediately for Android service
        if (_settingsService != null) {
          await _settingsService.saveActivePrayerLockPeriod(
            prayerName: prayer.displayName,
            lockStart: prayerTime,
            lockEnd: lockEndTime,
          );
          developer.log(
            'Saved active prayer lock period: ${prayer.displayName} until $lockEndTime',
            name: 'prayer_lock.scheduler',
          );
        }
        foundActiveLock = true;
        break; // Only one prayer can be active at a time
      }
    }
    
    // If not in an active lock, clear any old data
    if (!foundActiveLock && _settingsService != null) {
      await _settingsService.clearActivePrayerLockPeriod();
    }

    for (final MapEntry<Prayer, DateTime> entry
        in prayerTimes.entries) {
      final Prayer prayer = entry.key;
      final DateTime prayerTime = entry.value;

      // Schedule notification 2 minutes before prayer
      final DateTime notificationTime =
          prayerTime.subtract(const Duration(minutes: 2));

      if (notificationTime.isAfter(now)) {
        final String message = settings.notificationMessages[prayer] ??
            PrayerLockSettings.defaultNotificationMessage(prayer);

        await _notificationService.scheduleNotification(
          id: _getNotificationId(prayer),
          title: 'وقت صلاة ${prayer.arabicDisplayName}',
          body: message,
          scheduledDate: notificationTime,
          voiceAction: settings.voiceNotificationsEnabled
              ? const VoiceReminderAction(
                  kind: 'prayer',
                  recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
                )
              : null,
          silent: automaticVoiceScheduled,
        );
      }

      // Schedule lock at prayer time
      if (prayerTime.isAfter(now)) {
        _scheduleLock(prayer, prayerTime, settings);
      }
    }
  }

  /// Schedules a lock for a specific prayer time.
  void _scheduleLock(
    Prayer prayer,
    DateTime lockTime,
    PrayerLockSettings settings,
  ) {
    final Duration delay = lockTime.difference(DateTime.now());

    if (delay.isNegative) {
      // Prayer time has passed, but check if we're still in lock period
      final int durationMinutes = settings.getLockDuration(prayer, lockTime);
      final DateTime lockEndTime = lockTime.add(Duration(minutes: durationMinutes));
      if (DateTime.now().isBefore(lockEndTime)) {
        // Still in lock period, show immediately
        _showPrayerLock(prayer, settings).then((_) {
          // Save active lock period for Android background service
          if (_settingsService != null) {
            _settingsService.saveActivePrayerLockPeriod(
              prayerName: prayer.displayName,
              lockStart: lockTime,
              lockEnd: lockEndTime,
            );
          }
        });
        
        final Duration remaining = lockEndTime.difference(DateTime.now());
        if (remaining.inMilliseconds > 0) {
          _activeLocks[prayer] = Timer(remaining, () {
            unawaited(_releasePrayerOverlay(prayer));
          });
        }
      }
      return;
    }

    _activeLocks[prayer] = Timer(delay, () {
      if (!_isActive) {
        return;
      }

      // Show lock and save active period (async operations)
      _showPrayerLock(prayer, settings).then((_) {
        // Save active lock period for Android background service
        final int durationMinutes =
            settings.getLockDuration(prayer, lockTime);
        final DateTime lockEndTime = lockTime.add(Duration(minutes: durationMinutes));
        
        if (_settingsService != null) {
          _settingsService.saveActivePrayerLockPeriod(
            prayerName: prayer.displayName,
            lockStart: lockTime,
            lockEnd: lockEndTime,
          );
        }

        // Schedule unlock after duration
        _activeLocks[prayer] = Timer(
          Duration(minutes: durationMinutes),
          () {
            unawaited(_releasePrayerOverlay(prayer));
          },
        );
      });
    });
  }

  /// Shows the prayer lock overlay.
  Future<void> _showPrayerLock(
    Prayer prayer,
    PrayerLockSettings settings,
  ) async {
    final OverlayData data = OverlayData(
      appName: 'Prayer Time Lock',
      usedMinutes: 0,
      limitMinutes: settings.getLockDuration(
        prayer,
        DateTime.now(),
      ),
    );

    // Create a custom overlay data for prayer locks.
    await _overlayService.showLimitWarning(data);
  }

  /// Starts periodic monitoring to reschedule locks.
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) {
        if (_isActive && _currentSettings != null) {
          _scheduleLocksAndNotifications(_currentSettings!);
        }
      },
    );
  }

  /// Starts continuous checking for prayer lock periods.
  void _startContinuousChecking(PrayerLockSettings settings) {
    _checkTimer?.cancel();
    // Check every 30 seconds if we're in a prayer lock period
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!_isActive || _currentSettings == null) {
          return;
        }
        _checkAndShowLockIfNeeded(settings);
      },
    );
    
    // Also check immediately
    _checkAndShowLockIfNeeded(settings);
  }

  /// Checks if we're currently in a prayer lock period and shows overlay if needed.
  Future<void> _checkAndShowLockIfNeeded(PrayerLockSettings settings) async {
    if (settings.latitude == null || settings.longitude == null) {
      return;
    }

    final DateTime now = DateTime.now();
    final Map<Prayer, DateTime>? prayerTimes =
        _prayerTimeService.calculatePrayerTimes(now, settings);

    if (prayerTimes == null) {
      return;
    }

    // Check each prayer to see if we're in its lock period
    for (final MapEntry<Prayer, DateTime> entry in prayerTimes.entries) {
      final Prayer prayer = entry.key;
      final DateTime prayerTime = entry.value;
      final int lockDuration = settings.getLockDuration(prayer, prayerTime);
      final DateTime lockEndTime = prayerTime.add(Duration(minutes: lockDuration));

      // Check if current time is between prayer time and lock end time
      if (now.isAfter(prayerTime) && now.isBefore(lockEndTime)) {
        // We're in a lock period - show overlay if not already shown
        if (!_activeLocks.containsKey(prayer)) {
          await _showPrayerLock(prayer, settings);
          
          // Save active lock period for Android background service
          if (_settingsService != null) {
            await _settingsService.saveActivePrayerLockPeriod(
              prayerName: prayer.displayName,
              lockStart: prayerTime,
              lockEnd: lockEndTime,
            );
          }
          
          // Schedule unlock
          final Duration remaining = lockEndTime.difference(now);
          if (remaining.inMilliseconds > 0) {
            _activeLocks[prayer] = Timer(remaining, () {
              unawaited(_releasePrayerOverlay(prayer));
            });
          }
        }
        break; // Only one prayer can be active at a time
      } else if (now.isAfter(lockEndTime)) {
        // Release only this prayer's lock. Older prayer times must not dismiss
        // an unrelated social-app limit overlay.
        await _releasePrayerOverlay(prayer);
      }
    }
  }

  Future<void> _releasePrayerOverlay([Prayer? prayer]) async {
    _activeLocks.remove(prayer);
    final String? prayerName = prayer?.displayName;
    final bool shouldClose =
        await _settingsService?.releasePrayerOverlayIfOwned(
              prayerName: prayerName,
            ) ??
            true;
    if (shouldClose) {
      await _overlayService.closeOverlay();
    }
  }

  /// Gets a unique notification ID for a prayer.
  int _getNotificationId(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 1001,
      Prayer.dhuhr => 1002,
      Prayer.asr => 1003,
      Prayer.maghrib => 1004,
      Prayer.isha => 1005,
    };
  }
}
