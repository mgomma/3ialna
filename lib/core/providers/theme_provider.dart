import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;
  
  ThemeProvider(this._storageService) {
    _initializeTheme();
  }

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> _initializeTheme() async {
    _setLoading(true);
    try {
      final savedTheme = _storageService.getTheme();
      _themeMode = _getThemeModeFromString(savedTheme);
    } catch (e) {
      // Default to system theme if there's an error
      _themeMode = ThemeMode.system;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _setLoading(true);
    try {
      _themeMode = mode;
      await _storageService.saveTheme(_getStringFromThemeMode(mode));
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  ThemeMode _getThemeModeFromString(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Theme display names
  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
