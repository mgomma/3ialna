import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/presentation/onboarding/feature_walkthrough_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{'app_locale': 'en'});
    LocaleController.instance =
        LocaleController(await SharedPreferences.getInstance());
  });

  testWidgets('walkthrough advances through feature pages and can be skipped',
      (WidgetTester tester) async {
    int completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FeatureWalkthroughScreen(
          onCompleted: () async {
            completed += 1;
          },
        ),
      ),
    );

    expect(find.text('Your family, first'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Protection and limits'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(completed, 1);
  });
}
