import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mu_super_app/data/local/settings_service.dart';
import 'package:mu_super_app/domain/models/prayer_lock_settings.dart';

void main() {
  test('persists a manually selected prayer calculation method', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsService settings = SettingsService(prefs);

    await settings.setPrayerCalculationMethodOverride('isna');
    await settings.savePrayerLockSettings(
      PrayerLockSettings.defaults().copyWith(
        calculationMethodName: 'isna',
        voiceNotificationsEnabled: false,
      ),
    );

    final SettingsService reloaded = SettingsService(prefs);
    expect(reloaded.isPrayerCalculationMethodManuallySelected, isTrue);
    expect(reloaded.prayerCalculationMethodOverride, 'isna');
    final PrayerLockSettings loaded = reloaded.loadPrayerLockSettings();
    expect(loaded.calculationMethodName, 'isna');
    expect(loaded.voiceNotificationsEnabled, isFalse);
  });
}
