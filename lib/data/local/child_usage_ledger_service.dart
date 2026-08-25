import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../system/app_usage_service.dart';

/// A locally stored usage total for one child on one calendar day.
///
/// Child identifiers are used only on the device to let a parent filter the
/// on-device report. They are deliberately not attached to diagnostic exports
/// or remote report payloads.
class ChildUsageLedgerEntry {
  const ChildUsageLedgerEntry({
    required this.childId,
    required this.day,
    required this.totalMinutes,
    required this.appUsageMinutes,
  });

  final String childId;
  final String day;
  final int totalMinutes;
  final Map<String, int> appUsageMinutes;

  ChildUsageLedgerEntry copyWith({
    int? totalMinutes,
    Map<String, int>? appUsageMinutes,
  }) =>
      ChildUsageLedgerEntry(
        childId: childId,
        day: day,
        totalMinutes: totalMinutes ?? this.totalMinutes,
        appUsageMinutes: appUsageMinutes ?? this.appUsageMinutes,
      );

  Map<String, Object> toJson() => <String, Object>{
        'childId': childId,
        'day': day,
        'totalMinutes': totalMinutes,
        'appUsageMinutes': appUsageMinutes,
      };

  factory ChildUsageLedgerEntry.fromJson(Map<String, dynamic> json) =>
      ChildUsageLedgerEntry(
        childId: json['childId'] as String? ?? '',
        day: json['day'] as String? ?? '',
        totalMinutes: json['totalMinutes'] as int? ?? 0,
        appUsageMinutes:
            (json['appUsageMinutes'] as Map<String, dynamic>? ??
                    <String, dynamic>{})
                .map(
          (String key, dynamic value) =>
              MapEntry<String, int>(key, value as int? ?? 0),
        ),
      );
}

class ChildUsageLedgerAggregate {
  const ChildUsageLedgerAggregate({
    required this.totalMinutes,
    required this.appUsageMinutes,
  });

  final int totalMinutes;
  final Map<String, int> appUsageMinutes;
}

/// Attributes usage deltas to the child who is selected when that usage is
/// observed. Android does not identify individual people in its UsageStats
/// data, so usage before the first local observation cannot be retroactively
/// assigned to a child.
class ChildUsageLedgerService {
  const ChildUsageLedgerService({this.enableFileArchive = true});

  final bool enableFileArchive;

  static const String _entriesKey = 'child_usage_ledger_entries_v1';
  static const String _baselineKey = 'child_usage_ledger_baseline_v1';
  static const String _archiveFileName = '3ialna_child_usage_history_v1.json';

  Future<ChildUsageLedgerEntry> captureActiveChildUsage({
    required String childId,
    DateTime? observedAt,
  }) async {
    final AppUsageSummary summary =
        await const AppUsageService().loadTodayUsageSummary();
    return recordObservedUsage(
      childId: childId,
      observedUsage: summary,
      observedAt: observedAt,
    );
  }

