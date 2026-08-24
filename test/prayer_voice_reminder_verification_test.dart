import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/prayer_voice_reminder_verification.dart';

void main() {
  test('schedules verification exactly one minute after the parent starts it', () {
    final DateTime now = DateTime(2026, 8, 24, 9, 30, 15);

    expect(
      PrayerVoiceReminderVerification.scheduledAt(now),
      DateTime(2026, 8, 24, 9, 31, 15),
    );
  });

  test('requires both a local recording and the platform permission', () {
    expect(
      PrayerVoiceReminderVerification.canSchedule(
        hasRecording: true,
        platformPermissionGranted: true,
      ),
      isTrue,
    );
    expect(
      PrayerVoiceReminderVerification.canSchedule(
        hasRecording: false,
        platformPermissionGranted: true,
      ),
      isFalse,
    );
    expect(
      PrayerVoiceReminderVerification.canSchedule(
        hasRecording: true,
        platformPermissionGranted: false,
      ),
      isFalse,
    );
  });
}
