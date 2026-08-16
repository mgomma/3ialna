import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorReportService {
  static const String _prefsKeyReports = 'error_reports_v1';
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
        'message': _sanitize(message),
        'stack': _sanitize(stackTrace?.toString() ?? ''),
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

  static String _sanitize(String value) {
    final String noNewLines = value.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (noNewLines.length <= 300) {
      return noNewLines;
    }
    return noNewLines.substring(0, 300);
  }
}
