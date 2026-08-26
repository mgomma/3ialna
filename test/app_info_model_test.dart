import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/domain/models/app_info.dart';

void main() {
  test('round-trips installed app metadata through map serialization', () {
    const AppInfo original = AppInfo(
      packageName: 'com.example.game',
      appName: 'Example Game',
      iconBase64: 'aW1hZ2U=',
      isSystemApp: false,
      isEnabled: true,
      installTime: 10,
      updateTime: 20,
    );

    final AppInfo restored = AppInfo.fromMap(original.toMap());

    expect(restored.packageName, original.packageName);
    expect(restored.appName, original.appName);
    expect(restored.iconBase64, original.iconBase64);
    expect(restored.isSystemApp, original.isSystemApp);
    expect(restored.isEnabled, original.isEnabled);
    expect(restored.installTime, original.installTime);
    expect(restored.updateTime, original.updateTime);
  });

  test('uses safe defaults for optional app metadata', () {
    final AppInfo app = AppInfo.fromMap(<String, dynamic>{
      'packageName': 'com.example.app',
      'appName': 'Example',
    });

    expect(app.iconBase64, isNull);
    expect(app.isSystemApp, isFalse);
    expect(app.isEnabled, isTrue);
    expect(app.installTime, 0);
    expect(app.updateTime, 0);
  });

  test('copyWith changes selected fields while retaining the rest', () {
    const AppInfo original = AppInfo(
      packageName: 'com.example.app',
      appName: 'Example',
      isSystemApp: true,
      isEnabled: false,
      installTime: 10,
      updateTime: 20,
    );

    final AppInfo updated = original.copyWith(
      appName: 'Updated',
      isEnabled: true,
    );

    expect(updated.packageName, original.packageName);
    expect(updated.appName, 'Updated');
    expect(updated.isSystemApp, isTrue);
    expect(updated.isEnabled, isTrue);
    expect(updated.installTime, original.installTime);
    expect(updated.updateTime, original.updateTime);
  });
}
