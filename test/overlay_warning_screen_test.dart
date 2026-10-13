import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/presentation/overlay/overlay_warning_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const MethodChannel accessibilityChannel = MethodChannel(
    'app_blocking/accessibility',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          accessibilityChannel,
          (MethodCall methodCall) async => false,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accessibilityChannel, null);
  });

  testWidgets('renders accessibility warning without a startup snackbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OverlayWarningApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Tap to enable Accessibility Service for app blocking'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
