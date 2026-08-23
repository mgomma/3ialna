import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/domain/services/prayer_calculation_method_policy.dart';

void main() {
  group('PrayerCalculationMethodPolicy', () {
    test('selects Umm al-Qura for Middle Eastern country codes', () {
      expect(
        PrayerCalculationMethodPolicy.forLocation(countryCode: 'SA'),
        PrayerCalculationMethodPolicy.ummAlQura,
      );
      expect(
        PrayerCalculationMethodPolicy.forLocation(countryCode: 'AE'),
        PrayerCalculationMethodPolicy.ummAlQura,
      );
    });

    test('selects ISNA for North American country codes', () {
      expect(
        PrayerCalculationMethodPolicy.forLocation(countryCode: 'US'),
        PrayerCalculationMethodPolicy.northAmerica,
      );
      expect(
        PrayerCalculationMethodPolicy.forLocation(countryCode: 'CA'),
        PrayerCalculationMethodPolicy.northAmerica,
      );
    });

    test('uses coordinate regions when country code is unavailable', () {
      expect(
        PrayerCalculationMethodPolicy.forLocation(latitude: 24.7, longitude: 46.7),
        PrayerCalculationMethodPolicy.ummAlQura,
      );
      expect(
        PrayerCalculationMethodPolicy.forLocation(latitude: 40.7, longitude: -74.0),
        PrayerCalculationMethodPolicy.northAmerica,
      );
    });

    test('country code takes precedence over broad coordinate fallback', () {
      expect(
        PrayerCalculationMethodPolicy.forLocation(
          countryCode: 'US',
          latitude: 24.7,
          longitude: 46.7,
        ),
        PrayerCalculationMethodPolicy.northAmerica,
      );
    });

    test('falls back to Umm al-Qura when location is unavailable', () {
      expect(
        PrayerCalculationMethodPolicy.forLocation(),
        PrayerCalculationMethodPolicy.fallback,
      );
    });
  });
}
