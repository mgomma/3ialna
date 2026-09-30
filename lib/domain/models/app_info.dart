/// Model representing an installed application on the device.
class AppInfo {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final bool isSystemApp;
  final bool isEnabled;
  final int installTime;
  final int updateTime;
  /// Android's own declared app category (`ApplicationInfo.CATEGORY_*`), or
  /// null when undeclared/unavailable (e.g. older OS versions, non-Android).
  final int? androidCategory;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    required this.isSystemApp,
    required this.isEnabled,
    required this.installTime,
    required this.updateTime,
    this.androidCategory,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    final int? category = map['category'] as int?;
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBase64: map['icon'] as String?,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
      installTime: map['installTime'] as int? ?? 0,
      updateTime: map['updateTime'] as int? ?? 0,
      androidCategory: category == null || category < 0 ? null : category,
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
      'category': androidCategory,
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
    int? androidCategory,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBase64: iconBase64 ?? this.iconBase64,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isEnabled: isEnabled ?? this.isEnabled,
      installTime: installTime ?? this.installTime,
      updateTime: updateTime ?? this.updateTime,
      androidCategory: androidCategory ?? this.androidCategory,
    );
  }
}

