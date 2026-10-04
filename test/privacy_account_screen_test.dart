import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/l10n/app_localizations.dart';
import 'package:mu_super_app/presentation/support/privacy_account_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, String languageCode) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(languageCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const PrivacyAccountScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows policy and deletion actions in English', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, 'en');

    expect(find.text('Privacy & account'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Request account deletion'), findsOneWidget);
    expect(find.text(PrivacyAccountScreen.supportEmail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows policy and deletion actions in Arabic', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, 'ar');

    expect(find.text('الخصوصية والحساب'), findsOneWidget);
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    expect(find.text('طلب حذف الحساب'), findsOneWidget);
    expect(find.text(PrivacyAccountScreen.supportEmail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('deletion request contains no child data', () {
    final Uri request = PrivacyAccountScreen.accountDeletionRequestUri(
      subject: 'Account deletion',
      body: 'Please delete my registered account. No child details attached.',
    );

    expect(request.scheme, 'mailto');
    expect(request.path, PrivacyAccountScreen.supportEmail);
    expect(request.queryParameters['subject'], 'Account deletion');
    expect(request.queryParameters['body'], contains('registered account'));
    expect(request.queryParameters['body'], isNot(contains('birth date')));
    expect(request.queryParameters['body'], isNot(contains('usage history')));
  });
}
