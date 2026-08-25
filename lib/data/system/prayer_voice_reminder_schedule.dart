import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import 'prayer_time_service.dart';

/// Calculates one-shot, pre-prayer reminder times for native background
/// delivery. A one-week horizon stays below iOS's pending-notification limit.
class PrayerVoiceReminderSchedule {
  PrayerVoiceReminderSchedule._();

  static const int scheduleDays = 7;

  /// Rebuilds the upcoming native alarm plan after the device has restarted.
  static List<DateTime> refreshAfterReboot({
    required PrayerTimeService prayerTimeService,
    required PrayerLockSettings settings,
    required DateTime now,
  }) =>
      upcomingTimes(
        prayerTimeService: prayerTimeService,
        settings: settings,
        now: now,
      );

  /// Rebuilds the plan from the current local clock after the user returns to
  /// 3ialna following a device time-zone change.
  static List<DateTime> refreshAfterTimeZoneChange({
    required PrayerTimeService prayerTimeService,
    required PrayerLockSettings settings,
    required DateTime localNow,
  }) =>
      upcomingTimes(
        prayerTimeService: prayerTimeService,
        settings: settings,
        now: localNow,
      );

  static List<DateTime> upcomingTimes({
    required PrayerTimeService prayerTimeService,
    required PrayerLockSettings settings,
    required DateTime now,
    int maxItems = 35,
  }) {
    final List<DateTime> reminders = <DateTime>[];
    final DateTime firstDay = DateTime(now.year, now.month, now.day);
    for (int dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
      final Map<Prayer, DateTime>? dayPrayerTimes =
          prayerTimeService.calculatePrayerTimes(
        firstDay.add(Duration(days: dayOffset)),
        settings,
      );
      if (dayPrayerTimes == null) continue;
      for (final DateTime prayerTime in dayPrayerTimes.values) {
        final DateTime reminderTime =
            prayerTime.subtract(const Duration(minutes: 2));
        if (reminderTime.isAfter(now)) reminders.add(reminderTime);
      }
    }
    reminders.sort();
    return reminders.take(maxItems).toList(growable: false);
  }

  /// Returns future calculated prayer starts for automatic Azan playback.
  /// Unlike [upcomingTimes], no pre-prayer offset is applied.
  static List<DateTime> upcomingPrayerStartTimes({
    required PrayerTimeService prayerTimeService,
    required PrayerLockSettings settings,
    required DateTime now,
    int maxItems = 35,
  }) {
    final List<DateTime> starts = <DateTime>[];
    final DateTime firstDay = DateTime(now.year, now.month, now.day);
    for (int dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
      final Map<Prayer, DateTime>? dayPrayerTimes =
          prayerTimeService.calculatePrayerTimes(
        firstDay.add(Duration(days: dayOffset)),
        settings,
      );
      if (dayPrayerTimes == null) continue;
      starts.addAll(
        dayPrayerTimes.values.where((DateTime prayerTime) => prayerTime.isAfter(now)),
      );
    }
    starts.sort();
    return starts.take(maxItems).toList(growable: false);
  }
}
