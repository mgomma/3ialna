import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/presentation/parental_control/widgets/domain_rules_tabs.dart';
import 'package:mu_super_app/presentation/parental_control/widgets/protection_status_card.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('ProtectionStatusCard', () {
    testWidgets('shows Arabic protected state and stop control', (tester) async {
      var stopPressed = false;
      await tester.pumpWidget(
        _testApp(
          ProtectionStatusCard(
            policyEnabled: true,
            vpnPermissionGranted: true,
            vpnRunning: true,
            isAndroid: true,
            isArabic: true,
            onStop: () => stopPressed = true,
          ),
        ),
      );

      expect(find.text('الحماية مفعّلة'), findsOneWidget);
      expect(find.text('يعمل فلتر النطاقات على حركة DNS المدعومة.'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      expect(stopPressed, isTrue);
    });

    testWidgets('shows permission-required state and invokes grant action', (tester) async {
      var grantPressed = false;
      await tester.pumpWidget(
        _testApp(
          ProtectionStatusCard(
            policyEnabled: true,
            vpnPermissionGranted: false,
            vpnRunning: false,
            isAndroid: true,
            isArabic: true,
            onGrantPermission: () => grantPressed = true,
          ),
        ),
      );

      expect(find.text('يلزم السماح باتصال VPN'), findsOneWidget);
      expect(find.text('منح الإذن'), findsOneWidget);
      await tester.tap(find.text('منح الإذن'));
      expect(grantPressed, isTrue);
    });

    testWidgets('shows disabled policy state with enable action', (tester) async {
      var enabled = false;
      await tester.pumpWidget(
        _testApp(
          ProtectionStatusCard(
            policyEnabled: false,
            vpnPermissionGranted: true,
            vpnRunning: false,
            isAndroid: true,
            isArabic: false,
            onEnablePolicy: () => enabled = true,
          ),
        ),
      );

      expect(find.text('Safe-content policy is off'), findsOneWidget);
      await tester.tap(find.text('Enable policy'));
      expect(enabled, isTrue);
    });
  });

  group('DomainRulesTabs', () {
    testWidgets('shows Arabic tabs and actionable empty states', (tester) async {
      await tester.pumpWidget(
        _testApp(
          DomainRulesTabs(
            blockedDomains: const {},
            allowedDomains: const {},
            isArabic: true,
            onAddBlocked: (_) {},
            onAddAllowed: (_) {},
            onRemoveBlocked: (_) {},
            onRemoveAllowed: (_) {},
          ),
        ),
      );

      expect(find.text('المحظورة (0)'), findsOneWidget);
      expect(find.text('المسموح بها (0)'), findsOneWidget);
      expect(find.textContaining('لا توجد نطاقات محظورة'), findsOneWidget);
      expect(find.text('إضافة نطاق'), findsOneWidget);
    });

    testWidgets('normalizes and returns a newly added allowed domain', (tester) async {
      String? addedDomain;
      await tester.pumpWidget(
        _testApp(
          DomainRulesTabs(
            blockedDomains: const {},
            allowedDomains: const {},
            isArabic: true,
            onAddBlocked: (_) {},
            onAddAllowed: (domain) => addedDomain = domain,
            onRemoveBlocked: (_) {},
            onRemoveAllowed: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('المسموح بها (0)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة استثناء'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'https://WWW.Example.org/home');
      await tester.tap(find.text('السماح بهذا النطاق'));
      await tester.pumpAndSettle();

      expect(addedDomain, 'example.org');
    });

    testWidgets('filters domains and sends the selected rule to remove', (tester) async {
      String? removedDomain;
      await tester.pumpWidget(
        _testApp(
          DomainRulesTabs(
            blockedDomains: const {'blocked.example', 'other.example'},
            allowedDomains: const {},
            isArabic: false,
            onAddBlocked: (_) {},
            onAddAllowed: (_) {},
            onRemoveBlocked: (domain) => removedDomain = domain,
            onRemoveAllowed: (_) {},
          ),
        ),
      );

      expect(find.text('blocked.example'), findsOneWidget);
      expect(find.text('other.example'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'blocked');
      await tester.pump();
      expect(find.text('blocked.example'), findsOneWidget);
      expect(find.text('other.example'), findsNothing);

      await tester.tap(find.byTooltip('Remove rule'));
      expect(removedDomain, 'blocked.example');
    });
  });
}
