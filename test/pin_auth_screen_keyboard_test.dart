import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/system/pin_auth_service.dart';
import 'package:mu_super_app/presentation/parental_control/pin_auth_screen.dart';

void main() {
  testWidgets('PIN fields remain reachable on a short landscape viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 210);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: PinAuthScreen(isSetupMode: true, onAuthenticated: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Set Parent PIN'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts Arabic keyboard numerals and stores a normalized PIN', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    bool authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PinAuthScreen(
          isSetupMode: true,
          onAuthenticated: () => authenticated = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '١');
    await tester.enterText(fields.at(1), '٢');
    await tester.enterText(fields.at(2), '٣');
    await tester.enterText(fields.at(3), '٤');
    await tester.pumpAndSettle();

    await tester.enterText(fields.at(0), '١');
    await tester.enterText(fields.at(1), '٢');
    await tester.enterText(fields.at(2), '٣');
    await tester.enterText(fields.at(3), '٤');
    await tester.pumpAndSettle();

    expect(authenticated, isTrue);
    expect(await PinAuthService().validatePin('1234'), isTrue);
  });
}
