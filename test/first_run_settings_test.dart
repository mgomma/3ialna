import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('enables prayer locks by default for a new local settings store', () async {
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    expect(settings.loadPrayerLockSettings().enabled, isTrue);
  });

  test('uses the default-on value for an older prayer record missing enabled',
      () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'prayer_lock_settings',
      jsonEncode(<String, Object>{'calculationMethod': 'makkah'}),
    );

    expect(SettingsService(prefs).loadPrayerLockSettings().enabled, isTrue);
  });

  test('preserves an explicit parent choice to disable prayer locking',
      () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'prayer_lock_settings',
      jsonEncode(<String, Object>{'enabled': false}),
    );

    expect(SettingsService(prefs).loadPrayerLockSettings().enabled, isFalse);
  });

  test('persists country profile and essential onboarding completion immediately',
      () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsService settings = SettingsService(prefs);

    await settings.setSelectedCountry('Egypt');
    await settings.setEssentialPermissionsPrompted();

    final SettingsService reloaded = SettingsService(prefs);
    expect(reloaded.selectedCountry, 'Egypt');
    expect(reloaded.countryWordProfile?.welcomeWord, 'اهلا');
    expect(reloaded.essentialPermissionsPrompted, isTrue);
  });
}
