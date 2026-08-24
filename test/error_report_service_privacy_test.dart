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

    final String report = await ErrorReportService.buildShareText();
    final Map<String, dynamic> decoded = jsonDecode(report) as Map<String, dynamic>;
    final String normalized = report.toLowerCase();

    expect(decoded['format'], '3ialna-diagnostic-report');
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
  });
}
