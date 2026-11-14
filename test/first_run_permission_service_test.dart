import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/first_run_permission_service.dart';

const MethodChannel _onboardingChannel =
    MethodChannel('parental_control/onboarding');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const FirstRunPermissionService service = FirstRunPermissionService();
  bool usageAccessEnabled = false;
  bool settingsOpened = false;

  setUp(() {
    usageAccessEnabled = false;
    settingsOpened = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_onboardingChannel, (MethodCall call) async {
          switch (call.method) {
            case 'hasUsageAccess':
              return usageAccessEnabled;
            case 'openUsageAccessSettings':
              settingsOpened = true;
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_onboardingChannel, null);
  });

  test('reports Usage Access as denied when Android denies it', () async {
    expect(await service.hasUsageAccess(), isFalse);
  });

  test('reports Usage Access as granted when Android allows it', () async {
    usageAccessEnabled = true;

    expect(await service.hasUsageAccess(), isTrue);
  });

  test('fails closed when the native permission check throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_onboardingChannel, (MethodCall call) async {
          throw PlatformException(code: 'PERMISSION_CHECK_FAILED');
        });

    expect(await service.hasUsageAccess(), isFalse);
  });

  test('opens Android Usage Access settings on request', () async {
    expect(await service.openUsageAccessSettings(), isTrue);
    expect(settingsOpened, isTrue);
  });
}