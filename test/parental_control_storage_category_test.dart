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
    // Unknown apps are still bucketed (quick setup) rather than left unassigned.
    expect(categories['com.example.unknown'], ManagedAppCategory.other);
  });

  test('does not overwrite a parent override with the registry default', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    // Parent explicitly moves a normally-social app into Others.
    await storage.setAppCategory('com.instagram.android', ManagedAppCategory.other);

    final Map<String, ManagedAppCategory> categories =
        await storage.reconcileInstalledAppCategories(<AppInfo>[
      const AppInfo(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        isSystemApp: false,
        isEnabled: true,
        installTime: 0,
        updateTime: 0,
      ),
    ]);

    expect(categories['com.instagram.android'], ManagedAppCategory.other);
  });

  test('uses the OS-declared category for an unregistered app during reconciliation', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();

    final Map<String, ManagedAppCategory> categories =
        await storage.reconcileInstalledAppCategories(<AppInfo>[
      const AppInfo(
        packageName: 'com.example.indiegame',
        appName: 'Indie Game',
        isSystemApp: false,
        isEnabled: true,
        installTime: 0,
        updateTime: 0,
        androidCategory: 0,
      ),
    ]);

    expect(categories['com.example.indiegame'], ManagedAppCategory.games);
  });

  test('reclassifies an unknown app once the parent clears their override', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    const AppInfo unknownApp = AppInfo(
      packageName: 'com.example.unknown',
      appName: 'Unknown',
      isSystemApp: false,
      isEnabled: true,
      installTime: 0,
      updateTime: 0,
    );

    final Map<String, ManagedAppCategory> firstPass =
        await storage.reconcileInstalledAppCategories(<AppInfo>[unknownApp]);
    expect(firstPass['com.example.unknown'], ManagedAppCategory.other);

    await storage.setAppCategory('com.example.unknown', ManagedAppCategory.games);
    expect((await storage.getAppCategories())['com.example.unknown'], ManagedAppCategory.games);

    await storage.setAppCategory('com.example.unknown', ManagedAppCategory.unassigned);
    final Map<String, ManagedAppCategory> secondPass =
        await storage.reconcileInstalledAppCategories(<AppInfo>[unknownApp]);
    expect(secondPass['com.example.unknown'], ManagedAppCategory.other);
  });
}
