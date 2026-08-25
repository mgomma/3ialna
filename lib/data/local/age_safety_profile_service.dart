import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/age_safety_profile.dart';
import '../../domain/models/child_profile.dart';
import '../system/ios_screen_time_safeguard_service.dart';

class AgeSafetyProfileService {
  const AgeSafetyProfileService(this._prefs);

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static const String _key = 'age_safety_profile_config';
  static const String _childrenKey = 'parental_control_children';
  static const String _activeChildKey = 'parental_control_active_child_id';
  static const String _parentModeActiveKey =
      'parental_control_parent_mode_active';
  static const String _runtimeActiveChildKey = 'active_child_id';
  static const String _runtimeSocialLimitKey = 'active_social_media_limit_minutes';
  static const String _runtimeGamesLimitKey = 'active_games_limit_minutes';
  static const String _runtimePrayerLockEnabledKey = 'active_prayer_lock_enabled';
  static const String _runtimePrayerLockMinutesKey = 'active_prayer_lock_minutes';
  static const String _runtimeSleepLockEnabledKey = 'active_sleep_lock_enabled';
  static const String _runtimeSleepLockStartKey = 'active_sleep_lock_start_minutes';
  static const String _runtimeSleepLockEndKey = 'active_sleep_lock_end_minutes';
  final SharedPreferences _prefs;

  List<ChildProfile> loadChildren() {
    final String? raw = _prefs.getString(_childrenKey);
    if (raw == null) return <ChildProfile>[];
    try {
      final List<dynamic> values = jsonDecode(raw) as List<dynamic>;
      return values
          .whereType<Map<String, dynamic>>()
          .map(ChildProfile.fromJson)
          .toList(growable: false);
    } catch (_) {
      return <ChildProfile>[];
    }
  }

  ChildProfile? activeChild() {
    final List<ChildProfile> children = loadChildren();
    if (children.isEmpty) return null;
    final String? activeId = _prefs.getString(_activeChildKey);
    return children.firstWhere(
      (ChildProfile child) => child.id == activeId,
      orElse: () => children.first,
    );
  }

  /// Parent mode is separate from a child profile. The UI may enable it only
  /// after a parent PIN or biometric verification succeeds.
  bool isParentModeActive() => _prefs.getBool(_parentModeActiveKey) ?? false;

