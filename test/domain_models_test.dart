import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/domain/models/daily_usage_report.dart';
import 'package:mu_super_app/domain/models/local_user_profile.dart';
import 'package:mu_super_app/domain/models/usage_stats.dart';

void main() {
  group('UsageStats', () {
    test('calculates and formats usage durations', () {
      const stats = UsageStats(
        packageName: 'com.example.app',
        appName: 'Example',
        totalTimeInForeground: 2 * 60 * 60 * 1000 + 30 * 60 * 1000,
        lastTimeUsed: 100,
        firstTimeStamp: 50,
        lastTimeStamp: 100,
      );

      expect(stats.totalMinutes, 150);
      expect(stats.totalHours, 2.5);
      expect(stats.formattedTime, '2h 30m');
    });

    test('formats durations below one hour in minutes', () {
      const stats = UsageStats(
        packageName: 'com.example.app',
        appName: 'Example',
        totalTimeInForeground: 90 * 1000,
        lastTimeUsed: 0,
        firstTimeStamp: 0,
        lastTimeStamp: 0,
      );

      expect(stats.totalMinutes, 2);
      expect(stats.formattedTime, '2m');
    });

    test('round-trips through a map and applies missing numeric defaults', () {
      final stats = UsageStats.fromMap(const <String, dynamic>{
        'packageName': 'com.example.app',
        'appName': 'Example',
      });

      expect(stats.totalTimeInForeground, 0);
      expect(stats.lastTimeUsed, 0);
      expect(stats.firstTimeStamp, 0);
      expect(stats.lastTimeStamp, 0);
      expect(stats.toMap(), const <String, dynamic>{
        'packageName': 'com.example.app',
        'appName': 'Example',
        'totalTimeInForeground': 0,
        'lastTimeUsed': 0,
        'firstTimeStamp': 0,
        'lastTimeStamp': 0,
      });
    });
  });

  group('DailyUsageStats', () {
    test('returns app usage and formats total device usage', () {
      const stats = UsageStats(
        packageName: 'com.example.app',
        appName: 'Example',
        totalTimeInForeground: 30 * 60 * 1000,
        lastTimeUsed: 0,
        firstTimeStamp: 0,
        lastTimeStamp: 0,
      );
      final daily = DailyUsageStats(
        date: DateTime(2026, 8, 16),
        appStats: <String, UsageStats>{stats.packageName: stats},
        totalDeviceUsage: 90,
      );

      expect(daily.getAppUsage('com.example.app'), 30);
      expect(daily.getAppUsage('missing'), 0);
      expect(daily.formattedTotalUsage, '1h 30m');
    });
  });

  group('DailyUsageReport', () {
    test('round-trips nested usage maps and preserves sync state', () {
      final report = DailyUsageReport.fromMap(const <String, dynamic>{
        'id': 'report-1',
        'date': '2026-08-16',
        'totalUsageMinutes': 75,
        'appUsage': <String, dynamic>{'com.example.app': 45},
        'categoryUsage': <String, dynamic>{'education': 30},
        'isSynced': true,
      });

      expect(report.appUsage, const <String, int>{'com.example.app': 45});
      expect(report.categoryUsage, const <String, int>{'education': 30});
      expect(report.isSynced, isTrue);
      expect(report.toMap(), const <String, dynamic>{
        'id': 'report-1',
        'date': '2026-08-16',
        'totalUsageMinutes': 75,
        'appUsage': <String, int>{'com.example.app': 45},
        'categoryUsage': <String, int>{'education': 30},
        'isSynced': true,
      });
    });

    test('uses safe defaults for optional persisted fields', () {
      final report = DailyUsageReport.fromMap(const <String, dynamic>{
        'id': 'report-2',
        'date': '2026-08-17',
      });

      expect(report.totalUsageMinutes, 0);
      expect(report.appUsage, isEmpty);
      expect(report.categoryUsage, isEmpty);
      expect(report.isSynced, isFalse);
    });

    test('copyWith changes selected fields and retains the rest', () {
      const original = DailyUsageReport(
        id: 'report-1',
        date: '2026-08-16',
        totalUsageMinutes: 75,
        appUsage: <String, int>{'com.example.app': 45},
        categoryUsage: <String, int>{'education': 30},
      );

      final updated = original.copyWith(
        totalUsageMinutes: 90,
        isSynced: true,
      );

      expect(updated.id, original.id);
      expect(updated.date, original.date);
      expect(updated.totalUsageMinutes, 90);
      expect(updated.appUsage, original.appUsage);
      expect(updated.categoryUsage, original.categoryUsage);
      expect(updated.isSynced, isTrue);
    });
  });

  group('LocalUserProfile', () {
    test('applies defaults when loading a partial map', () {
      final profile = LocalUserProfile.fromMap(const <String, dynamic>{
        'email': 'parent@example.com',
      });

      expect(profile.email, 'parent@example.com');
      expect(profile.firstName, isEmpty);
      expect(profile.lastName, isEmpty);
      expect(profile.phone, isEmpty);
      expect(profile.country, isEmpty);
      expect(profile.language, 'ar');
      expect(profile.isRegistered, isFalse);
    });

    test('copyWith updates profile fields without losing optional data', () {
      const original = LocalUserProfile(
        email: 'parent@example.com',
        firstName: 'Amina',
        lastName: 'Ali',
        phone: '+123',
        country: 'Egypt',
        language: 'en',
        accessToken: 'access-token',
        childDeviceId: 'child-1',
      );

      final updated = original.copyWith(
        firstName: 'Mariam',
        isRegistered: true,
      );

      expect(updated.firstName, 'Mariam');
      expect(updated.lastName, original.lastName);
      expect(updated.accessToken, original.accessToken);
      expect(updated.childDeviceId, original.childDeviceId);
      expect(updated.isRegistered, isTrue);
    });

    test('serializes all profile fields to a map', () {
      const profile = LocalUserProfile(
        email: 'parent@example.com',
        firstName: 'Amina',
        lastName: 'Ali',
        phone: '+123',
        country: 'Egypt',
        language: 'ar',
        authProvider: 'google',
        providerUserId: 'google-1',
        isRegistered: true,
      );

      expect(profile.toMap(), const <String, dynamic>{
        'email': 'parent@example.com',
        'firstName': 'Amina',
        'lastName': 'Ali',
        'phone': '+123',
        'country': 'Egypt',
        'language': 'ar',
        'accessToken': null,
        'refreshToken': null,
        'childDeviceId': null,
        'deviceToken': null,
        'authProvider': 'google',
        'providerUserId': 'google-1',
        'isRegistered': true,
      });
    });
  });
}
