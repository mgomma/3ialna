/// Pure timing and readiness rules for the parent-run reminder verification.
class PrayerVoiceReminderVerification {
  PrayerVoiceReminderVerification._();

  static const Duration testDelay = Duration(minutes: 1);

  /// Gives the parent time to lock the device before the local test fires.
  static DateTime scheduledAt(DateTime now) => now.add(testDelay);

  /// Android requires exact-alarm access for native on-time playback. iPhone
  /// uses its local-notification permission instead.
  static bool canSchedule({
    required bool hasRecording,
    required bool platformPermissionGranted,
  }) =>
      hasRecording && platformPermissionGranted;
}
