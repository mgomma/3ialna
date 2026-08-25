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
    expect(find.text('Add the children'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets('walkthrough demonstrates shared-device child and Parent mode setup',
      (WidgetTester tester) async {
    var completed = 0;
    var profileSetupOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FeatureWalkthroughScreen(
          onCompleted: () async => completed += 1,
          onOpenProfileSetup: () async => profileSetupOpened += 1,
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walkthrough-add-child')));
    await tester.pump();
    expect(find.text('Profiles in this example: 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walkthrough-switch-child')));
    await tester.pump();
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('walkthrough-switch-child'))).selected,
      isTrue,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('walkthrough-parent-mode')));
    await tester.tap(find.byKey(const Key('walkthrough-parent-mode')));
    await tester.pump();
    expect(find.text('Verified in this example'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('walkthrough-open-kids-management')),
    );
    await tester.tap(find.byKey(const Key('walkthrough-open-kids-management')));
    await tester.pumpAndSettle();
    expect(profileSetupOpened, 1);
    expect(completed, 1);
  });
}
