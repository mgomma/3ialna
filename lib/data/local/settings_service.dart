import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/overlay_data.dart';
import '../../domain/models/country_word_profile.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';

/// Keys for persisted settings.
const String _prefsKeyTimeLimit = 'time_limit_minutes';
const String _prefsKeyIsMonitoring = 'is_monitoring';
const String _prefsKeyOverlayApp = 'overlay_app_name';
const String _prefsKeyOverlayUsed = 'overlay_used_minutes';
const String _prefsKeyOverlayLimit = 'overlay_limit_minutes';
const String _prefsKeyUsageDialogShown = 'usage_dialog_shown';
const String _prefsKeyPrayerLockSettings = 'prayer_lock_settings';
const String _prefsKeyPrayerCalculationMethodManual = 'prayer_calculation_method_manual';
const String _prefsKeyPrayerCalculationMethodOverride = 'prayer_calculation_method_override';
const String _prefsKeyPrayerLockActiveStart = 'prayer_lock_active_start';
const String _prefsKeyPrayerLockActiveEnd = 'prayer_lock_active_end';
const String _prefsKeyPrayerLockActiveName = 'prayer_lock_active_name';
const String _prefsKeyIsStrictMode = 'is_strict_mode';
const String _prefsKeyIsDeviceLocked = 'is_device_locked';
const String _prefsKeySelectedCountry = 'selected_country_profile';
const String _prefsKeyEssentialPermissionsPrompted = 'essential_permissions_prompted_v1';
const String _prefsKeyFeatureWalkthroughSeen = 'feature_walkthrough_seen_v1';
const String _prefsKeyQuickSettingsPrompted = 'quick_settings_prompted_v1';
const String _prefsKeyFirstRunSetupComplete = 'first_run_setup_complete_v1';
const String _prayerOverlayPrefix = 'Prayer Time Lock';

/// Thin wrapper around [SharedPreferences] to keep persistence logic in one
/// place and out of widgets.
class SettingsService {
  const SettingsService(this._prefs);

  final SharedPreferences _prefs;

  int get timeLimitMinutes => _prefs.getInt(_prefsKeyTimeLimit) ?? 30;

  bool get isMonitoring => _prefs.getBool(_prefsKeyIsMonitoring) ?? false;

  bool get usageDialogShown => _prefs.getBool(_prefsKeyUsageDialogShown) ?? false;

  bool get isStrictMode => _prefs.getBool(_prefsKeyIsStrictMode) ?? false;

  bool get isDeviceLocked => _prefs.getBool(_prefsKeyIsDeviceLocked) ?? false;

  String? get selectedCountry => _prefs.getString(_prefsKeySelectedCountry);

  bool get essentialPermissionsPrompted =>
      _prefs.getBool(_prefsKeyEssentialPermissionsPrompted) ?? false;

  bool get featureWalkthroughSeen =>
      _prefs.getBool(_prefsKeyFeatureWalkthroughSeen) ?? false;

  bool get quickSettingsPrompted =>
      _prefs.getBool(_prefsKeyQuickSettingsPrompted) ?? false;

  bool get firstRunSetupComplete =>
      _prefs.getBool(_prefsKeyFirstRunSetupComplete) ?? false;

  CountryWordProfile? get countryWordProfile {
    final String? country = selectedCountry;
    if (country == null || country.isEmpty) {
      return null;
    }
    return CountryWordProfile.fromCountry(country);
  }

  Future<void> setTimeLimitMinutes(int value) async {
    await _prefs.setInt(_prefsKeyTimeLimit, value);
  }

  Future<void> setIsMonitoring(bool value) async {
    await _prefs.setBool(_prefsKeyIsMonitoring, value);
  }

  Future<void> setUsageDialogShown() async {
    await _prefs.setBool(_prefsKeyUsageDialogShown, true);
  }

  Future<void> setIsStrictMode(bool value) async {
    await _prefs.setBool(_prefsKeyIsStrictMode, value);
  }

