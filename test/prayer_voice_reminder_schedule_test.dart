import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/prayer_time_service.dart';
import 'package:mu_super_app/data/system/prayer_voice_reminder_schedule.dart';
import 'package:mu_super_app/domain/models/prayer_lock_settings.dart';

void main() {
  test('builds only future prayer voice reminders across the next seven days',
      () {
    final DateTime now = DateTime(2026, 8, 24, 12);
    final PrayerLockSettings settings = PrayerLockSettings.defaults().copyWith(
      latitude: 21.3891,
      longitude: 39.8579,
    );

    final List<DateTime> reminders = PrayerVoiceReminderSchedule.upcomingTimes(
      prayerTimeService: const PrayerTimeService(),
      settings: settings,
      now: now,
    );

    expect(reminders, isNotEmpty);
    expect(reminders.length, lessThanOrEqualTo(35));
    expect(reminders.every((DateTime time) => time.isAfter(now)), isTrue);
    for (int index = 1; index < reminders.length; index++) {
      expect(reminders[index].isAfter(reminders[index - 1]), isTrue);
    }
  });
}
