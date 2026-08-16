import 'dart:io';

import '../local/report_storage_service.dart';
import '../local/user_profile_storage_service.dart';
import '../../domain/models/daily_usage_report.dart';
import '../../domain/models/local_user_profile.dart';
import '../../domain/models/social_auth_profile.dart';
import 'drupal_api_service.dart';

class DrupalSyncService {
  DrupalSyncService({
    DrupalApiService? api,
    UserProfileStorageService? userProfileStorage,
    ReportStorageService? reportStorage,
  })  : _api = api ?? const DrupalApiService(),
        _userProfileStorage = userProfileStorage ?? UserProfileStorageService(),
        _reportStorage = reportStorage ?? ReportStorageService();

  final DrupalApiService _api;
  final UserProfileStorageService _userProfileStorage;
  final ReportStorageService _reportStorage;

  Future<LocalUserProfile?> getProfile() {
    return _userProfileStorage.loadProfile();
  }

  Future<void> saveLocalProfile(LocalUserProfile profile) {
    return _userProfileStorage.saveProfile(profile);
  }

  Future<LocalUserProfile> registerAndLinkDevice({
    required LocalUserProfile profile,
    required String password,
  }) async {
    await _userProfileStorage.saveProfile(profile.copyWith(isRegistered: false));

    final Map<String, dynamic> registerResponse = await _api.registerUser(
      email: profile.email,
      password: password,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phone: profile.phone,
      country: profile.country,
      language: profile.language,
    );

    final Map<String, dynamic> data =
        registerResponse['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> tokens =
        data['tokens'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final String? accessToken = tokens['accessToken'] as String?;
    final String? refreshToken = tokens['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const HttpException('Registration succeeded but access token is missing.');
    }

    final String deviceId = await _resolveDeviceId();
    final String deviceName = "${profile.firstName}'s Device";

    final Map<String, dynamic> deviceResponse = await _api.registerChildDevice(
      accessToken: accessToken,
      deviceName: deviceName,
      deviceId: deviceId,
      childName: profile.firstName,
    );

    final Map<String, dynamic> deviceData =
        deviceResponse['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final dynamic rawDeviceId =
        deviceData['id'] ?? deviceData['deviceId'] ?? deviceData['childDeviceId'];
    final String? childDeviceId = rawDeviceId?.toString();
    final String? deviceToken = deviceData['deviceToken'] as String?;

    final LocalUserProfile registered = profile.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      childDeviceId: childDeviceId,
      deviceToken: deviceToken,
      isRegistered: true,
    );

    await _userProfileStorage.saveProfile(registered);
    await syncPendingReports();
    return registered;
  }

  Future<LocalUserProfile> registerAndLinkDeviceWithSocial({
    required LocalUserProfile profile,
    required SocialAuthProfile social,
  }) async {
    await _userProfileStorage.saveProfile(profile.copyWith(isRegistered: false));

    Map<String, dynamic> registerResponse;
    try {
      registerResponse = await _api.registerUserWithSocial(
        provider: social.provider,
        providerUserId: social.providerUserId,
        email: profile.email,
        firstName: profile.firstName,
        lastName: profile.lastName,
        country: profile.country,
        language: profile.language,
        accessToken: social.accessToken,
        idToken: social.idToken,
        authorizationCode: social.authorizationCode,
      );
    } catch (_) {
      // Backward-compatible fallback while social endpoint may still be pending.
      final String fallbackPassword =
          'S0cial_${social.provider}_${DateTime.now().millisecondsSinceEpoch}!';
      return registerAndLinkDevice(profile: profile, password: fallbackPassword);
    }

    final Map<String, dynamic> data =
        registerResponse['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> tokens =
        data['tokens'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final String? accessToken = tokens['accessToken'] as String?;
    final String? refreshToken = tokens['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const HttpException('Social registration succeeded but access token is missing.');
    }

    final String deviceId = await _resolveDeviceId();
    final String deviceName = "${profile.firstName}'s Device";

    final Map<String, dynamic> deviceResponse = await _api.registerChildDevice(
      accessToken: accessToken,
      deviceName: deviceName,
      deviceId: deviceId,
      childName: profile.firstName,
    );

    final Map<String, dynamic> deviceData =
        deviceResponse['data'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final dynamic rawDeviceId =
        deviceData['id'] ?? deviceData['deviceId'] ?? deviceData['childDeviceId'];
    final String? childDeviceId = rawDeviceId?.toString();
    final String? deviceToken = deviceData['deviceToken'] as String?;

    final LocalUserProfile registered = profile.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      childDeviceId: childDeviceId,
      deviceToken: deviceToken,
      isRegistered: true,
    );

    await _userProfileStorage.saveProfile(registered);
    await syncPendingReports();
    return registered;
  }

  Future<void> submitReport(DailyUsageReport report) async {
    await _reportStorage.addReport(report);

    final LocalUserProfile? profile = await _userProfileStorage.loadProfile();
    if (profile == null || !profile.isRegistered) {
      return;
    }

    final String? token = profile.deviceToken ?? profile.accessToken;
    final String? deviceId = profile.childDeviceId;

    if (token == null || token.isEmpty || deviceId == null || deviceId.isEmpty) {
      return;
    }

    try {
      await _api.submitDailyReport(
        bearerToken: token,
        childDeviceId: deviceId,
        report: report,
      );
      await _reportStorage.markSynced(report.id);
    } catch (_) {
      // Keep local report unsynced for future retry.
    }
  }

  Future<void> syncPendingReports() async {
    final LocalUserProfile? profile = await _userProfileStorage.loadProfile();
    if (profile == null || !profile.isRegistered) {
      return;
    }

    final String? token = profile.deviceToken ?? profile.accessToken;
    final String? deviceId = profile.childDeviceId;
    if (token == null || token.isEmpty || deviceId == null || deviceId.isEmpty) {
      return;
    }

    final List<DailyUsageReport> pending = await _reportStorage.loadPendingReports();
    for (final DailyUsageReport report in pending) {
      try {
        await _api.submitDailyReport(
          bearerToken: token,
          childDeviceId: deviceId,
          report: report,
        );
        await _reportStorage.markSynced(report.id);
      } catch (_) {
        break;
      }
    }
  }

  Future<String> _resolveDeviceId() async {
    final LocalUserProfile? profile = await _userProfileStorage.loadProfile();
    if (profile?.childDeviceId != null && profile!.childDeviceId!.isNotEmpty) {
      return profile.childDeviceId!;
    }
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
  }
}