  Future<void> setIsDeviceLocked(bool value) async {
    await _prefs.setBool(_prefsKeyIsDeviceLocked, value);
  }

  Future<void> setSelectedCountry(String country) async {
    await _prefs.setString(_prefsKeySelectedCountry, country);
  }

  Future<void> setEssentialPermissionsPrompted() async {
    await _prefs.setBool(_prefsKeyEssentialPermissionsPrompted, true);
  }

  Future<void> setFeatureWalkthroughSeen() async {
    await _prefs.setBool(_prefsKeyFeatureWalkthroughSeen, true);
  }

  Future<void> setQuickSettingsPrompted() async {
    await _prefs.setBool(_prefsKeyQuickSettingsPrompted, true);
  }

  Future<void> setFirstRunSetupComplete() async {
    await _prefs.setBool(_prefsKeyFirstRunSetupComplete, true);
  }

  Future<void> saveOverlayData(OverlayData data) async {
    await _prefs.setString(_prefsKeyOverlayApp, data.appName);
    await _prefs.setInt(_prefsKeyOverlayUsed, data.usedMinutes);
    await _prefs.setInt(_prefsKeyOverlayLimit, data.limitMinutes);
  }

  OverlayData loadOverlayData() {
    return OverlayData(
      appName: _prefs.getString(_prefsKeyOverlayApp) ?? 'Social App',
      usedMinutes: _prefs.getInt(_prefsKeyOverlayUsed) ?? 0,
      limitMinutes: _prefs.getInt(_prefsKeyOverlayLimit) ?? 0,
    );
  }

  bool get isPrayerCalculationMethodManuallySelected =>
      _prefs.getBool(_prefsKeyPrayerCalculationMethodManual) ?? false;

  Future<void> setPrayerCalculationMethodManuallySelected(bool value) async {
    await _prefs.setBool(_prefsKeyPrayerCalculationMethodManual, value);
  }

  String? get prayerCalculationMethodOverride =>
      _prefs.getString(_prefsKeyPrayerCalculationMethodOverride);

  Future<void> setPrayerCalculationMethodOverride(String methodName) async {
    await _prefs.setString(_prefsKeyPrayerCalculationMethodOverride, methodName);
    await setPrayerCalculationMethodManuallySelected(true);
  }

  /// Saves prayer lock settings.
  Future<void> savePrayerLockSettings(PrayerLockSettings settings) async {
    final Map<String, dynamic> json = {
      'enabled': settings.enabled,
      'lockDurations': settings.lockDurations.map((Prayer key, int value) => MapEntry(key.name, value)),
      'fridayDhuhrDuration': settings.fridayDhuhrDuration,
      'calculationMethod': settings.calculationMethodName,
      'notificationMessages': settings.notificationMessages.map((Prayer key, String value) => MapEntry(key.name, value)),
      'voiceNotificationsEnabled': settings.voiceNotificationsEnabled,
      'automaticAzanEnabled': settings.automaticAzanEnabled,
      if (settings.latitude != null) 'latitude': settings.latitude,
      if (settings.longitude != null) 'longitude': settings.longitude,
    };

    await _prefs.setString(_prefsKeyPrayerLockSettings, jsonEncode(json));
  }

  /// Loads prayer lock settings.
  PrayerLockSettings loadPrayerLockSettings() {
    final String? jsonString = _prefs.getString(_prefsKeyPrayerLockSettings);
    if (jsonString == null) {
      return PrayerLockSettings.defaults();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;

      final Map<Prayer, int> lockDurations = {};
      if (json['lockDurations'] != null) {
        final Map<String, dynamic> durations = json['lockDurations'] as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> entry in durations.entries) {
          final Prayer? prayer = _prayerFromString(entry.key);
          if (prayer != null) {
            lockDurations[prayer] = entry.value as int;
          }
        }
      }

      final Map<Prayer, String> notificationMessages = {};
      if (json['notificationMessages'] != null) {
        final Map<String, dynamic> messages = json['notificationMessages'] as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> entry in messages.entries) {
          final Prayer? prayer = _prayerFromString(entry.key);
          if (prayer != null) {
            final String message = entry.value as String;
            notificationMessages[prayer] =
                PrayerLockSettings.isLegacyDefaultNotificationMessage(
              prayer,
              message,
            )
                    ? PrayerLockSettings.defaultNotificationMessage(prayer)
                    : message;
          }
        }
      }

