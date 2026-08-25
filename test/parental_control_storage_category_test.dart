import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/parental_control_storage_service.dart';
import 'package:mu_super_app/domain/models/app_info.dart';
import 'package:mu_super_app/domain/models/managed_app_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reconciles known installed apps without overwriting parent assignments', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    await storage.setAppCategory('com.facebook.katana', ManagedAppCategory.games);

    final Map<String, ManagedAppCategory> categories =
        await storage.reconcileInstalledAppCategories(<AppInfo>[
      const AppInfo(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
        isSystemApp: false,
        isEnabled: true,
        installTime: 0,
        updateTime: 0,
      ),
      const AppInfo(
        packageName: 'com.roblox.client',
        appName: 'Roblox',
        isSystemApp: false,
        isEnabled: true,
        installTime: 0,
        updateTime: 0,
      ),
      const AppInfo(
        packageName: 'com.example.unknown',
        appName: 'Unknown',
        isSystemApp: false,
        isEnabled: true,
        installTime: 0,
        updateTime: 0,
      ),
    ]);

    expect(categories['com.facebook.katana'], ManagedAppCategory.games);
    expect(categories['com.roblox.client'], ManagedAppCategory.games);
    expect(categories.containsKey('com.example.unknown'), isFalse);
  });
}
