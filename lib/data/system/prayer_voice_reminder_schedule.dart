import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import 'prayer_time_service.dart';

/// Calculates one-shot, pre-prayer reminder times for native background
/// delivery. A one-week horizon stays below iOS's pending-notification limit.
class PrayerVoiceReminderSchedule {
  PrayerVoiceReminderSchedule._();

  static const int scheduleDays = 7;

  static List<DateTime> upcomingTimes({
    required PrayerTimeService prayerTimeService,
    required PrayerLockSettings settings,
    required DateTime now,
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
    return reminders;
  }
}