  Future<void> ensureDefaultChild() async {
    if (loadChildren().isNotEmpty) {
      final bool refreshed = await refreshAutomaticAgeProfiles();
      if (!refreshed) await _syncRuntime(activeChild());
      return;
    }
    final bool hasLegacyPreset = _prefs.containsKey(_key);
    final ChildProfile child = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Child 1',
      birthDate: DateTime.now(),
      gender: ChildGender.unspecified,
      preset: _loadLegacyPreset(),
      profileFollowsBirthDate: !hasLegacyPreset,
    );
    await _saveChildren(<ChildProfile>[child], activeId: child.id);
  }

  AgeSafetyProfilePreset load() {
    final ChildProfile? child = activeChild();
    if (child != null) return child.preset;
    return _loadLegacyPreset();
  }

  AgeSafetyProfilePreset _loadLegacyPreset() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return AgeSafetyProfilePreset.defaults[AgeSafetyProfile.underFive]!;
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final AgeSafetyProfile profile = AgeSafetyProfile.values.firstWhere(
        (AgeSafetyProfile item) => item.name == json['profile'],
        orElse: () => AgeSafetyProfile.underFive,
      );
      final AgeSafetyProfilePreset base = AgeSafetyProfilePreset.defaults[profile]!;
      return base.copyWith(
        dailyLimitMinutes: json['dailyLimitMinutes'] as int?,
        socialMediaLimitMinutes: json['socialMediaLimitMinutes'] as int?,
        gamesLimitMinutes: json['gamesLimitMinutes'] as int?,
        prayerLockEnabled: json['prayerLockEnabled'] as bool?,
        prayerLockMinutes: json['prayerLockMinutes'] as int?,
        sleepLockEnabled: json['sleepLockEnabled'] as bool?,
        sleepLockStartMinutes: json['sleepLockStartMinutes'] as int?,
        sleepLockEndMinutes: json['sleepLockEndMinutes'] as int?,
        blockMatureContent: json['blockMatureContent'] as bool?,
        requireParentApproval: json['requireParentApproval'] as bool?,
        voiceNotifications: json['voiceNotifications'] as bool?,
      );
    } catch (_) {
      return AgeSafetyProfilePreset.defaults[AgeSafetyProfile.underFive]!;
    }
  }

  Future<void> save(AgeSafetyProfilePreset preset) async {
    await ensureDefaultChild();
    final ChildProfile active = activeChild()!;
    final List<ChildProfile> children = loadChildren()
        .map((ChildProfile child) => child.id == active.id
            ? child.copyWith(
                preset: preset,
                profileFollowsBirthDate: false,
              )
            : child)
        .toList(growable: false);
    await _saveChildren(children, activeId: active.id);
    await _prefs.setString(_key, jsonEncode(<String, Object>{
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
    }));
  }

  Future<AgeSafetyProfilePreset> reset() async {
    final AgeSafetyProfilePreset preset = AgeSafetyProfilePreset.defaults[load().profile]!;
    await save(preset);
    return preset;
  }

  Future<AgeSafetyProfilePreset> select(AgeSafetyProfile profile) async {
    final AgeSafetyProfilePreset preset = AgeSafetyProfilePreset.defaults[profile]!;
    await save(preset);
    return preset;
  }

  Future<ChildProfile> addChild({
    required String name,
    required DateTime birthDate,
    required ChildGender gender,
    AgeSafetyProfile? profile,
    bool? profileFollowsBirthDate,
  }) async {
    await ensureDefaultChild();
    final bool followsBirthDate = profileFollowsBirthDate ?? profile == null;
    final AgeSafetyProfile resolvedProfile = followsBirthDate
        ? AgeSafetyProfileRecommendation.forBirthDate(birthDate)
        : profile!;
    final ChildProfile child = ChildProfile(
      id: 'child-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Child ${loadChildren().length + 1}' : name.trim(),
      birthDate: birthDate,
      gender: gender,
      preset: AgeSafetyProfilePreset.defaults[resolvedProfile]!,
      profileFollowsBirthDate: followsBirthDate,
    );
    final List<ChildProfile> children = <ChildProfile>[...loadChildren(), child];
    await _saveChildren(children, activeId: activeChild()?.id ?? child.id);
    return child;
  }

  Future<void> updateChild(ChildProfile child) async {
    final ChildProfile updatedChild = child.profileFollowsBirthDate
        ? child.copyWith(
            preset: AgeSafetyProfilePreset.defaults[
              AgeSafetyProfileRecommendation.forBirthDate(child.birthDate)
            ]!,
          )
        : child;
    final List<ChildProfile> children = loadChildren()
        .map((ChildProfile item) => item.id == updatedChild.id ? updatedChild : item)
        .toList(growable: false);
    await _saveChildren(children, activeId: activeChild()?.id ?? updatedChild.id);
  }

  /// Updates only profiles previously marked as birth-date recommendations.
  /// Parent-selected or edited profiles deliberately remain unchanged.
  Future<bool> refreshAutomaticAgeProfiles({DateTime? now}) async {
    final List<ChildProfile> children = loadChildren();
    if (children.isEmpty) return false;
    var changed = false;
    final List<ChildProfile> updated = children.map((ChildProfile child) {
      if (!child.profileFollowsBirthDate) return child;
      final AgeSafetyProfile recommended =
          AgeSafetyProfileRecommendation.forBirthDate(child.birthDate, onDate: now);
      if (child.preset.profile == recommended) return child;
      changed = true;
      return child.copyWith(
        preset: AgeSafetyProfilePreset.defaults[recommended]!,
      );
    }).toList(growable: false);
    if (!changed) return false;
    await _saveChildren(
      updated,
      activeId: activeChild()?.id ?? updated.first.id,
    );
    return true;
  }

  Future<void> setActiveChild(String childId) async {
    final List<ChildProfile> children = loadChildren();
    if (!children.any((ChildProfile child) => child.id == childId)) return;
    await _prefs.setBool(_parentModeActiveKey, false);
    await _saveChildren(children, activeId: childId);
  }

  /// Called only after the caller has completed PIN or biometric verification.
  Future<void> setParentModeActive(bool active) async {
    await ensureDefaultChild();
    await _prefs.setBool(_parentModeActiveKey, active);
    await _syncRuntime(activeChild());
    changes.value += 1;
  }

  Future<void> removeChild(String childId) async {
    final List<ChildProfile> children = loadChildren();
    if (children.length <= 1) return;
    final List<ChildProfile> updated = children.where((ChildProfile child) => child.id != childId).toList(growable: false);
    final String activeId = activeChild()?.id == childId ? updated.first.id : (activeChild()?.id ?? updated.first.id);
    await _saveChildren(updated, activeId: activeId);
  }

  Future<void> _saveChildren(List<ChildProfile> children, {required String activeId}) async {
    await _prefs.setString(_childrenKey, jsonEncode(children.map((ChildProfile child) => child.toJson()).toList()));
    await _prefs.setString(_activeChildKey, activeId);
    final ChildProfile active = children.firstWhere((ChildProfile child) => child.id == activeId, orElse: () => children.first);
    await _syncRuntime(active);
    changes.value += 1;
  }

  Future<void> _syncRuntime(ChildProfile? child) async {
    if (child == null) return;
    if (isParentModeActive()) {
      await _prefs.setString(_runtimeActiveChildKey, 'parent');
      await _prefs.setInt(_runtimeSocialLimitKey, 0);
      await _prefs.setInt(_runtimeGamesLimitKey, 0);
      await _prefs.setBool(_runtimePrayerLockEnabledKey, false);
      await _prefs.setInt(_runtimePrayerLockMinutesKey, 0);
      await _prefs.setBool(_runtimeSleepLockEnabledKey, false);
      await _prefs.setInt(_runtimeSleepLockStartKey, 0);
      await _prefs.setInt(_runtimeSleepLockEndKey, 0);
      if (Platform.isIOS) {
        try {
          await IosScreenTimeSafeguardService().syncSleepShield(
            enabled: false,
            startMinutes: 0,
            endMinutes: 0,
          );
          await IosScreenTimeSafeguardService().clearPrayerShields();
        } catch (_) {
          // The platform bridge reports authorization/setup separately.
        }
      }
      return;
    }
    await _prefs.setString(_runtimeActiveChildKey, child.id);
    await _prefs.setInt(_runtimeSocialLimitKey, child.preset.socialMediaLimitMinutes);
    await _prefs.setInt(_runtimeGamesLimitKey, child.preset.gamesLimitMinutes);
    await _prefs.setBool(_runtimePrayerLockEnabledKey, child.preset.prayerLockEnabled);
    await _prefs.setInt(_runtimePrayerLockMinutesKey, child.preset.prayerLockMinutes);
    await _prefs.setBool(_runtimeSleepLockEnabledKey, child.preset.sleepLockEnabled);
    await _prefs.setInt(_runtimeSleepLockStartKey, child.preset.sleepLockStartMinutes);
    await _prefs.setInt(_runtimeSleepLockEndKey, child.preset.sleepLockEndMinutes);
    if (Platform.isIOS) {
      try {
        await IosScreenTimeSafeguardService().syncSleepShield(
          enabled: child.preset.sleepLockEnabled,
          startMinutes: child.preset.sleepLockStartMinutes,
          endMinutes: child.preset.sleepLockEndMinutes,
        );
      } catch (_) {
        // The native bridge reports setup status in the iOS onboarding screen.
      }
    }
  }
}