  Future<ChildUsageLedgerEntry> recordObservedUsage({
    required String childId,
    required AppUsageSummary observedUsage,
    DateTime? observedAt,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final DateTime observed = observedAt ?? DateTime.now();
    final String day = _dayKey(observed);
    final _UsageBaseline baseline = _readBaseline(preferences);
    final List<ChildUsageLedgerEntry> entries = await _loadEntries(preferences);
    final bool isNewDay = baseline.day != day;

    if (isNewDay) {
      await _save(
        preferences,
        entries,
        _UsageBaseline.fromUsage(day: day, usage: observedUsage),
      );
      return _findOrEmpty(entries, childId: childId, day: day);
    }

    final int totalDelta = (observedUsage.totalMinutes - baseline.totalMinutes)
        .clamp(0, 1 << 30)
        .toInt();
    final Map<String, int> appDeltas = <String, int>{};
    for (final MapEntry<String, int> app in observedUsage.perAppMinutes.entries) {
      final int delta = (app.value - (baseline.appUsageMinutes[app.key] ?? 0))
          .clamp(0, 1 << 30)
          .toInt();
      if (delta > 0) appDeltas[app.key] = delta;
    }

    final int index = entries.indexWhere(
      (ChildUsageLedgerEntry entry) =>
          entry.childId == childId && entry.day == day,
    );
    final ChildUsageLedgerEntry previous = index == -1
        ? ChildUsageLedgerEntry(
            childId: childId,
            day: day,
            totalMinutes: 0,
            appUsageMinutes: const <String, int>{},
          )
        : entries[index];
    final Map<String, int> updatedApps =
        Map<String, int>.from(previous.appUsageMinutes);
    for (final MapEntry<String, int> app in appDeltas.entries) {
      updatedApps[app.key] = (updatedApps[app.key] ?? 0) + app.value;
    }
    final ChildUsageLedgerEntry updated = previous.copyWith(
      totalMinutes: previous.totalMinutes + totalDelta,
      appUsageMinutes: updatedApps,
    );
    if (index == -1) {
      entries.add(updated);
    } else {
      entries[index] = updated;
    }
    await _save(
      preferences,
      entries,
      _UsageBaseline.fromUsage(day: day, usage: observedUsage),
    );
    return updated;
  }

  Future<ChildUsageLedgerAggregate> loadAggregate({
    String? childId,
    required DateTime start,
    required DateTime end,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String firstDay = _dayKey(start);
    final String lastDay = _dayKey(end);
    int totalMinutes = 0;
    final Map<String, int> appUsage = <String, int>{};
    for (final ChildUsageLedgerEntry entry in await _loadEntries(preferences)) {
      if (entry.day.compareTo(firstDay) < 0 || entry.day.compareTo(lastDay) > 0) {
        continue;
      }
      if (childId != null && entry.childId != childId) continue;
      totalMinutes += entry.totalMinutes;
      for (final MapEntry<String, int> app in entry.appUsageMinutes.entries) {
        appUsage[app.key] = (appUsage[app.key] ?? 0) + app.value;
      }
    }
    return ChildUsageLedgerAggregate(
      totalMinutes: totalMinutes,
      appUsageMinutes: appUsage,
    );
  }

  Future<List<ChildUsageLedgerEntry>> loadEntries() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return _loadEntries(preferences);
  }

  /// Removes only the selected child’s local history. Parent-facing UI must
  /// require parent authentication before calling this destructive operation.
  Future<void> deleteHistoryForChild(String childId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<ChildUsageLedgerEntry> remaining =
        (await _loadEntries(preferences))
            .where((ChildUsageLedgerEntry entry) => entry.childId != childId)
            .toList(growable: false);
    await _save(preferences, remaining, _readBaseline(preferences));
  }

  /// Returns the private application-document archive path when the platform
  /// exposes one. The archive is never attached to diagnostics or config packs.
  Future<String?> archivePath() async {
    if (!enableFileArchive) return null;
    try {
      return (await _archiveFile()).path;
    } catch (_) {
      return null;
    }
  }

  Future<List<ChildUsageLedgerEntry>> _loadEntries(
    SharedPreferences preferences,
  ) async {
    if (enableFileArchive) {
      try {
        final File archive = await _archiveFile();
        if (await archive.exists()) {
          final List<ChildUsageLedgerEntry> entries =
              _decodeEntries(await archive.readAsString());
          if (entries.isNotEmpty) return entries;
        }
      } catch (_) {
        // Preference cache remains the compatible local fallback in tests and
        // on any device where the document directory is temporarily unavailable.
      }
    }
    return _readEntries(preferences);
  }

  List<ChildUsageLedgerEntry> _readEntries(SharedPreferences preferences) {
    return _decodeEntries(preferences.getString(_entriesKey) ?? '[]');
  }

  List<ChildUsageLedgerEntry> _decodeEntries(String raw) {
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ChildUsageLedgerEntry.fromJson)
          .where((ChildUsageLedgerEntry entry) =>
              entry.childId.isNotEmpty && entry.day.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return <ChildUsageLedgerEntry>[];
    }
  }

  _UsageBaseline _readBaseline(SharedPreferences preferences) {
    final String raw = preferences.getString(_baselineKey) ?? '{}';
    try {
      return _UsageBaseline.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const _UsageBaseline(
        day: '',
        totalMinutes: 0,
        appUsageMinutes: <String, int>{},
      );
    }
  }

  Future<void> _save(
    SharedPreferences preferences,
    List<ChildUsageLedgerEntry> entries,
    _UsageBaseline baseline,
  ) async {
    await preferences.setString(
      _entriesKey,
      jsonEncode(entries.map((ChildUsageLedgerEntry entry) => entry.toJson()).toList()),
    );
    await preferences.setString(_baselineKey, jsonEncode(baseline.toJson()));
    if (enableFileArchive) {
      try {
        final File archive = await _archiveFile();
        await archive.writeAsString(
          jsonEncode(entries.map((ChildUsageLedgerEntry entry) => entry.toJson()).toList()),
          flush: true,
        );
      } catch (_) {
        // SharedPreferences retains the on-device fallback if file I/O fails.
      }
    }
  }

  Future<File> _archiveFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_archiveFileName');
  }

  ChildUsageLedgerEntry _findOrEmpty(
    List<ChildUsageLedgerEntry> entries, {
    required String childId,
    required String day,
  }) =>
      entries.firstWhere(
        (ChildUsageLedgerEntry entry) =>
            entry.childId == childId && entry.day == day,
        orElse: () => ChildUsageLedgerEntry(
          childId: childId,
          day: day,
          totalMinutes: 0,
          appUsageMinutes: const <String, int>{},
        ),
      );

  String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _UsageBaseline {
  const _UsageBaseline({
    required this.day,
    required this.totalMinutes,
    required this.appUsageMinutes,
  });

  final String day;
  final int totalMinutes;
  final Map<String, int> appUsageMinutes;

  factory _UsageBaseline.fromUsage({
    required String day,
    required AppUsageSummary usage,
  }) =>
      _UsageBaseline(
        day: day,
        totalMinutes: usage.totalMinutes,
        appUsageMinutes: usage.perAppMinutes,
      );

  factory _UsageBaseline.fromJson(Map<String, dynamic> json) => _UsageBaseline(
        day: json['day'] as String? ?? '',
        totalMinutes: json['totalMinutes'] as int? ?? 0,
        appUsageMinutes:
            (json['appUsageMinutes'] as Map<String, dynamic>? ??
                    <String, dynamic>{})
                .map(
          (String key, dynamic value) =>
              MapEntry<String, int>(key, value as int? ?? 0),
        ),
      );

  Map<String, Object> toJson() => <String, Object>{
        'day': day,
        'totalMinutes': totalMinutes,
        'appUsageMinutes': appUsageMinutes,
      };
}
