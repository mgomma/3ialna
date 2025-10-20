import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? language;
  final String? country;
  final String? timezone;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.language,
    this.country,
    this.timezone,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$firstName $lastName';
  
  bool get isAdmin => role == 'admin';
  bool get isMasterParent => role == 'master_parent';
  bool get isParent => role == 'parent';
}

@JsonSerializable()
class MasterParentProfile {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String experience;
  final String? profileImage;
  final List<String> specializations;
  final int yearsOfExperience;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const MasterParentProfile({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.experience,
    this.profileImage,
    required this.specializations,
    required this.yearsOfExperience,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory MasterParentProfile.fromJson(Map<String, dynamic> json) => 
      _$MasterParentProfileFromJson(json);
  Map<String, dynamic> toJson() => _$MasterParentProfileToJson(this);
}

@JsonSerializable()
class DefaultProfile {
  final int id;
  final int masterParentId;
  final String name;
  final String description;
  final String gender;
  final String ageGroup;
  final String motherTongue;
  final String countryOfOrigin;
  final String countryOfResidence;
  final DefaultSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const DefaultProfile({
    required this.id,
    required this.masterParentId,
    required this.name,
    required this.description,
    required this.gender,
    required this.ageGroup,
    required this.motherTongue,
    required this.countryOfOrigin,
    required this.countryOfResidence,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory DefaultProfile.fromJson(Map<String, dynamic> json) => 
      _$DefaultProfileFromJson(json);
  Map<String, dynamic> toJson() => _$DefaultProfileToJson(this);
}

@JsonSerializable()
class DefaultSettings {
  final int lockDurationMinutes;
  final int appUsageLimitMinutes;
  final String notificationMessage;
  final String language;
  final Map<String, int> appLimits;
  final PrayerSettings prayerSettings;

  const DefaultSettings({
    required this.lockDurationMinutes,
    required this.appUsageLimitMinutes,
    required this.notificationMessage,
    required this.language,
    required this.appLimits,
    required this.prayerSettings,
  });

  factory DefaultSettings.fromJson(Map<String, dynamic> json) => 
      _$DefaultSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$DefaultSettingsToJson(this);
}

@JsonSerializable()
class PrayerSettings {
  final int fajrLockMinutes;
  final int dhuhrLockMinutes;
  final int asrLockMinutes;
  final int maghribLockMinutes;
  final int ishaLockMinutes;
  final int fridayDhuhrLockMinutes;
  final String notificationMessage;
  final bool isEnabled;

  const PrayerSettings({
    required this.fajrLockMinutes,
    required this.dhuhrLockMinutes,
    required this.asrLockMinutes,
    required this.maghribLockMinutes,
    required this.ishaLockMinutes,
    required this.fridayDhuhrLockMinutes,
    required this.notificationMessage,
    required this.isEnabled,
  });

  factory PrayerSettings.fromJson(Map<String, dynamic> json) => 
      _$PrayerSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PrayerSettingsToJson(this);
}
