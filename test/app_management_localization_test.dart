import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/data/local/parental_control_storage_service.dart';
import 'package:mu_super_app/data/system/pin_auth_service.dart';
import 'package:mu_super_app/l10n/app_localizations.dart';
import 'package:mu_super_app/presentation/parental_control/app_management_screen.dart';
import 'package:mu_super_app/presentation/parental_control/parent_dashboard_screen.dart';
import 'package:mu_super_app/presentation/parental_control/pin_auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel appListChannel = MethodChannel('parental_control/apps');

Future<void> pumpManagementScreen(
  WidgetTester tester,
  String languageCode,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'app_locale': languageCode,
  });
  LocaleController.instance = LocaleController(
    await SharedPreferences.getInstance(),
  );
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
  testWidgets(
    'refreshes dashboard counts after returning from app management',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': 'en',
      });
      LocaleController.instance = LocaleController(
        await SharedPreferences.getInstance(),
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final name in <String>[
        'parental_control/kiosk',
        'app_blocking/accessibility',
      ]) {
        final channel = MethodChannel(name);
        messenger.setMockMethodCallHandler(channel, (_) async => false);
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }
      messenger.setMockMethodCallHandler(
        appListChannel,
        (_) async => <Object?>[],
      );
      final storage = ParentalControlStorageService();
      await PinAuthService().setPin('2468');
      await storage.setBlockedApps(<String>['example.one']);
      await storage.setTimeLimits(<String, int>{'example.one': 10});

      await tester.pumpWidget(const MaterialApp(home: ParentDashboardScreen()));
      await tester.pumpAndSettle();
      tester
          .widget<PinAuthScreen>(find.byType(PinAuthScreen))
          .onAuthenticated();
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNWidgets(2));

      await tester.ensureVisible(find.text('Manage Apps'));
      await tester.tap(find.text('Manage Apps'));
      await tester.pumpAndSettle();
      expect(find.byType(AppManagementScreen), findsOneWidget);
      await storage.setBlockedApps(<String>[]);
      await storage.setTimeLimits(<String, int>{
        'example.one': 10,
        'example.two': 20,
      });
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

  for (final language in <String>['en', 'ar']) {
    testWidgets('removes an existing app time limit in $language', (
      WidgetTester tester,
    ) async {
      final isArabic = language == 'ar';
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': language,
      });
      LocaleController.instance = LocaleController(
        await SharedPreferences.getInstance(),
      );
      final storage = ParentalControlStorageService();
      await storage.setAppTimeLimit('example.game', 15);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            appListChannel,
            (_) async => <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'example.game',
                'appName': 'Test game',
                'isSystemApp': false,
              },
            ],
          );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(isArabic ? 'التطبيقات المحظورة فقط' : 'Blocked apps only'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(isArabic ? 'تعيين حد زمني' : 'Set Time Limit'),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text(
            isArabic ? 'تعيين الحد الزمني' : 'Set Time Limit',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(isArabic ? 'إزالة الحد' : 'Remove limit'));
      await tester.pumpAndSettle();

      expect(await storage.getAppTimeLimit('example.game'), isNull);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.text(isArabic ? 'تعيين حد زمني' : 'Set Time Limit'),
      );
      await tester.pumpAndSettle();
      expect(find.text(isArabic ? 'إزالة الحد' : 'Remove limit'), findsNothing);
      expect(
        find.text(isArabic ? 'مدة مخصصة (بالدقائق)' : 'Custom (minutes)'),
        findsOneWidget,
      );
      await tester.tap(find.text(isArabic ? 'إلغاء' : 'Cancel'));
      await tester.pumpAndSettle();
    });
  }

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
