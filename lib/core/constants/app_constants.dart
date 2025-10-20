class AppConstants {
  static const String appName = '3ialna Parental Control';
  static const String baseUrl = 'https://3ialna.net/api';
  static const String apiVersion = 'v1';
  // Run the app without a backend (first release demo)
  static const bool offlineMode = true;
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  
  // User Management
  static const String profileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/profile';
  
  // Child Devices
  static const String childDevicesEndpoint = '/child-devices';
  static const String childDeviceSettingsEndpoint = '/child-devices/{id}/settings';
  static const String childDeviceReportsEndpoint = '/child-devices/{id}/reports';
  
  // Master Parent Profiles
  static const String masterProfilesEndpoint = '/master-profiles';
  static const String masterProfileEndpoint = '/master-profiles/{id}';
  
  // Prayer Times
  static const String prayerTimesEndpoint = '/prayer-times';
  static const String prayerSettingsEndpoint = '/prayer-settings';
  
  // App Usage
  static const String appUsageEndpoint = '/app-usage';
  static const String appLimitsEndpoint = '/app-limits';
  
  // Reports
  static const String dailyReportsEndpoint = '/reports/daily';
  static const String activityReportsEndpoint = '/reports/activity';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String languageKey = 'language';
  static const String themeKey = 'theme';
  
  // User Roles
  static const String adminRole = 'admin';
  static const String masterParentRole = 'master_parent';
  static const String parentRole = 'parent';
  
  // Default Settings
  static const int defaultLockDuration = 30; // minutes
  static const int defaultAppLimit = 60; // minutes per day
  static const int notificationTimeBeforeLock = 2; // minutes
}
