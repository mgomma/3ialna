class DailyUsageReport {
  const DailyUsageReport({
    required this.id,
    required this.date,
    required this.totalUsageMinutes,
    required this.appUsage,
    required this.categoryUsage,
    this.isSynced = false,
  });

  final String id;
  final String date;
  final int totalUsageMinutes;
  final Map<String, int> appUsage;
  final Map<String, int> categoryUsage;
  final bool isSynced;

  DailyUsageReport copyWith({
    String? id,
    String? date,
    int? totalUsageMinutes,
    Map<String, int>? appUsage,
    Map<String, int>? categoryUsage,
    bool? isSynced,
  }) {
    return DailyUsageReport(
      id: id ?? this.id,
      date: date ?? this.date,
      totalUsageMinutes: totalUsageMinutes ?? this.totalUsageMinutes,
      appUsage: appUsage ?? this.appUsage,
      categoryUsage: categoryUsage ?? this.categoryUsage,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory DailyUsageReport.fromMap(Map<String, dynamic> map) {
    return DailyUsageReport(
      id: map['id'] as String,
      date: map['date'] as String,
      totalUsageMinutes: map['totalUsageMinutes'] as int? ?? 0,
      appUsage: (map['appUsage'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((String key, dynamic value) => MapEntry(key, value as int)),
      categoryUsage: (map['categoryUsage'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .map((String key, dynamic value) => MapEntry(key, value as int)),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date,
      'totalUsageMinutes': totalUsageMinutes,
      'appUsage': appUsage,
      'categoryUsage': categoryUsage,
      'isSynced': isSynced,
    };
  }
}
