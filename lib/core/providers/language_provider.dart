import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storageService;
  
  LanguageProvider(this._storageService) {
    _initializeLanguage();
  }

  Locale _locale = const Locale('en', 'US');
  bool _isLoading = false;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> _initializeLanguage() async {
    _setLoading(true);
    try {
      final savedLanguage = _storageService.getLanguage();
      _locale = Locale(savedLanguage, savedLanguage == 'ar' ? 'SA' : 'US');
    } catch (e) {
      // Default to English if there's an error
      _locale = const Locale('en', 'US');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _setLoading(true);
    try {
      final countryCode = languageCode == 'ar' ? 'SA' : 'US';
      _locale = Locale(languageCode, countryCode);
      
      await _storageService.saveLanguage(languageCode);
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguage = _locale.languageCode == 'ar' ? 'en' : 'ar';
    await setLanguage(newLanguage);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Text direction helper
  TextDirection get textDirection {
    return _locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

  // Language display names
  String get currentLanguageName {
    return _locale.languageCode == 'ar' ? 'العربية' : 'English';
  }

  String get otherLanguageName {
    return _locale.languageCode == 'ar' ? 'English' : 'العربية';
  }
}
