import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/domain/models/prayer.dart';
import 'package:mu_super_app/domain/models/prayer_lock_settings.dart';
import 'package:mu_super_app/domain/validation/country_mobile_phone_validator.dart';

void main() {
  test('normalizes a Saudi local mobile number into the selected calling code', () {
    final CountryMobilePhoneValidation result =
        CountryMobilePhoneValidator.validate(
      country: 'Saudi Arabia',
      input: '050 123 4567',
    );

    expect(result.isValid, isTrue);
    expect(result.e164, '+966501234567');
  });

  test('accepts Arabic-Indic digits and a matching country calling code', () {
    final CountryMobilePhoneValidation result =
        CountryMobilePhoneValidator.validate(
      country: 'Egypt',
      input: '+٢٠ ١٠١٢٣٤٥٦٧٨',
    );

    expect(result.isValid, isTrue);
    expect(result.e164, '+201012345678');
  });

  test('rejects a valid-looking mobile number with another country calling code', () {
    final CountryMobilePhoneValidation result =
        CountryMobilePhoneValidator.validate(
      country: 'UAE',
      input: '+966501234567',
    );

    expect(result.isValid, isFalse);
    expect(result.error, 'countryCode');
  });

  test('uses a 15-minute Arabic-first prayer-lock default', () {
    final PrayerLockSettings settings = PrayerLockSettings.defaults();

    expect(settings.getLockDuration(Prayer.fajr, DateTime(2026, 8, 24)), 15);
    expect(settings.getLockDuration(Prayer.dhuhr, DateTime(2026, 8, 28)), 15);
    expect(settings.notificationMessages[Prayer.fajr], contains('اقترب وقت صلاة الفجر'));
    expect(settings.notificationMessages[Prayer.fajr], contains('سيُقفل الجهاز'));
  });
}
