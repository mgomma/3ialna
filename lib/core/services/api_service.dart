import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/child_device_model.dart';

class ApiService {
  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          if (await _refreshAccessToken()) {
            // Retry the original request
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $_accessToken';
            final response = await _dio.fetch(options);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  // Simple in-memory demo data for offline mode
  static const _demoUser = {
    'id': 1,
    'email': 'demo@3ialna.app',
    'firstName': 'Demo',
    'lastName': 'User',
    'role': 'parent',
    'phone': null,
    'profileImage': null,
    'createdAt': '2023-01-01T00:00:00.000Z',
    'updatedAt': '2023-01-01T00:00:00.000Z',
    'isActive': true,
    'language': 'en',
    'country': 'SA',
    'timezone': 'Asia/Riyadh',
  };

  static final _demoDevices = [
    {
      'id': 1,
      'parentId': 1,
      'deviceName': 'Demo Phone',
      'deviceId': 'DEMO-DEVICE-1',
      'deviceType': 'android',
      'childName': 'Ahmed',
      'childAge': 10,
      'childGender': 'male',
      'isActive': true,
      'lastSeen': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'settings': {
        'lockDurationMinutes': AppConstants.defaultLockDuration,
        'appUsageLimitMinutes': AppConstants.defaultAppLimit,
        'notificationMessage': 'Prayer time - device will lock',
        'language': 'en',
        'appLimits': {'com.facebook.katana': 30, 'com.instagram.android': 30},
        'prayerSettings': {
          'fajrLockMinutes': 20,
          'dhuhrLockMinutes': 15,
          'asrLockMinutes': 15,
          'maghribLockMinutes': 20,
          'ishaLockMinutes': 25,
          'fridayDhuhrLockMinutes': 40,
          'notificationMessage': 'Prayer time',
          'isEnabled': true,
        },
        'isLocked': false,
        'lockUntil': null,
        'blockedApps': [],
        'allowedApps': [],
      },
      'appliedProfileId': null,
    }
  ];

  // Authentication Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (AppConstants.offlineMode) {
      // Create fake tokens and save them
      _accessToken = 'DEMO_ACCESS_TOKEN';
      _refreshToken = 'DEMO_REFRESH_TOKEN';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _accessToken!);
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
      await prefs.setString(AppConstants.userRoleKey, _demoUser['role']);

