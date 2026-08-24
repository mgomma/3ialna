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

  test('releases only a prayer-owned overlay when its lock expires', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'overlay_app_name': 'Prayer Time Lock - Dhuhr',
      'overlay_used_minutes': 0,
      'overlay_limit_minutes': 30,
      'is_device_locked': true,
      'prayer_lock_active_name': 'Dhuhr',
      'prayer_lock_active_start': '1',
      'prayer_lock_active_end': '2',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsService settings = SettingsService(prefs);

    expect(
      await settings.releasePrayerOverlayIfOwned(prayerName: 'Dhuhr'),
      isTrue,
    );
    expect(settings.isDeviceLocked, isFalse);
    expect(settings.activePrayerLockName, isNull);
    expect(settings.loadOverlayData().appName, 'Social App');
  });

  test('does not clear an unrelated app-limit overlay at prayer expiry',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'overlay_app_name': 'TikTok',
      'overlay_used_minutes': 30,
      'overlay_limit_minutes': 30,
      'is_device_locked': true,
      'prayer_lock_active_name': 'Dhuhr',
      'prayer_lock_active_start': '1',
      'prayer_lock_active_end': '2',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsService settings = SettingsService(prefs);

    expect(
      await settings.releasePrayerOverlayIfOwned(prayerName: 'Dhuhr'),
      isFalse,
    );
    expect(settings.isDeviceLocked, isTrue);
    expect(settings.loadOverlayData().appName, 'TikTok');
  });
}
