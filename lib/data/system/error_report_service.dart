import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorReportService {
  static const String _prefsKeyReports = 'error_reports_v1';
  static const String _prefsKeyNativeReports = 'native_error_reports_v1';
  static const int _maxReports = 20;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _record(
        source: 'flutter',
        message: details.exceptionAsString(),
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _record(
        source: 'platform',
        message: error.toString(),
        stackTrace: stack,
      );
      return false;
    };
  }

  static Future<void> _record({
    required String source,
    required String message,
    StackTrace? stackTrace,
    String? event,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> existing = prefs.getStringList(_prefsKeyReports) ?? <String>[];
      final Map<String, String> payload = <String, String>{
        'timestamp': DateTime.now().toIso8601String(),
        'source': _sanitizeSource(source),
        // Raw exception text can contain a child name, package label, PIN, or
        // other local input. Store only a category derived from the type.
        'errorType': _sanitizeErrorType(message),
        'stack': _sanitizeStack(stackTrace?.toString() ?? ''),
      };
      final String safeEvent = _sanitizeEvent(event);
      if (safeEvent.isNotEmpty) payload['event'] = safeEvent;

      existing.add(jsonEncode(payload));
      if (existing.length > _maxReports) {
        existing.removeRange(0, existing.length - _maxReports);
      }
      await prefs.setStringList(_prefsKeyReports, existing);
    } catch (_) {
      // Diagnostics must not create a new failure loop.
    }
  }

  /// Records a handled fault without retaining the error's raw message.
  static Future<void> recordHandled({
    required String source,
    required Object error,
    StackTrace? stackTrace,
  }) => _record(
        source: source,
        message: error.runtimeType.toString(),
        stackTrace: stackTrace,
      );

  /// Records an allowlisted product outcome without retaining user input,
  /// notification payloads, recording keys, or exception text.
  static Future<void> recordEvent({
    required String source,
    required String event,
  }) => _record(
        source: source,
        message: 'Event',
        event: event,
      );

  /// Creates a parent-controlled diagnostic payload for the native share sheet
  /// or the user's email composer. It intentionally contains no child/profile
  /// data, credentials, recordings, domains, app usage, reminder labels,
  /// recording paths, or raw errors.
  static Future<String> buildShareText() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> storedReports = <Map<String, String>>[
      ..._readReports(prefs.getStringList(_prefsKeyReports) ?? const <String>[]),
      ..._readNativeReports(prefs.getString(_prefsKeyNativeReports)),
    ];
    final List<Map<String, String>> reports = storedReports
        .where(_isRelevantReport)
        .toList(growable: false)
      ..sort((Map<String, String> a, Map<String, String> b) =>
          (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    final Map<String, Object> report = <String, Object>{
      'format': '3ialna-diagnostic-report',
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'summary': <String, int>{
        'relevantEventCount': reports.length,
        'suppressedLifecycleEntries': storedReports.length - reports.length,
      },
      'privacy': 'Contains only sanitized error categories, allowlisted outcome names, and safe stack frame locations. It excludes children, birth dates, gender, PINs, recordings, recording paths, reminder labels, app rules, domains, usage, and raw exception messages.',
      'reports': reports.take(_maxReports).toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(report);
  }

  /// Builds a mailto URI only after a parent explicitly chooses to send the
  /// already-sanitized report. Opening an email composer is intentionally not
  /// automatic: crashes must never send data or interrupt a child session.
  static Future<Uri> buildEmailUri() async {
    final String report = await buildShareText();
    return Uri(
      scheme: 'mailto',
      path: '3ialna.app@gmail.com',
      queryParameters: <String, String>{
        'subject': '3ialna diagnostic report',
        'body': report,
      },
    );
  }

  static List<Map<String, String>> _readReports(List<String> values) {
    final List<Map<String, String>> reports = <Map<String, String>>[];
    for (final String value in values) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(value) as Map<String, dynamic>;
        final Map<String, String> report = <String, String>{
          'timestamp': decoded['timestamp'] as String? ?? '',
          'source': _sanitizeSource(decoded['source']?.toString() ?? 'flutter'),
          'errorType': _sanitizeErrorType(
            decoded['errorType']?.toString() ?? decoded['message']?.toString() ?? 'UnknownError',
          ),
          'stack': _sanitizeStack(decoded['stack']?.toString() ?? ''),
        };
        final String safeEvent = _sanitizeEvent(decoded['event']?.toString());
        if (safeEvent.isNotEmpty) report['event'] = safeEvent;
        reports.add(report);
      } catch (_) {
        // Ignore corrupt local diagnostics instead of risking an error loop.
      }
    }
    return reports;
  }

  static List<Map<String, String>> _readNativeReports(String? value) {
    if (value == null || value.isEmpty) return const <Map<String, String>>[];
    try {
      final List<dynamic> decoded = jsonDecode(value) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().map((Map<String, dynamic> item) {
        final Map<String, String> report = <String, String>{
          'timestamp': item['timestamp'] as String? ?? '',
          'source': _sanitizeSource(item['source']?.toString() ?? 'native'),
          'errorType': _sanitizeErrorType(item['errorType']?.toString() ?? 'NativeError'),
          'stack': _sanitizeStack(item['stack']?.toString() ?? ''),
        };
        final String safeEvent = _sanitizeEvent(item['event']?.toString());
        if (safeEvent.isNotEmpty) report['event'] = safeEvent;
        return report;
      }).toList(growable: false);
    } catch (_) {
      return const <Map<String, String>>[];
    }
  }

  static String _sanitizeErrorType(String value) {
    final String candidate = value.trim().split(RegExp(r'[\s:(]')).first;
    final bool isExceptionName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*(?:Error|Exception|Fault)$').hasMatch(candidate);
    return isExceptionName || candidate == 'Error' || candidate == 'Event'
        ? candidate
        : 'UnknownError';
  }

  static String _sanitizeSource(String value) {
    const Set<String> allowed = <String>{
      'flutter',
      'platform',
      'lifecycle',
      'native_uncaught',
      'vpn_status_refresh',
      'vpn_permission_or_start',
      'diagnostic_share',
      'vpn_permission_request',
      'device_admin_request',
      'notification_permission',
      'notification_schedule',
      'notification_action',
      'voice_playback',
    };
    return allowed.contains(value) ? value : 'unknown';
  }

  static String _sanitizeEvent(String? value) {
    const Set<String> allowed = <String>{
      'notification_permission_denied',
      'notification_schedule_denied',
      'notification_action_received',
      'notification_action_invalid',
      'notification_action_opened',
      'notification_action_navigation_unavailable',
      'voice_playback_started',
      'voice_playback_unavailable',
    };
    return value != null && allowed.contains(value) ? value : '';
  }

  static bool _isRelevantReport(Map<String, String> report) {
    return report['source'] != 'lifecycle' ||
        report['event']?.isNotEmpty == true ||
        report['errorType'] != 'UnknownError' ||
        report['stack']?.isNotEmpty == true;
  }

  static String _sanitizeStack(String value) {
    const List<String> sensitiveFrameTerms = <String>[
      'voice',
      'record',
      'reminder',
      'task',
      'audio',
      '.m4a',
      '.wav',
    ];
    final List<String> safeFrames = value
        .split(RegExp(r'\r?\n'))
        .where((String line) {
          final String normalized = line.toLowerCase();
          final bool isApplicationFrame = normalized.contains('package:') ||
              normalized.contains('/lib/') ||
              normalized.contains('com.ialna.');
          return isApplicationFrame &&
              !sensitiveFrameTerms.any(normalized.contains);
        })
        .map((String line) => line.trim())
        .take(12)
        .toList(growable: false);
    final String joined = safeFrames.join('\n');
    return joined.substring(0, joined.length.clamp(0, 600).toInt());
  }
}
