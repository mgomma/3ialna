import '../constants/social_media_apps.dart';
import '../../domain/models/app_info.dart';
import '../../domain/models/managed_app_category.dart';

/// Android's `ApplicationInfo.CATEGORY_GAME` constant.
const int _androidCategoryGame = 0;

/// Android's `ApplicationInfo.CATEGORY_SOCIAL` constant.
const int _androidCategorySocial = 4;

/// Classifies an installed app into Games, Social Media, or Others.
///
/// Classification is fully on-device and privacy-preserving: it only
/// consults the local package-name registry and the OS-declared app
/// category already returned by the platform's app list query. No app
/// inventory or metadata is transmitted off the device.
class AppCategoryClassifier {
  const AppCategoryClassifier._();

  /// Returns the best-guess category for [app], defaulting to [ManagedAppCategory.other]
  /// when no known signal matches.
  static ManagedAppCategory classify(AppInfo app) {
    return classifyPackage(app.packageName, androidCategory: app.androidCategory);
  }

  /// Same as [classify] but works directly off a package name, useful when
  /// only the identifier is known (e.g. registry seeding).
  static ManagedAppCategory classifyPackage(String packageName, {int? androidCategory}) {
    if (gameApps.containsKey(packageName)) return ManagedAppCategory.games;
    if (socialMediaApps.containsKey(packageName)) return ManagedAppCategory.socialMedia;
    if (androidCategory == _androidCategoryGame) return ManagedAppCategory.games;
    if (androidCategory == _androidCategorySocial) return ManagedAppCategory.socialMedia;
    return ManagedAppCategory.other;
  }
}
