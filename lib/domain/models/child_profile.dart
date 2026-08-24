import 'age_safety_profile.dart';

enum ChildGender { boy, girl, unspecified }

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.preset,
    this.profileFollowsBirthDate = false,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final ChildGender gender;
  final AgeSafetyProfilePreset preset;
  final bool profileFollowsBirthDate;

  int get ageYears {
    final DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (DateTime(today.year, birthDate.month, birthDate.day).isAfter(today)) {
      age -= 1;
    }
    return age.clamp(0, 99).toInt();
  }

  ChildProfile copyWith({
    String? name,
    DateTime? birthDate,
    ChildGender? gender,
    AgeSafetyProfilePreset? preset,
    bool? profileFollowsBirthDate,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      preset: preset ?? this.preset,
      profileFollowsBirthDate:
          profileFollowsBirthDate ?? this.profileFollowsBirthDate,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender.name,
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
        'profileFollowsBirthDate': profileFollowsBirthDate,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final AgeSafetyProfile profile = AgeSafetyProfile.values.firstWhere(
      (AgeSafetyProfile item) => item.name == json['profile'],
      orElse: () => AgeSafetyProfile.underFive,
    );
    final AgeSafetyProfilePreset base = AgeSafetyProfilePreset.defaults[profile]!;
    final ChildGender gender = ChildGender.values.firstWhere(
      (ChildGender item) => item.name == json['gender'],
      orElse: () => ChildGender.unspecified,
    );
    return ChildProfile(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Child',
      birthDate: DateTime.tryParse(json['birthDate'] as String? ?? '') ?? DateTime.now(),
      gender: gender,
      preset: base.copyWith(
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
      ),
      profileFollowsBirthDate:
          json['profileFollowsBirthDate'] as bool? ?? false,
    );
  }
}
