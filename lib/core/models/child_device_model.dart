import 'package:json_annotation/json_annotation.dart';

part 'child_device_model.g.dart';

@JsonSerializable()
class ChildDevice {
  final int id;
  final int parentId;
  final String deviceName;
  final String deviceId;
  final String deviceType;
  final String? childName;
  final int? childAge;
  final String? childGender;
  final bool isActive;
  final DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceSettings settings;
  final String? appliedProfileId;

  const ChildDevice({
    required this.id,
    required this.parentId,
    required this.deviceName,
    required this.deviceId,
    required this.deviceType,
    this.childName,
    this.childAge,
    this.childGender,
    required this.isActive,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    this.appliedProfileId,
  });

  factory ChildDevice.fromJson(Map<String, dynamic> json) => 
      _$ChildDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$ChildDeviceToJson(this);
}

@JsonSerializable()
class DeviceSettings {
  final int lockDurationMinutes;
  final int appUsageLimitMinutes;
  final String notificationMessage;
  final String language;
  final Map<String, int> appLimits;
  final PrayerSettings prayerSettings;
  final bool isLocked;
  final DateTime? lockUntil;
  final List<String> blockedApps;
  final List<String> allowedApps;

  const DeviceSettings({
    required this.lockDurationMinutes,
    required this.appUsageLimitMinutes,
    required this.notificationMessage,
    required this.language,
    required this.appLimits,
    required this.prayerSettings,
    required this.isLocked,
    this.lockUntil,
    required this.blockedApps,
    required this.allowedApps,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => 
      _$DeviceSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceSettingsToJson(this);
}

@JsonSerializable()
class AppUsage {
  final String packageName;
  final String appName;
  final String category;
  final int usageTimeMinutes;
  final int limitMinutes;
  final bool isBlocked;
  final DateTime lastUsed;

  const AppUsage({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.usageTimeMinutes,
    required this.limitMinutes,
    required this.isBlocked,
    required this.lastUsed,
  });

  factory AppUsage.fromJson(Map<String, dynamic> json) => 
      _$AppUsageFromJson(json);
  Map<String, dynamic> toJson() => _$AppUsageToJson(this);
}

@JsonSerializable()
class DailyReport {
  final int id;
  final int childDeviceId;
  final DateTime date;
  final int totalUsageMinutes;
  final Map<String, int> appUsage;
  final Map<String, int> categoryUsage;
  final int lockTimeMinutes;
  final List<String> blockedApps;
  final List<String> accessedApps;
  final DateTime createdAt;

  const DailyReport({
    required this.id,
    required this.childDeviceId,
    required this.date,
    required this.totalUsageMinutes,
    required this.appUsage,
    required this.categoryUsage,
    required this.lockTimeMinutes,
    required this.blockedApps,
    required this.accessedApps,
    required this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => 
      _$DailyReportFromJson(json);
  Map<String, dynamic> toJson() => _$DailyReportToJson(this);
}

@JsonSerializable()
class PrayerTime {
  final String name;
  final DateTime time;
  final bool isLocked;
  final int lockDurationMinutes;

  const PrayerTime({
    required this.name,
    required this.time,
    required this.isLocked,
    required this.lockDurationMinutes,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) => 
      _$PrayerTimeFromJson(json);
  Map<String, dynamic> toJson() => _$PrayerTimeToJson(this);
}
