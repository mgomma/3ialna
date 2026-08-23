import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mu_super_app/data/local/locale_controller.dart';

void main() {
  test('defaults to Arabic and persists an English selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocaleController controller = LocaleController(prefs);

    expect(controller.locale.languageCode, 'ar');

    await controller.setLocale(const Locale('en'));
    expect(controller.locale.languageCode, 'en');
    expect(prefs.getString('app_locale'), 'en');
  });

  test('restores the saved Arabic locale', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'app_locale': 'ar'});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocaleController controller = LocaleController(prefs);

    expect(controller.isArabic, isTrue);
  });
}
