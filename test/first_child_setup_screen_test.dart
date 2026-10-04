import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/age_safety_profile_service.dart';
import 'package:mu_super_app/domain/models/age_safety_profile.dart';
import 'package:mu_super_app/domain/models/child_profile.dart';
import 'package:mu_super_app/l10n/app_localizations.dart';
import 'package:mu_super_app/presentation/onboarding/first_child_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('collects child details, previews the age preset, and saves one child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FirstChildSetupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('age-profile-preview')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey<String>('save-first-child-profile')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('first-child-name')),
      'Maha',
    );
    await tester.tap(find.byKey(const ValueKey<String>('first-child-birth-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('first-child-gender')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Girl').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('age-profile-preview')), findsOneWidget);
    expect(find.text('Recommended starting profile'), findsOneWidget);
    for (final String label in <String>[
      'Daily recreational budget',
      'Social media',
      'Games',
      'Sleep schedule',
      'Prayer lock',
      'Block mature content',
      'Require parent approval for requests',
      'Parent voice reminders',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('save-first-child-profile')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('save-first-child-profile')));
    await tester.pumpAndSettle();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService profiles = AgeSafetyProfileService(prefs);
    final List<ChildProfile> children = profiles.loadChildren();
    expect(children, hasLength(1));
    expect(children.single.name, 'Maha');
    expect(children.single.gender, ChildGender.girl);
    expect(
      children.single.preset.profile,
      AgeSafetyProfileRecommendation.forBirthDate(children.single.birthDate),
    );
    expect(children.single.preset.dailyLimitMinutes, isPositive);
  });
}