import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/age_safety_profile.dart';
import '../../domain/models/managed_app_category.dart';
import '../../domain/models/schedule.dart';
import 'age_safety_profile_service.dart';
import 'parental_control_storage_service.dart';

class ShareableProfilePack {
  const ShareableProfilePack({
    required this.profileName,
    required this.creatorName,
    required this.preset,
    required this.blockedApps,
    required this.appTimeLimits,
    required this.appCategories,
    required this.schedule,
  });

  static const String format = '3ialna-profile-pack';
  static const int version = 1;

  final String profileName;
  final String creatorName;
  final AgeSafetyProfilePreset preset;
  final List<String> blockedApps;
  final Map<String, int> appTimeLimits;
  final Map<String, ManagedAppCategory> appCategories;
  final Schedule schedule;

  Map<String, Object> toJson() => <String, Object>{
        'format': format,
        'version': version,
        'profileName': profileName,
        'creatorName': creatorName,
        'preset': <String, Object>{
          'profile': preset.profile.name,
          'dailyLimitMinutes': preset.dailyLimitMinutes,
          'socialMediaLimitMinutes': preset.socialMediaLimitMinutes,
          'gamesLimitMinutes': preset.gamesLimitMinutes,
          'prayerLockEnabled': preset.prayerLockEnabled,
          'prayerLockMinutes': preset.prayerLockMinutes,
          'sleepLockEnabled': preset.sleepLockEnabled,
          'sleepLockStartMinutes': preset.sleepLockStartMinutes,
          'sleepLockEndMinutes': preset.sleepLockEndMinutes,
          'blockMatureContent': preset.blockMatureContent,
          'requireParentApproval': preset.requireParentApproval,
          'voiceNotifications': preset.voiceNotifications,
        },
        'appRules': <String, Object>{
          'blockedApps': blockedApps,
          'timeLimits': appTimeLimits,
          'categories': appCategories.map((String key, ManagedAppCategory value) => MapEntry(key, value.name)),
        },
        'schedule': schedule.toMap(),
      };

  factory ShareableProfilePack.fromJson(Map<String, dynamic> json) {
    if (json['format'] != format || json['version'] != version || _containsIdentityField(json)) {
      throw const FormatException('This is not a supported anonymous 3ialna profile pack.');
    }
    final String profileName = (json['profileName'] as String? ?? '').trim();
    final String creatorName = (json['creatorName'] as String? ?? '').trim();
    if (profileName.isEmpty || creatorName.isEmpty || profileName.length > 80 || creatorName.length > 80) {
      throw const FormatException('A profile name and creator name are required.');
    }
    final Map<String, dynamic> presetJson = Map<String, dynamic>.from(json['preset'] as Map? ?? const <String, dynamic>{});
    final AgeSafetyProfile profile = AgeSafetyProfile.values.firstWhere(
      (AgeSafetyProfile value) => value.name == presetJson['profile'],
      orElse: () => AgeSafetyProfile.underFive,
    );
    final AgeSafetyProfilePreset base = AgeSafetyProfilePreset.defaults[profile]!;
    final Map<String, dynamic> appRules = Map<String, dynamic>.from(json['appRules'] as Map? ?? const <String, dynamic>{});
    final Map<String, dynamic> categoryJson = Map<String, dynamic>.from(appRules['categories'] as Map? ?? const <String, dynamic>{});
    final Map<String, dynamic> limitsJson = Map<String, dynamic>.from(appRules['timeLimits'] as Map? ?? const <String, dynamic>{});
    return ShareableProfilePack(
      profileName: profileName,
      creatorName: creatorName,
      preset: base.copyWith(
        dailyLimitMinutes: _int(presetJson['dailyLimitMinutes'], 0, 1440),
        socialMediaLimitMinutes: _int(presetJson['socialMediaLimitMinutes'], 0, 1440),
        gamesLimitMinutes: _int(presetJson['gamesLimitMinutes'], 0, 1440),
        prayerLockEnabled: presetJson['prayerLockEnabled'] as bool?,
        prayerLockMinutes: _int(presetJson['prayerLockMinutes'], 0, 120),
        sleepLockEnabled: presetJson['sleepLockEnabled'] as bool?,
        sleepLockStartMinutes: _int(presetJson['sleepLockStartMinutes'], 0, 1439),
        sleepLockEndMinutes: _int(presetJson['sleepLockEndMinutes'], 0, 1439),
        blockMatureContent: presetJson['blockMatureContent'] as bool?,
        requireParentApproval: presetJson['requireParentApproval'] as bool?,
        voiceNotifications: presetJson['voiceNotifications'] as bool?,
      ),
      blockedApps: (appRules['blockedApps'] as List? ?? const <dynamic>[]).whereType<String>().take(300).toList(growable: false),
      appTimeLimits: limitsJson.map((String key, dynamic value) => MapEntry(key, _int(value, 0, 1440) ?? 0)),
      appCategories: categoryJson.map((String key, dynamic value) => MapEntry(
            key,
            ManagedAppCategory.values.firstWhere(
              (ManagedAppCategory category) => category.name == value,
              orElse: () => ManagedAppCategory.unassigned,
            ),
          )),
      schedule: Schedule.fromMap(Map<String, dynamic>.from(json['schedule'] as Map? ?? const <String, dynamic>{})),
    );
  }

  static int? _int(dynamic value, int min, int max) {
    if (value is! int) return null;
    return value.clamp(min, max).toInt();
  }

  static bool _containsIdentityField(Object? value) {
    const Set<String> prohibited = <String>{'children', 'child', 'childId', 'childName', 'birthDate', 'dateOfBirth', 'gender', 'activeChildId'};
    if (value is Map) {
      for (final MapEntry<dynamic, dynamic> item in value.entries) {
        if (item.key is String && prohibited.contains(item.key)) return true;
        if (_containsIdentityField(item.value)) return true;
      }
    } else if (value is List) {
      return value.any(_containsIdentityField);
    }
    return false;
  }
}

class ShareableProfilePackService {
  ShareableProfilePackService(this._profiles, this._controls);

  final AgeSafetyProfileService _profiles;
  final ParentalControlStorageService _controls;

  Future<String> export({required String profileName, required String creatorName}) async {
    final ShareableProfilePack pack = ShareableProfilePack(
      profileName: profileName.trim(),
      creatorName: creatorName.trim(),
      preset: _profiles.load(),
      blockedApps: await _controls.getBlockedApps(),
      appTimeLimits: await _controls.getTimeLimits(),
      appCategories: await _controls.getAppCategories(),
      schedule: await _controls.getSchedule(),
    );
    if (pack.profileName.isEmpty || pack.creatorName.isEmpty) {
      throw const FormatException('A profile name and creator name are required.');
    }
    return const JsonEncoder.withIndent('  ').convert(pack.toJson());
  }

  Future<ShareableProfilePack> importText(String text) async {
    final Object decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) throw const FormatException('The imported file must be a JSON object.');
    final ShareableProfilePack pack = ShareableProfilePack.fromJson(decoded);
    await _profiles.save(pack.preset);
    await _controls.setBlockedApps(pack.blockedApps);
    await _controls.setTimeLimits(pack.appTimeLimits);
    await _controls.setAppCategories(pack.appCategories);
    await _controls.setSchedule(pack.schedule);
    return pack;
  }

  static Future<ShareableProfilePackService> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return ShareableProfilePackService(AgeSafetyProfileService(prefs), ParentalControlStorageService());
  }
}
