import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../models/child_device_model.dart';

class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  // Prayer calculation parameters
  final CalculationParameters _calculationParams = CalculationParameters(
    method: CalculationMethod.muslim_world_league,
    fajrAngle: 18.0,
    ishaAngle: 17.0,
  );

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate prayer times for a specific date and location
  List<PrayerTime> calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    PrayerSettings? settings,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final prayerTimes = PrayerTimes.today(coordinates, _calculationParams);

    return [
      PrayerTime(
        name: 'fajr',
        time: prayerTimes.fajr,
        isLocked: settings?.isEnabled ?? true,
        lockDurationMinutes: settings?.fajrLockMinutes ?? 20,
      ),
      PrayerTime(
        name: 'dhuhr',
        time: prayerTimes.dhuhr,
        isLocked: settings?.isEnabled ?? true,
        lockDurationMinutes: _getDhuhrLockDuration(prayerTimes.dhuhr, settings),
      ),
      PrayerTime(
        name: 'asr',
        time: prayerTimes.asr,
        isLocked: settings?.isEnabled ?? true,
        lockDurationMinutes: settings?.asrLockMinutes ?? 15,
      ),
      PrayerTime(
        name: 'maghrib',
        time: prayerTimes.maghrib,
        isLocked: settings?.isEnabled ?? true,
        lockDurationMinutes: settings?.maghribLockMinutes ?? 20,
      ),
      PrayerTime(
        name: 'isha',
        time: prayerTimes.isha,
        isLocked: settings?.isEnabled ?? true,
        lockDurationMinutes: settings?.ishaLockMinutes ?? 25,
      ),
    ];
  }

  // Get Dhuhr lock duration (special rule for Friday)
  int _getDhuhrLockDuration(DateTime dhuhrTime, PrayerSettings? settings) {
    if (settings == null) return 15;
    
    // Check if it's Friday
    if (dhuhrTime.weekday == DateTime.friday) {
      return settings.fridayDhuhrLockMinutes;
    }
    
    return settings.dhuhrLockMinutes;
  }

  // Get next prayer time
  PrayerTime? getNextPrayerTime({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
  }) {
    final prayerTimes = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
      settings: settings,
    );

    final now = DateTime.now();
    
    for (final prayerTime in prayerTimes) {
      if (prayerTime.time.isAfter(now)) {
        return prayerTime;
      }
    }

    // If no prayer time is found for today, get the first prayer of tomorrow
    final tomorrowPrayerTimes = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now().add(const Duration(days: 1)),
      settings: settings,
    );

    return tomorrowPrayerTimes.isNotEmpty ? tomorrowPrayerTimes.first : null;
  }

  // Lock window: returns start and end DateTime for lock period (5 minutes before to 5 minutes after prayer)
  Map<String, DateTime> getLockWindow(DateTime prayerTime) {
    final start = prayerTime.subtract(const Duration(minutes: 5));
    final end = prayerTime.add(const Duration(minutes: 5));
    return {'start': start, 'end': end};
  }

  // Check if current time is inside the lock window for a given prayer
  bool isInPrayerLockWindow(PrayerTime prayerTime) {
    final now = DateTime.now();
    final window = getLockWindow(prayerTime.time);
    return now.isAfter(window['start']!) && now.isBefore(window['end']!);
  }

  // Returns true if device should be locked now for the 5-min before/after rule
  bool shouldLockForPrayerWindow({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
  }) {
    final prayerTimes = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
      settings: settings,
    );

    for (final prayerTime in prayerTimes) {
      if (isInPrayerLockWindow(prayerTime)) return true;
    }

    return false;
  }

  // Provide a stream that periodically checks prayer lock state and emits true (lock) / false (unlock)
  Stream<bool> lockStateStream({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
    Duration interval = const Duration(seconds: 30),
  }) {
    late StreamController<bool> controller;
    Timer? timer;

    controller = StreamController<bool>(
      onListen: () {
        // Emit initial state
        final locked = shouldLockForPrayerWindow(
          latitude: latitude,
          longitude: longitude,
          settings: settings,
        );
        controller.add(locked);

        timer = Timer.periodic(interval, (_) {
          final locked = shouldLockForPrayerWindow(
            latitude: latitude,
            longitude: longitude,
            settings: settings,
          );
          if (!controller.isClosed) controller.add(locked);
        });
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  // Check if device should be locked for prayer
  bool shouldLockForPrayer({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
  }) {
    if (settings == null || !settings.isEnabled) return false;

    final now = DateTime.now();
    final prayerTimes = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: now,
      settings: settings,
    );

    for (final prayerTime in prayerTimes) {
      if (prayerTime.isLocked) {
        final prayerStart = prayerTime.time;
        final prayerEnd = prayerStart.add(Duration(minutes: prayerTime.lockDurationMinutes));
        
        if (now.isAfter(prayerStart) && now.isBefore(prayerEnd)) {
          return true;
        }
      }
    }

    return false;
  }

  // Get time until next prayer
  Duration? getTimeUntilNextPrayer({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
  }) {
    final nextPrayer = getNextPrayerTime(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
    );

    if (nextPrayer != null) {
      return nextPrayer.time.difference(DateTime.now());
    }

    return null;
  }

  // Get notification time (2 minutes before prayer)
  DateTime? getNotificationTime({
    required double latitude,
    required double longitude,
    PrayerSettings? settings,
  }) {
    final nextPrayer = getNextPrayerTime(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
    );

    if (nextPrayer != null) {
      return nextPrayer.time.subtract(const Duration(minutes: 2));
    }

    return null;
  }

  // Format prayer time for display
  String formatPrayerTime(DateTime time, String language) {
    final hour = time.hour;
    final minute = time.minute;
    
    if (language == 'ar') {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }
  }

  // Get prayer name in Arabic or English
  String getPrayerName(String prayerName, String language) {
    final prayerNames = {
      'ar': {
        'fajr': 'الفجر',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
        'maghrib': 'المغرب',
        'isha': 'العشاء',
      },
      'en': {
        'fajr': 'Fajr',
        'dhuhr': 'Dhuhr',
        'asr': 'Asr',
        'maghrib': 'Maghrib',
        'isha': 'Isha',
      },
    };

    return prayerNames[language]?[prayerName] ?? prayerName;
  }

  // Get dua message for prayer time
  String getPrayerDua(String language) {
    if (language == 'ar') {
      return 'وقت الصلاة، دعاء قبل الإغلاق';
    } else {
      return 'Prayer time, dua before lock';
    }
  }
}
