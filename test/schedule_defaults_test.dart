import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/parental_control_storage_service.dart';
import 'package:mu_super_app/domain/models/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('enables the schedule by default when no schedule is stored', () async {
    expect(await ParentalControlStorageService().getSchedule(), isA<Schedule>());
    expect((await ParentalControlStorageService().getSchedule()).enabled, isTrue);
  });

  test('uses enabled default for an incomplete schedule record', () {
    expect(Schedule.fromMap(<String, dynamic>{}).enabled, isTrue);
  });

  test('preserves explicit parent schedule disablement', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'parental_control_schedule',
      jsonEncode(<String, Object>{
        'enabled': false,
        'startTime': '09:00',
        'endTime': '21:00',
        'activeDays': <int>[0, 1, 2, 3, 4, 5, 6],
      }),
    );

    expect((await ParentalControlStorageService().getSchedule()).enabled, isFalse);
  });
}
