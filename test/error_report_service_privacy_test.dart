import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/error_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('diagnostic share report excludes sensitive child and local values', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'native_error_reports_v1',
      jsonEncode(<Map<String, String>>[
        <String, String>{
          'timestamp': '2026-08-24T00:00:00.000Z',
          'source': 'LaylaHassan',
          'errorType': 'LaylaHassan',
          'stack': 'package:mu_super_app/presentation/parental_control/safe_content_screen.dart:42',
        },
        <String, String>{
          'timestamp': '2026-08-24T00:01:00.000Z',
          'source': 'task_reminder_DrinkWater',
          'errorType': 'StateError: Drink water before lunch',
          'stack': 'package:mu_super_app/presentation/parental_control/task_voice_reminder_screen.dart:88 parent_voice_task_DrinkWater.m4a',
        },
      ]),
    );
    await ErrorReportService.recordHandled(
      source: 'vpn_permission_or_start',
      error: StateError('Layla Hassan born 2017-04-12 PIN 1234'),
      stackTrace: StackTrace.fromString('package:mu_super_app/data/system/safe_content_vpn_service.dart:21'),
    );
    await ErrorReportService.recordEvent(
      source: 'notification_action',
      event: 'notification_action_received',
    );

    final String report = await ErrorReportService.buildShareText();
    final Map<String, dynamic> decoded = jsonDecode(report) as Map<String, dynamic>;
    final String normalized = report.toLowerCase();

    expect(decoded['format'], '3ialna-diagnostic-report');
    expect(decoded['summary'], <String, int>{
      'relevantEventCount': 4,
      'suppressedLifecycleEntries': 0,
    });
    expect(normalized, isNot(contains('layla')));
    expect(normalized, isNot(contains('2017-04-12')));
    expect(normalized, isNot(contains('1234')));
    expect(normalized, isNot(contains('born')));
    expect(normalized, isNot(contains('drinkwater')));
    expect(normalized, isNot(contains('drink water')));
    expect(normalized, isNot(contains('lunch')));
    expect(normalized, isNot(contains('.m4a')));
    expect(normalized, contains('unknownerror'));
    expect(normalized, contains('vpn_permission_or_start'));
    expect(normalized, contains('notification_action_received'));
  });

  test('email URI uses the sanitized report and does not include sensitive values', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('error_reports_v1', <String>[
      jsonEncode(<String, String>{
        'timestamp': '2026-08-24T10:00:00.000Z',
        'source': 'flutter',
        'errorType': 'StateError: child name Layla PIN 1234',
        'stack': 'package:mu_super_app/data/system/error_report_service.dart:21',
      }),
    ]);

    final Uri email = await ErrorReportService.buildEmailUri();
    final String body = email.queryParameters['body'] ?? '';

    expect(email.scheme, 'mailto');
    expect(email.path, '3ialna.app@gmail.com');
    expect(email.queryParameters['subject'], '3ialna diagnostic report');
    expect(body, contains('3ialna-diagnostic-report'));
    expect(body.toLowerCase(), isNot(contains('layla')));
    expect(body, isNot(contains('1234')));
    expect(body.toLowerCase(), isNot(contains('child name')));
  });

  test('suppresses legacy lifecycle-only startup rows while preserving an allowlisted outcome', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('error_reports_v1', <String>[
      jsonEncode(<String, String>{
        'timestamp': '2026-08-24T10:00:00.000Z',
        'source': 'lifecycle',
        'errorType': 'UnknownError',
        'stack': '',
      }),
    ]);
    await ErrorReportService.recordEvent(
      source: 'notification_permission',
      event: 'notification_permission_denied',
    );

    final Map<String, dynamic> report =
        jsonDecode(await ErrorReportService.buildShareText()) as Map<String, dynamic>;
    final List<dynamic> reports = report['reports'] as List<dynamic>;

    expect((report['summary'] as Map<String, dynamic>)['suppressedLifecycleEntries'], 1);
    expect(reports, hasLength(1));
    expect((reports.single as Map<String, dynamic>)['event'], 'notification_permission_denied');
  });
}
