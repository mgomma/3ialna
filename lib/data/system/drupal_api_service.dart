import 'dart:convert';
import 'dart:io';

import '../../domain/models/daily_usage_report.dart';

class DrupalApiService {
  const DrupalApiService({
    this.baseUrl = 'https://3ialna.net/api/v1',
  });

  final String baseUrl;

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String country,
    required String language,
  }) {
    return _post(
      '/auth/register',
      body: <String, dynamic>{
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'country': country,
        'language': language,
      },
    );
  }

  Future<Map<String, dynamic>> registerUserWithSocial({
    required String provider,
    required String providerUserId,
    required String email,
    required String firstName,
    required String lastName,
    required String country,
    required String language,
    String? accessToken,
    String? idToken,
    String? authorizationCode,
  }) {
    return _post(
      '/auth/social/$provider',
      body: <String, dynamic>{
        'provider': provider,
        'providerUserId': providerUserId,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'country': country,
        'language': language,
        if (accessToken != null && accessToken.isNotEmpty) 'accessToken': accessToken,
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        if (authorizationCode != null && authorizationCode.isNotEmpty) 'authorizationCode': authorizationCode,
      },
    );
  }

  Future<Map<String, dynamic>> registerChildDevice({
    required String accessToken,
    required String deviceName,
    required String deviceId,
    required String childName,
  }) {
    return _post(
      '/child-devices',
      bearerToken: accessToken,
      body: <String, dynamic>{
        'deviceName': deviceName,
        'deviceId': deviceId,
        'deviceType': Platform.isIOS ? 'ios' : 'android',
        'childName': childName,
      },
    );
  }

  Future<void> submitDailyReport({
    required String bearerToken,
    required String childDeviceId,
    required DailyUsageReport report,
  }) async {
    await _post(
      '/child-devices/$childDeviceId/daily-report',
      bearerToken: bearerToken,
      body: <String, dynamic>{
        'date': report.date,
        'totalUsageMinutes': report.totalUsageMinutes,
        'appUsage': report.appUsage,
        'categoryUsage': report.categoryUsage,
      },
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    String? bearerToken,
  }) async {
    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse('$baseUrl$path');
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      }
      request.write(jsonEncode(body));

      final HttpClientResponse response = await request.close();
      final String payload = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $payload');
      }

      if (payload.isEmpty) {
        return <String, dynamic>{};
      }

      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'data': decoded};
    } finally {
      client.close(force: true);
    }
  }
}
