import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/data/local/reward_service.dart';
import 'package:mu_super_app/l10n/app_localizations.dart';
import 'package:mu_super_app/presentation/parental_control/widgets/request_approval_components.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

ChildExtraTimeRequest _request({int minutes = 5}) {
  return ChildExtraTimeRequest(
    id: 'request-1',
    childId: 'child-1',
    minutes: minutes,
    packageName: 'com.example.game',
    createdAt: DateTime(2026, 1, 1),
    status: 'pending',
  );
}

void main() {
  testWidgets('request control shows pending state and disables duplicate action', (WidgetTester tester) async {
    await tester.pumpWidget(_host(const ChildRequestPendingBanner(pending: true, onRequest: _noop)));

    expect(find.text('Request pending'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });

  testWidgets('pending badge exposes an accessible count', (WidgetTester tester) async {
    await tester.pumpWidget(_host(const PendingRequestBadge(count: 3)));

    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('3 pending extra-time requests'), findsOneWidget);
  });

  testWidgets('request card disables approval when no token is available', (WidgetTester tester) async {
    await tester.pumpWidget(_host(PendingRequestCard(request: _request(), childName: 'Sam', tokenAvailable: 0, onApprove: _noop, onDecline: _noop)));

    expect(find.text('Request from Sam'), findsOneWidget);
    final Iterable<IconButton> buttons = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(buttons.any((IconButton button) => button.onPressed == null), isTrue);
  });

  testWidgets('approval sheet disables approval without a token and localizes Arabic copy', (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      ApprovalDecisionSheet(request: _request(minutes: 10), childName: 'أحمد', tokenAvailable: 0, onApprove: _noop, onDecline: _noop),
      locale: const Locale('ar'),
    ));

    expect(find.text('مراجعة طلب وقت إضافي'), findsOneWidget);
    expect(find.text('طلب من أحمد'), findsOneWidget);
    final Iterable<FilledButton> buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    expect(buttons.single.onPressed, isNull);
  });
}

void _noop() {}
