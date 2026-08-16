import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_usage_report.dart';

class ReportStorageService {
  static const String _keyReports = 'daily_usage_reports';

  Future<List<DailyUsageReport>> loadReports() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_keyReports) ?? <String>[];

    final List<DailyUsageReport> reports = <DailyUsageReport>[];
    for (final String item in raw) {
      try {
        final Map<String, dynamic> map = jsonDecode(item) as Map<String, dynamic>;
        reports.add(DailyUsageReport.fromMap(map));
      } catch (_) {
        // Skip malformed local records.
      }
    }
    return reports;
  }

  Future<void> saveReports(List<DailyUsageReport> reports) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> encoded = reports
        .map((DailyUsageReport report) => jsonEncode(report.toMap()))
        .toList();
    await prefs.setStringList(_keyReports, encoded);
  }

  Future<void> addReport(DailyUsageReport report) async {
    final List<DailyUsageReport> reports = await loadReports();
    reports.add(report);
    await saveReports(reports);
  }

  Future<void> markSynced(String reportId) async {
    final List<DailyUsageReport> reports = await loadReports();
    final List<DailyUsageReport> updated = reports
        .map((DailyUsageReport report) =>
            report.id == reportId ? report.copyWith(isSynced: true) : report)
        .toList();
    await saveReports(updated);
  }

  Future<List<DailyUsageReport>> loadPendingReports() async {
    final List<DailyUsageReport> reports = await loadReports();
    return reports.where((DailyUsageReport report) => !report.isSynced).toList();
  }
}
