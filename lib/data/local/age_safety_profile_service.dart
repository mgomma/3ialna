import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/age_safety_profile.dart';

class AgeSafetyProfileService {
  const AgeSafetyProfileService(this._prefs);

  static const String _key = 'age_safety_profile_config';
  final SharedPreferences _prefs;

  AgeSafetyProfilePreset load() {
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
        blockMatureContent: json['blockMatureContent'] as bool?,
        requireParentApproval: json['requireParentApproval'] as bool?,
        voiceNotifications: json['voiceNotifications'] as bool?,
      );
    } catch (_) {
      return AgeSafetyProfilePreset.defaults[AgeSafetyProfile.underFive]!;
    }
  }

  Future<void> save(AgeSafetyProfilePreset preset) async {
    await _prefs.setString(_key, jsonEncode(<String, Object>{
      'profile': preset.profile.name,
      'dailyLimitMinutes': preset.dailyLimitMinutes,
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
}