      return {
        'success': true,
        'data': {
          'tokens': {
            'accessToken': _accessToken,
            'refreshToken': _refreshToken,
          },
          'user': _demoUser,
        }
      };
    }

    try {
      final response = await _dio.post(AppConstants.loginEndpoint, data: {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final data = response.data['data'];
        _accessToken = data['tokens']['accessToken'];
        _refreshToken = data['tokens']['refreshToken'];
        
        // Store tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _accessToken!);
        await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        await prefs.setString(AppConstants.userRoleKey, data['user']['role']);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    if (AppConstants.offlineMode) {
      // Return created user (merge incoming data with demo defaults)
      final created = Map<String, dynamic>.from(_demoUser)..addAll(userData);
      _accessToken = 'DEMO_ACCESS_TOKEN';
      _refreshToken = 'DEMO_REFRESH_TOKEN';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, _accessToken!);
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
      await prefs.setString(AppConstants.userRoleKey, created['role']);

      return {
        'success': true,
        'data': {
          'tokens': {'accessToken': _accessToken, 'refreshToken': _refreshToken},
          'user': created,
        }
      };
    }

    try {
      final response = await _dio.post(AppConstants.registerEndpoint, data: userData);
      
      if (response.data['success']) {
        final data = response.data['data'];
        _accessToken = data['tokens']['accessToken'];
        _refreshToken = data['tokens']['refreshToken'];
        
        // Store tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _accessToken!);
        await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        await prefs.setString(AppConstants.userRoleKey, data['user']['role']);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      if (!AppConstants.offlineMode) {
        if (_accessToken != null) {
          await _dio.post(AppConstants.logoutEndpoint);
        }
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _accessToken = null;
      _refreshToken = null;
      
      // Clear stored tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.userRoleKey);
    }
  }

  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return false;

      final response = await _dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refreshToken': _refreshToken},
      );

      if (response.data['success']) {
        final data = response.data['data'];
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        
        // Update stored tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, _accessToken!);
        await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // User Management
  Future<User> getUserProfile() async {
    if (AppConstants.offlineMode) {
      return User.fromJson(Map<String, dynamic>.from(_demoUser));
    }

    try {
      final response = await _dio.get(AppConstants.profileEndpoint);
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put(
        AppConstants.updateProfileEndpoint,
        data: profileData,
      );
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Child Device Management
  Future<List<ChildDevice>> getChildDevices() async {
    if (AppConstants.offlineMode) {
      return _demoDevices.map((d) => ChildDevice.fromJson(Map<String, dynamic>.from(d))).toList();
    }

    try {
      final response = await _dio.get(AppConstants.childDevicesEndpoint);
      final List<dynamic> devices = response.data['data'];
      return devices.map((device) => ChildDevice.fromJson(device)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChildDevice> registerChildDevice(Map<String, dynamic> deviceData) async {
    try {
      final response = await _dio.post(
        AppConstants.childDevicesEndpoint,
        data: deviceData,
      );
      return ChildDevice.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChildDevice> updateChildDeviceSettings(
    int deviceId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _dio.put(
        AppConstants.childDeviceSettingsEndpoint.replaceAll('{id}', deviceId.toString()),
        data: settings,
      );
      return ChildDevice.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<DailyReport>> getChildDeviceReports(
    int deviceId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _dio.get(
        AppConstants.childDeviceReportsEndpoint.replaceAll('{id}', deviceId.toString()),
        queryParameters: {
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      final List<dynamic> reports = response.data['data'];
      return reports.map((report) => DailyReport.fromJson(report)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Master Parent Features
  Future<List<MasterParentProfile>> getMasterParentProfiles({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.masterProfilesEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      final List<dynamic> profiles = response.data['data'];
      return profiles.map((profile) => MasterParentProfile.fromJson(profile)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<DefaultProfile>> getDefaultProfiles({
    int? masterParentId,
    String? gender,
    String? ageGroup,
    String? motherTongue,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.masterProfilesEndpoint,
        queryParameters: {
          if (masterParentId != null) 'masterParentId': masterParentId,
          if (gender != null) 'gender': gender,
          if (ageGroup != null) 'ageGroup': ageGroup,
          if (motherTongue != null) 'motherTongue': motherTongue,
        },
      );
      final List<dynamic> profiles = response.data['data'];
      return profiles.map((profile) => DefaultProfile.fromJson(profile)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Prayer Times
  Future<List<PrayerTime>> getPrayerTimes(
    double latitude,
    double longitude,
    DateTime date,
  ) async {
    try {
      final response = await _dio.get(
        AppConstants.prayerTimesEndpoint,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'date': date.toIso8601String().split('T')[0],
        },
      );
      final List<dynamic> prayerTimes = response.data['data']['prayerTimes'];
      return prayerTimes.map((time) => PrayerTime.fromJson(time)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // App Usage
  Future<List<AppUsage>> getTopApps(int deviceId, {String period = 'week'}) async {
    try {
      final response = await _dio.get(
        AppConstants.appUsageEndpoint,
        queryParameters: {
          'deviceId': deviceId,
          'period': period,
        },
      );
      final List<dynamic> apps = response.data['data'];
      return apps.map((app) => AppUsage.fromJson(app)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitAppUsage(int deviceId, Map<String, dynamic> usageData) async {
    try {
      await _dio.post(
        AppConstants.appUsageEndpoint,
        data: {
          'deviceId': deviceId,
          ...usageData,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Initialize tokens from storage
  Future<void> initializeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.tokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);

    // If offline mode and no tokens exist, create demo tokens so auth flow recognizes user
    if (AppConstants.offlineMode && _accessToken == null) {
      _accessToken = 'DEMO_ACCESS_TOKEN';
      _refreshToken = 'DEMO_REFRESH_TOKEN';
      await prefs.setString(AppConstants.tokenKey, _accessToken!);
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
      await prefs.setString(AppConstants.userRoleKey, _demoUser['role']);
    }
  }

  bool get isAuthenticated => _accessToken != null;

  String? get userRole {
    // This would typically be decoded from the JWT token
    // For now, we'll get it from storage
    return null; // Will be implemented with JWT decoding
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        return Exception(data['error']['message'] ?? 'An error occurred');
      }
    }
    return Exception('Network error occurred');
  }
}
