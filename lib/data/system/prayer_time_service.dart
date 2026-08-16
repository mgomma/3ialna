import 'package:adhan_dart/adhan_dart.dart' hide Prayer;

import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';

/// Service for calculating prayer times.
class PrayerTimeService {
  const PrayerTimeService();

  /// Constructs CalculationParameters from method name using known values.
  CalculationParameters _constructParamsFromMethodName(String methodName) {
    final CalculationMethod calcMethod = switch (methodName) {
      'muslim_world_league' => CalculationMethod.muslimWorldLeague,
      'egyptian' => CalculationMethod.egyptian,
      'karachi' => CalculationMethod.karachi,
      'makkah' => CalculationMethod.muslimWorldLeague,
      'isna' => CalculationMethod.northAmerica,
      _ => CalculationMethod.muslimWorldLeague,
    };
    
    // Get angle values from the method (these are standard values)
    final Map<String, ({double fajr, double isha})> methodAngles = {
      'muslim_world_league': (fajr: 18.0, isha: 17.0),
      'egyptian': (fajr: 19.5, isha: 17.5),
      'karachi': (fajr: 18.0, isha: 18.0),
      'makkah': (fajr: 18.5, isha: 19.0),
      'isna': (fajr: 15.0, isha: 15.0),
    };
    
    final angles = methodAngles[methodName] ?? methodAngles['muslim_world_league']!;
    
    return CalculationParameters(
      method: calcMethod,
      fajrAngle: angles.fajr,
      ishaAngle: angles.isha,
    );
  }


  /// Calculates prayer times for a given date and settings.
  ///
  /// Returns a map of prayer to DateTime, or null if location is not set.
  Map<Prayer, DateTime>? calculatePrayerTimes(
    DateTime date,
    PrayerLockSettings settings,
  ) {
    if (settings.latitude == null ||
        settings.longitude == null) {
      return null;
    }

    final Coordinates coordinates = Coordinates(
      settings.latitude!,
      settings.longitude!,
    );

    // Get CalculationMethod and convert to CalculationParameters
    // Since CalculationMethod cannot be directly cast, we'll use dynamic
    // to access properties and construct CalculationParameters manually
    final dynamic method = switch (settings.calculationMethodName) {
      'muslim_world_league' => CalculationMethod.muslimWorldLeague,
      'egyptian' => CalculationMethod.egyptian,
      'karachi' => CalculationMethod.karachi,
      'makkah' => CalculationMethod.muslimWorldLeague,
      'isna' => CalculationMethod.northAmerica,
      _ => CalculationMethod.muslimWorldLeague,
    };

    // Try to construct CalculationParameters from the method's properties
    // Access properties dynamically since we don't know the exact structure
    CalculationParameters params;
    try {
      // Try accessing properties directly
      final double? fajrAngle = (method as dynamic).fajrAngle as double?;
      final double? ishaAngle = (method as dynamic).ishaAngle as double?;
      
      if (fajrAngle != null && ishaAngle != null) {
        // Use the method itself as the method parameter
        params = CalculationParameters(
          method: method as CalculationMethod,
          fajrAngle: fajrAngle,
          ishaAngle: ishaAngle,
        );
      } else {
        // Fallback: use known values for each method
        params = _constructParamsFromMethodName(settings.calculationMethodName);
      }
    } catch (e) {
      // If dynamic access fails, use method name to construct
      params = _constructParamsFromMethodName(settings.calculationMethodName);
    }

    final PrayerTimes prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
    );

    // Ensure prayer times are in local timezone
    final DateTime fajr = prayerTimes.fajr.toLocal();
    final DateTime dhuhr = prayerTimes.dhuhr.toLocal();
    final DateTime asr = prayerTimes.asr.toLocal();
    final DateTime maghrib = prayerTimes.maghrib.toLocal();
    final DateTime isha = prayerTimes.isha.toLocal();

    return {
      Prayer.fajr: fajr,
      Prayer.dhuhr: dhuhr,
      Prayer.asr: asr,
      Prayer.maghrib: maghrib,
      Prayer.isha: isha,
    };
  }

  /// Gets the next prayer time from now.
  ///
  /// Returns the prayer and its time, or null if no prayer times are available.
  ({Prayer prayer, DateTime time})? getNextPrayer(
    PrayerLockSettings settings,
  ) {
    final DateTime now = DateTime.now();
    final Map<Prayer, DateTime>? times =
        calculatePrayerTimes(now, settings);

    if (times == null) {
      return null;
    }

    Prayer? nextPrayer;
    DateTime? nextTime;

    for (final MapEntry<Prayer, DateTime> entry
        in times.entries) {
      if (entry.value.isAfter(now)) {
        if (nextTime == null || entry.value.isBefore(nextTime)) {
          nextTime = entry.value;
          nextPrayer = entry.key;
        }
      }
    }

    // If no prayer is found today, get the first prayer tomorrow
    if (nextPrayer == null || nextTime == null) {
      final DateTime tomorrow = now.add(const Duration(days: 1));
      final Map<Prayer, DateTime>? tomorrowTimes =
          calculatePrayerTimes(tomorrow, settings);
      if (tomorrowTimes != null && tomorrowTimes.isNotEmpty) {
        final Prayer firstPrayer = tomorrowTimes.keys.first;
        nextTime = tomorrowTimes[firstPrayer];
        nextPrayer = firstPrayer;
      } else {
        return null;
      }
    }

    if (nextTime == null) {
      return null;
    }
    return (prayer: nextPrayer, time: nextTime);
  }
}