      return PrayerLockSettings(
        // A missing field is an older/incomplete record, not a parent choice.
        // Preserve an explicit false while defaulting incomplete records on.
        enabled: json['enabled'] as bool? ?? PrayerLockSettings.defaults().enabled,
        lockDurations: lockDurations.isEmpty ? PrayerLockSettings.defaults().lockDurations : lockDurations,
        fridayDhuhrDuration: json['fridayDhuhrDuration'] as int? ??
            PrayerLockSettings.defaultLockDurationMinutes,
        calculationMethodName:
            prayerCalculationMethodOverride ??
            json['calculationMethod'] as String? ??
            'makkah',
        notificationMessages: notificationMessages.isEmpty ? PrayerLockSettings.defaults().notificationMessages : notificationMessages,
        voiceNotificationsEnabled: json['voiceNotificationsEnabled'] as bool? ?? true,
        automaticAzanEnabled: json['automaticAzanEnabled'] as bool? ?? false,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
      );
    } catch (e) {
      return PrayerLockSettings.defaults();
    }
  }

  Prayer? _prayerFromString(String name) {
    return switch (name) {
      'fajr' => Prayer.fajr,
      'dhuhr' => Prayer.dhuhr,
      'asr' => Prayer.asr,
      'maghrib' => Prayer.maghrib,
      'isha' => Prayer.isha,
      _ => null,
    };
  }

  /// Saves the currently active prayer lock period for background service checking.
  ///
  /// This allows the Android background service to check if we're in a prayer
  /// lock period without needing to calculate prayer times in Kotlin.
  Future<void> saveActivePrayerLockPeriod({required String prayerName, required DateTime lockStart, required DateTime lockEnd}) async {
    await _prefs.setString(_prefsKeyPrayerLockActiveName, prayerName);
    // Store as string since SharedPreferences doesn't have setLong
    await _prefs.setString(_prefsKeyPrayerLockActiveStart, lockStart.millisecondsSinceEpoch.toString());
    await _prefs.setString(_prefsKeyPrayerLockActiveEnd, lockEnd.millisecondsSinceEpoch.toString());
  }

  /// Clears the active prayer lock period.
  Future<void> clearActivePrayerLockPeriod() async {
    await _prefs.remove(_prefsKeyPrayerLockActiveName);
    await _prefs.remove(_prefsKeyPrayerLockActiveStart);
    await _prefs.remove(_prefsKeyPrayerLockActiveEnd);
  }

  String? get activePrayerLockName =>
      _prefs.getString(_prefsKeyPrayerLockActiveName);

  /// Releases persisted state only when the visible lock was created for a
  /// prayer interval. This prevents an expired prayer period from dismissing
  /// an unrelated app-limit overlay.
  Future<bool> releasePrayerOverlayIfOwned({String? prayerName}) async {
    if (prayerName != null && activePrayerLockName != prayerName) {
      return false;
    }
    final String overlayName = _prefs.getString(_prefsKeyOverlayApp) ?? '';
    final bool isPrayerOverlay = overlayName.startsWith(_prayerOverlayPrefix);
    await clearActivePrayerLockPeriod();
    if (!isPrayerOverlay) return false;
    await _prefs.remove(_prefsKeyOverlayApp);
    await _prefs.remove(_prefsKeyOverlayUsed);
    await _prefs.remove(_prefsKeyOverlayLimit);
    await setIsDeviceLocked(false);
    return true;
  }
}
