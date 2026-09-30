// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/main.dart';
import 'package:mu_super_app/presentation/overlay/overlay_warning_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    LocaleController.instance = LocaleController(
      await SharedPreferences.getInstance(),
    );
  });

  testWidgets('main app builds while Home settings initialize', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SocialMediaLimiterApp());

    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay warning screen builds without gesture conflicts', (
    WidgetTester tester,
  ) async {
    await tester.pump();
    await tester.pumpWidget(const OverlayWarningApp());

    expect(tester.takeException(), isNull);
  });
}
