import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/parent_voice_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('parent_voice_notifications');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads battery optimization status and opens only the system review list',
      () async {
    bool openedSystemSettings = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'isIgnoringBatteryOptimizations':
          return false;
        case 'openBatteryOptimizationSettings':
          openedSystemSettings = true;
          return true;
        default:
          throw PlatformException(code: 'UNEXPECTED_METHOD');
      }
    });

    final ParentVoiceNotificationService service =
        ParentVoiceNotificationService();

    expect(await service.isIgnoringBatteryOptimizations(), isFalse);
    await service.openBatteryOptimizationSettings();
    expect(openedSystemSettings, isTrue);

    await service.dispose();
  });
}
