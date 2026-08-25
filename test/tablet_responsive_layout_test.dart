import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/presentation/parental_control/profile_pack_screen.dart';
import 'package:mu_super_app/presentation/reports/parent_usage_report_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    LocaleController.instance = LocaleController(preferences);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('parent report renders its filters on a landscape tablet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(home: ParentUsageReportScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('parent-report-child-filter')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shareable-profile import dialog respects a tablet split view',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(home: ProfilePackScreen()),
    );
    await tester.tap(find.text('Import a setup'));
    await tester.pumpAndSettle();

    final Finder dialog = find.byType(Dialog);
    expect(dialog, findsOneWidget);
    expect(tester.getSize(dialog).width, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });
}
