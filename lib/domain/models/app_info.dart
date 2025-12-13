/// Model representing an installed application on the device.
class AppInfo {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final bool isSystemApp;
  final bool isEnabled;
  final int installTime;
  final int updateTime;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    required this.isSystemApp,
    required this.isEnabled,
    required this.installTime,
    required this.updateTime,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBase64: map['icon'] as String?,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
      installTime: map['installTime'] as int? ?? 0,
      updateTime: map['updateTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'icon': iconBase64,
      'isSystemApp': isSystemApp,
      'isEnabled': isEnabled,
      'installTime': installTime,
      'updateTime': updateTime,
    };
  }

  AppInfo copyWith({
    String? packageName,
    String? appName,
    String? iconBase64,
    bool? isSystemApp,
    bool? isEnabled,
    int? installTime,
    int? updateTime,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBase64: iconBase64 ?? this.iconBase64,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isEnabled: isEnabled ?? this.isEnabled,
      installTime: installTime ?? this.installTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}

