import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/core/classification/app_category_classifier.dart';
import 'package:mu_super_app/domain/models/app_info.dart';
import 'package:mu_super_app/domain/models/managed_app_category.dart';

AppInfo _app(String packageName, {int? androidCategory}) => AppInfo(
      packageName: packageName,
      appName: packageName,
      isSystemApp: false,
      isEnabled: true,
      installTime: 0,
      updateTime: 0,
      androidCategory: androidCategory,
    );

void main() {
  test('classifies a known registry social app as social media', () {
    expect(
      AppCategoryClassifier.classify(_app('com.instagram.android')),
      ManagedAppCategory.socialMedia,
    );
  });

  test('classifies a known registry game as games', () {
    expect(
      AppCategoryClassifier.classify(_app('com.roblox.client')),
      ManagedAppCategory.games,
    );
  });

  test('falls back to the OS-declared category when the app is unregistered', () {
    expect(
      AppCategoryClassifier.classify(_app('com.example.newgame', androidCategory: 0)),
      ManagedAppCategory.games,
    );
    expect(
      AppCategoryClassifier.classify(_app('com.example.newsocial', androidCategory: 4)),
      ManagedAppCategory.socialMedia,
    );
  });

  test('classifies a fully unknown app as other', () {
    expect(
      AppCategoryClassifier.classify(_app('com.example.unknown')),
      ManagedAppCategory.other,
    );
  });

  test('registry match takes priority over a conflicting OS-declared category', () {
    expect(
      AppCategoryClassifier.classify(_app('com.roblox.client', androidCategory: 4)),
      ManagedAppCategory.games,
    );
  });
}
