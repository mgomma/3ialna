import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mu_super_app/data/local/settings_service.dart';
import 'package:mu_super_app/domain/models/prayer.dart';
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
        automaticAzanEnabled: true,
      ),
    );

    final SettingsService reloaded = SettingsService(prefs);
    expect(reloaded.isPrayerCalculationMethodManuallySelected, isTrue);
    expect(reloaded.prayerCalculationMethodOverride, 'isna');
    final PrayerLockSettings loaded = reloaded.loadPrayerLockSettings();
    expect(loaded.calculationMethodName, 'isna');
    expect(loaded.voiceNotificationsEnabled, isFalse);
    expect(loaded.automaticAzanEnabled, isTrue);
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

  test('persists the one-time Quick Settings prompt flag', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    expect(settings.quickSettingsPrompted, isFalse);
    await settings.setQuickSettingsPrompted();
    expect(settings.quickSettingsPrompted, isTrue);
  });

  test('persists feature walkthrough completion', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    expect(settings.featureWalkthroughSeen, isFalse);
    await settings.setFeatureWalkthroughSeen();
    expect(settings.featureWalkthroughSeen, isTrue);
  });

  test('uses the 15-minute default for incomplete saved prayer settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_lock_settings': '{"enabled":true}',
    });
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    final PrayerLockSettings loaded = settings.loadPrayerLockSettings();
    expect(loaded.lockDurations[Prayer.fajr], 15);
    expect(loaded.fridayDhuhrDuration, 15);
  });

  test('migrates only legacy English default prayer notifications to Arabic',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_lock_settings': '{"notificationMessages":{"fajr":"Fajr prayer time is approaching. Your device will be locked in 2 minutes.","asr":"رسالة الوالد المخصصة"}}',
    });
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    final PrayerLockSettings loaded = settings.loadPrayerLockSettings();
    expect(loaded.notificationMessages[Prayer.fajr],
        'اقترب وقت صلاة الفجر. سيُقفل الجهاز بعد دقيقتين.');
    expect(loaded.notificationMessages[Prayer.asr], 'رسالة الوالد المخصصة');
  });

  test('falls back safely when stored prayer settings are malformed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_lock_settings': '{not-json',
    });
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    final PrayerLockSettings loaded = settings.loadPrayerLockSettings();
    expect(loaded.enabled, isTrue);
    expect(loaded.calculationMethodName, 'makkah');
    expect(loaded.lockDurations[Prayer.fajr], 15);
    expect(loaded.voiceNotificationsEnabled, isTrue);
  });

  test('preserves explicit disabled prayer lock and ignores unknown prayer keys',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_lock_settings': '{"enabled":false,"lockDurations":{"fajr":12,"unknown":99},"notificationMessages":{"fajr":"رسالة مخصصة","unknown":"تجاهل"}}',
    });
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    final PrayerLockSettings loaded = settings.loadPrayerLockSettings();
    expect(loaded.enabled, isFalse);
    expect(loaded.lockDurations, <Prayer, int>{Prayer.fajr: 12});
    expect(loaded.notificationMessages, <Prayer, String>{Prayer.fajr: 'رسالة مخصصة'});
  });

  test('manual calculation-method override wins over a stored value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prayer_lock_settings': '{"calculationMethod":"isna"}',
      'prayer_calculation_method_override': 'makkah',
    });
    final SettingsService settings =
        SettingsService(await SharedPreferences.getInstance());

    expect(settings.loadPrayerLockSettings().calculationMethodName, 'makkah');
  });
}
