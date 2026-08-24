import 'prayer.dart';

/// Settings for prayer time-based locks.
class PrayerLockSettings {
  const PrayerLockSettings({
    required this.enabled,
    required this.lockDurations,
    required this.fridayDhuhrDuration,
    required this.calculationMethodName,
    required this.notificationMessages,
    this.voiceNotificationsEnabled = true,
    this.latitude,
    this.longitude,
  });

  /// Whether prayer locks are enabled.
  final bool enabled;

  /// Lock duration in minutes for each prayer.
  final Map<Prayer, int> lockDurations;

  /// Special lock duration for Friday Dhuhr in minutes.
  final int fridayDhuhrDuration;

  /// Calculation method name for prayer times (stored as string to avoid type issues).
  final String calculationMethodName;
  

  /// Custom notification messages for each prayer.
  final Map<Prayer, String> notificationMessages;

  /// Whether the written prayer message should also be spoken aloud.
  final bool voiceNotificationsEnabled;

  /// Latitude coordinate for prayer time calculations.
  final double? latitude;

  /// Longitude coordinate for prayer time calculations.
  final double? longitude;

  /// Returns the lock duration for a specific prayer, considering Friday rules.
  int getLockDuration(Prayer prayer, DateTime date) {
    if (prayer == Prayer.dhuhr && _isFriday(date)) {
      return fridayDhuhrDuration;
    }
    return lockDurations[prayer] ?? 30;
  }

  /// Checks if the given date is a Friday.
  bool _isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }

  /// Creates a copy with updated values.
  PrayerLockSettings copyWith({
    bool? enabled,
    Map<Prayer, int>? lockDurations,
    int? fridayDhuhrDuration,
    String? calculationMethodName,
    Map<Prayer, String>? notificationMessages,
    bool? voiceNotificationsEnabled,
    double? latitude,
    double? longitude,
  }) {
    return PrayerLockSettings(
      enabled: enabled ?? this.enabled,
      lockDurations: lockDurations ?? this.lockDurations,
      fridayDhuhrDuration:
          fridayDhuhrDuration ?? this.fridayDhuhrDuration,
      calculationMethodName:
          calculationMethodName ?? this.calculationMethodName,
      notificationMessages:
          notificationMessages ?? this.notificationMessages,
      voiceNotificationsEnabled:
          voiceNotificationsEnabled ?? this.voiceNotificationsEnabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Creates default settings.
  factory PrayerLockSettings.defaults() {
    const int defaultDuration = 30;
    return PrayerLockSettings(
      enabled: true,
      lockDurations: {
        Prayer.fajr: defaultDuration,
        Prayer.dhuhr: defaultDuration,
        Prayer.asr: defaultDuration,
        Prayer.maghrib: defaultDuration,
        Prayer.isha: defaultDuration,
      },
      fridayDhuhrDuration: defaultDuration,
      calculationMethodName: 'makkah',
      notificationMessages: {
        Prayer.fajr: 'Fajr prayer time is approaching. '
            'Your device will be locked in 2 minutes.',
        Prayer.dhuhr: 'Dhuhr prayer time is approaching. '
            'Your device will be locked in 2 minutes.',
        Prayer.asr: 'Asr prayer time is approaching. '
            'Your device will be locked in 2 minutes.',
        Prayer.maghrib: 'Maghrib prayer time is approaching. '
            'Your device will be locked in 2 minutes.',
        Prayer.isha: 'Isha prayer time is approaching. '
            'Your device will be locked in 2 minutes.',
      },
    );
  }
}
