import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/presentation/parental_control/app_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel appListChannel = MethodChannel('parental_control/apps');

Future<void> pumpManagementScreen(
  WidgetTester tester,
  String languageCode,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'app_locale': languageCode,
  });
  LocaleController.instance =
      LocaleController(await SharedPreferences.getInstance());
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        appListChannel,
        (MethodCall methodCall) async => <Object?>[],
      );

  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      home: const AppManagementScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the blocked-only empty state in English', (
    WidgetTester tester,
  ) async {
    await pumpManagementScreen(tester, 'en');

    expect(find.text('Manage Apps'), findsOneWidget);
    expect(find.text('Blocked apps only'), findsOneWidget);
    expect(find.text('No blocked apps yet'), findsOneWidget);
    await tester.tap(find.text('Blocked apps only'));
    await tester.pump();
    expect(find.text('All installed apps'), findsOneWidget);
    expect(find.text('No apps to display'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the blocked-only empty state in Arabic', (
    WidgetTester tester,
  ) async {
    await pumpManagementScreen(tester, 'ar');

    expect(find.text('إدارة التطبيقات'), findsOneWidget);
    expect(find.text('التطبيقات المحظورة فقط'), findsOneWidget);
    expect(find.text('لا توجد تطبيقات محظورة بعد'), findsOneWidget);
    await tester.tap(find.text('التطبيقات المحظورة فقط'));
    await tester.pump();
    expect(find.text('كل التطبيقات المثبتة'), findsOneWidget);
    expect(find.text('لا توجد تطبيقات للعرض'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appListChannel, null);
  });
}