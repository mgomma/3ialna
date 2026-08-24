import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/locale_controller.dart';
import 'package:mu_super_app/presentation/reports/parent_usage_report_screen.dart';
import 'package:mu_super_app/presentation/support/educational_expert_contact_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    LocaleController.instance = LocaleController(prefs);
  });

  testWidgets('parent report exposes date-filter controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ParentUsageReportScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.byType(ActionChip), findsOneWidget);
  });

  testWidgets('expert contact form requires an explicit child-data consent control',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EducationalExpertContactScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets(
      'expert contact accepts Arabic-Indic mobile digits before showing the consent gate',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EducationalExpertContactScreen()),
    );
    await tester.pumpAndSettle();

    final Finder phoneField = find.byType(TextFormField).at(0);
    final Finder detailsField = find.byType(TextFormField).at(1);
    await tester.enterText(phoneField, '٠٥٠ ١٢٣ ٤٥٦٧');
    await tester.enterText(detailsField, 'أحتاج إلى مساعدة في إعدادات الحماية.');

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(
      find.text('يرجى تأكيد موافقتك قبل تضمين أسماء الأطفال وأعمارهم في البريد.'),
      findsOneWidget,
    );
    expect(
      find.text('أدخل رقم جوال صحيحًا للدولة المحددة (+966).'),
      findsNothing,
    );
  });
}
