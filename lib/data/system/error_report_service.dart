import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorReportService {
  static const String _prefsKeyReports = 'error_reports_v1';
  static const String _prefsKeyNativeReports = 'native_error_reports_v1';
  static const int _maxReports = 20;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
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

    await _record(source: 'lifecycle', message: 'app_started');
  }

  static Future<void> _record({
    required String source,
    required String message,
    StackTrace? stackTrace,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> existing = prefs.getStringList(_prefsKeyReports) ?? <String>[];

      final Map<String, String> payload = <String, String>{
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        // Store the exception category, not its raw text. Raw exception text
        // can contain a child name, package label, PIN, or other local input.
        'errorType': _sanitizeErrorType(message),
        'stack': _sanitizeStack(stackTrace?.toString() ?? ''),
      };

      existing.add(jsonEncode(payload));
      if (existing.length > _maxReports) {
        existing.removeRange(0, existing.length - _maxReports);
      }

      await prefs.setStringList(_prefsKeyReports, existing);
    } catch (_) {
      // Swallow logging errors to avoid recursive failures.
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

  /// Creates a parent-controlled diagnostic payload for the native share sheet.
  /// It intentionally contains no child/profile data, credentials, recordings,
  /// domains, app usage, or raw exception messages.
  static Future<String> buildShareText() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, String>> reports = <Map<String, String>>[
      ..._readReports(prefs.getStringList(_prefsKeyReports) ?? const <String>[]),
      ..._readNativeReports(prefs.getString(_prefsKeyNativeReports)),
    ]..sort((Map<String, String> a, Map<String, String> b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    final Map<String, Object> report = <String, Object>{
      'format': '3ialna-diagnostic-report',
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'privacy': 'Contains only sanitized error categories and stack frame locations. It excludes children, birth dates, gender, PINs, recordings, app rules, domains, and usage.',
      'reports': reports.take(_maxReports).toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(report);
  }

  static List<Map<String, String>> _readReports(List<String> values) {
    final List<Map<String, String>> reports = <Map<String, String>>[];
    for (final String value in values) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(value) as Map<String, dynamic>;
        reports.add(<String, String>{
          'timestamp': decoded['timestamp'] as String? ?? '',
          'source': _sanitizeSource(decoded['source']?.toString() ?? 'flutter'),
          'errorType': _sanitizeErrorType(decoded['errorType']?.toString() ?? decoded['message']?.toString() ?? 'UnknownError'),
          'stack': _sanitizeStack(decoded['stack']?.toString() ?? ''),
        });
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
        return <String, String>{
          'timestamp': item['timestamp'] as String? ?? '',
          'source': _sanitizeSource(item['source']?.toString() ?? 'native'),
          'errorType': _sanitizeErrorType(item['errorType']?.toString() ?? 'NativeError'),
          'stack': _sanitizeStack(item['stack']?.toString() ?? ''),
        };
      }).toList(growable: false);
    } catch (_) {
      return const <Map<String, String>>[];
    }
  }

  static String _sanitizeErrorType(String value) {
    final String candidate = value.trim().split(RegExp(r'[\s:(]')).first;
    final bool isExceptionName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*(?:Error|Exception|Fault)$').hasMatch(candidate);
    return isExceptionName || candidate == 'Error' ? candidate : 'UnknownError';
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
    };
    return allowed.contains(value) ? value : 'unknown';
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
          final bool isApplicationFrame = normalized.contains('package:') || normalized.contains('/lib/') || normalized.contains('com.ialna.');
          return isApplicationFrame && !sensitiveFrameTerms.any(normalized.contains);
        })
        .map((String line) => line.trim())
        .take(12)
        .toList(growable: false);
    final String joined = safeFrames.join('\n');
    return joined.substring(0, joined.length.clamp(0, 600).toInt());
  }
}
