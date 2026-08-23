import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs)
      : _locale = Locale(_prefs.getString(_key) ?? 'ar');

  static const String _key = 'app_locale';
  static late LocaleController instance;

  final SharedPreferences _prefs;
  Locale _locale;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> setLocale(Locale locale) async {
    final String languageCode = locale.languageCode == 'ar' ? 'ar' : 'en';
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    await _prefs.setString(_key, languageCode);
    notifyListeners();
  }
}
