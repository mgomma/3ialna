import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/system/safe_content_vpn_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('safe_content/vpn');
  const StandardMethodCodec codec = StandardMethodCodec();

  Future<void> deliverNativePermissionResult(bool granted) async {
    final ByteData payload = codec.encodeMethodCall(
      MethodCall('onVpnPermissionResult', granted),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      payload,
      (_) {},
    );
  }

  test('delivers a granted Android VPN consent result to Safe Content', () async {
    bool? received;
    SafeContentVpnService.setPermissionResultHandler((bool granted) async {
      received = granted;
    });

    await deliverNativePermissionResult(true);

    expect(received, isTrue);
  });

  test('delivers a declined Android VPN consent result to Safe Content', () async {
    bool? received;
    SafeContentVpnService.setPermissionResultHandler((bool granted) async {
      received = granted;
    });

    await deliverNativePermissionResult(false);

    expect(received, isFalse);
  });
}
