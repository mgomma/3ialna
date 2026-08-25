import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/presentation/parental_control/active_child_handover_reminder_card.dart';

void main() {
  Widget buildReminder({
    required int childProfileCount,
    required bool isParentModeActive,
    String? activeChildName,
    bool isArabic = false,
    required VoidCallback onConfirmActiveUser,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ActiveChildHandoverReminderCard(
          isArabic: isArabic,
          childProfileCount: childProfileCount,
          isParentModeActive: isParentModeActive,
          activeChildName: activeChildName,
          onConfirmActiveUser: onConfirmActiveUser,
        ),
      ),
    );
  }

  testWidgets('is hidden when only one child profile exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildReminder(
        childProfileCount: 1,
        isParentModeActive: false,
        activeChildName: 'Omar',
        onConfirmActiveUser: () {},
      ),
    );

    expect(find.text('Confirm the user before handover'), findsNothing);
    expect(find.byKey(const Key('handover-confirm-active-user')), findsNothing);
  });

  testWidgets('shows the active child and delegates the handover action',
      (WidgetTester tester) async {
    var confirmations = 0;
    await tester.pumpWidget(
      buildReminder(
        childProfileCount: 2,
        isParentModeActive: false,
        activeChildName: 'Omar',
        onConfirmActiveUser: () => confirmations += 1,
      ),
    );

    expect(find.text('Confirm the user before handover'), findsOneWidget);
    expect(find.textContaining('Current active user: Omar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('handover-confirm-active-user')));
    expect(confirmations, 1);
  });

  testWidgets('explains that Parent mode must return to a child profile',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildReminder(
        childProfileCount: 2,
        isArabic: true,
        isParentModeActive: true,
        onConfirmActiveUser: () {},
      ),
    );

    expect(find.text('تأكيد المستخدم قبل تسليم الجهاز'), findsOneWidget);
    expect(find.textContaining('وضع الوالدين'), findsOneWidget);
    expect(find.text('تأكيد أو تغيير المستخدم'), findsOneWidget);
  });
}
