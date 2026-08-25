import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/prayer_time_service.dart';
import 'package:mu_super_app/domain/models/prayer.dart';
import 'package:mu_super_app/domain/models/prayer_lock_settings.dart';

void main() {
  test('calculates a displayable time for every prayer-lock title', () {
    final PrayerLockSettings settings = PrayerLockSettings.defaults().copyWith(
      latitude: 24.7136,
      longitude: 46.6753,
      calculationMethodName: 'makkah',
    );

    final Map<Prayer, DateTime>? times =
        const PrayerTimeService().calculatePrayerTimes(
      DateTime(2026, 8, 25),
      settings,
    );

    expect(times, isNotNull);
    expect(times!.keys, containsAll(Prayer.values));
    for (final Prayer prayer in Prayer.values) {
      expect(times[prayer], isNotNull);
      expect(times[prayer]!.hour, inInclusiveRange(0, 23));
      expect(times[prayer]!.minute, inInclusiveRange(0, 59));
    }
  });
}
