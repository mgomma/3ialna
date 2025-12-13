import 'dart:developer' as developer;

import 'package:app_usage/app_usage.dart';

import '../../core/constants/social_media_apps.dart';

/// Provides read-only access to app usage information.
class AppUsageService {
  const AppUsageService();

  /// Loads today's usage summary, including tracked social apps and total usage.
  Future<AppUsageSummary> loadTodayUsageSummary() async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    try {
      final AppUsage appUsage = AppUsage();
      final List<AppUsageInfo> infos =
          await appUsage.getAppUsage(startOfDay, now);

      final Map<String, int> perApp = {};
      int totalMinutes = 0;

      for (final AppUsageInfo info in infos) {
        // Round up to the nearest minute so short sessions are not ignored.
        final int minutes = (info.usage.inSeconds + 59) ~/ 60;
        totalMinutes += minutes;

        final String packageName = info.packageName;
        if (!socialMediaApps.containsKey(packageName)) {
          continue;
        }

        perApp[packageName] = (perApp[packageName] ?? 0) + minutes;
      }

      return AppUsageSummary(
        perAppMinutes: perApp,
        totalMinutes: totalMinutes,
      );
    } catch (e, s) {
      developer.log(
        'Failed to load app usage',
        name: 'social_media_limiter.usage',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return const AppUsageSummary(
        perAppMinutes: <String, int>{},
        totalMinutes: 0,
      );
    }
  }

  /// Gets today's usage for a specific app in minutes.
  Future<int> getTodayUsageForApp(String packageName) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    try {
      final AppUsage appUsage = AppUsage();
      final List<AppUsageInfo> infos =
          await appUsage.getAppUsage(startOfDay, now);

      int totalMinutes = 0;
      for (final AppUsageInfo info in infos) {
        if (info.packageName == packageName) {
          final int minutes = (info.usage.inSeconds + 59) ~/ 60;
          totalMinutes += minutes;
        }
      }

      return totalMinutes;
    } catch (e, s) {
      developer.log(
        'Failed to load app usage for $packageName',
        name: 'social_media_limiter.usage',
        error: e,
        stackTrace: s,
        level: 1000,
      );
      return 0;
    }
  }
}

/// Simple data holder for usage summaries.
class AppUsageSummary {
  const AppUsageSummary({
    required this.perAppMinutes,
    required this.totalMinutes,
  });

  final Map<String, int> perAppMinutes;
  final int totalMinutes;
}
