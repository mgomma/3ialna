/// Model representing app usage statistics.
class UsageStats {
  final String packageName;
  final String appName;
  final int totalTimeInForeground; // milliseconds
  final int lastTimeUsed; // timestamp
  final int firstTimeStamp; // timestamp
  final int lastTimeStamp; // timestamp

  const UsageStats({
    required this.packageName,
    required this.appName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    required this.firstTimeStamp,
    required this.lastTimeStamp,
  });

  /// Gets total usage time in minutes.
  int get totalMinutes => (totalTimeInForeground / 1000 / 60).round();

  /// Gets total usage time in hours.
  double get totalHours => totalTimeInForeground / 1000 / 60 / 60;

  /// Gets formatted usage time string (e.g., "2h 30m").
  String get formattedTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory UsageStats.fromMap(Map<String, dynamic> map) {
    return UsageStats(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      totalTimeInForeground: map['totalTimeInForeground'] as int? ?? 0,
      lastTimeUsed: map['lastTimeUsed'] as int? ?? 0,
      firstTimeStamp: map['firstTimeStamp'] as int? ?? 0,
      lastTimeStamp: map['lastTimeStamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'totalTimeInForeground': totalTimeInForeground,
      'lastTimeUsed': lastTimeUsed,
      'firstTimeStamp': firstTimeStamp,
      'lastTimeStamp': lastTimeStamp,
    };
  }
}

/// Model representing daily usage statistics.
class DailyUsageStats {
  final DateTime date;
  final Map<String, UsageStats> appStats;
  final int totalDeviceUsage; // minutes

  const DailyUsageStats({
    required this.date,
    required this.appStats,
    required this.totalDeviceUsage,
  });

  /// Gets total usage for a specific app in minutes.
  int getAppUsage(String packageName) {
    return appStats[packageName]?.totalMinutes ?? 0;
  }

  /// Gets formatted total device usage.
  String get formattedTotalUsage {
    final hours = totalDeviceUsage ~/ 60;
    final minutes = totalDeviceUsage % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

