import 'package:flutter/services.dart';

class SafeContentVpnService {
  static const MethodChannel _channel = MethodChannel('safe_content/vpn');

  Future<bool> isPermissionGranted() async {
    return await _channel.invokeMethod<bool>('isVpnPermissionGranted') ?? false;
  }

  /// Returns true when permission was already granted. Returns false when
  /// Android opened its consent screen and the parent must confirm there.
  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestVpnPermission') ?? false;
  }

  Future<bool> start() async {
    return await _channel.invokeMethod<bool>('startVpn') ?? false;
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stopVpn');
  }

  Future<bool> isRunning() async {
    return await _channel.invokeMethod<bool>('isVpnRunning') ?? false;
  }
}
