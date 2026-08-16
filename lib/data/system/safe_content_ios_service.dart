import 'package:flutter/services.dart';

class SafeContentIosService {
  static const MethodChannel _channel = MethodChannel('safe_content/ios');

  Future<bool> isAuthorizationGranted() async {
    return await _channel.invokeMethod<bool>('isAuthorizationGranted') ?? false;
  }

  Future<bool> requestAuthorization() async {
    return await _channel.invokeMethod<bool>('requestAuthorization') ?? false;
  }

  Future<bool> requestNetworkPermission() async {
    return await _channel.invokeMethod<bool>('requestNetworkPermission') ?? false;
  }

  Future<bool> startWebProtection() async {
    return await _channel.invokeMethod<bool>('startWebProtection') ?? false;
  }

  Future<void> stopWebProtection() async {
    await _channel.invokeMethod<void>('stopWebProtection');
  }

  Future<bool> isWebProtectionRunning() async {
    return await _channel.invokeMethod<bool>('isWebProtectionRunning') ?? false;
  }
}
