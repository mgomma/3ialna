import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/prayer_lock_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final apiService = ApiService();
  
  runApp(MyApp(
    storageService: storageService,
    apiService: apiService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService, storageService)),
        ChangeNotifierProvider(create: (_) => PrayerLockProvider()),
      ],
      child: Consumer4<LanguageProvider, ThemeProvider, AuthProvider, PrayerLockProvider>(
        builder: (context, languageProvider, themeProvider, authProvider, prayerLockProvider, child) {
          return Stack(
            children: [
              MaterialApp(
                title: AppConstants.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                locale: languageProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', 'US'),
                  Locale('ar', 'SA'),
                ],
                initialRoute: authProvider.isAuthenticated 
                    ? AppRoutes.home 
                    : AppRoutes.login,
                onGenerateRoute: AppRoutes.generateRoute,
              ),

              // Prayer Lock Overlay
              if (prayerLockProvider.isLocked)
                Positioned.fill(
                  child: Material(
                    color: Colors.black.withOpacity(0.9),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            prayerLockProvider.prayerName?.toUpperCase() ?? 'PRAYER',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            prayerLockProvider.lockStart != null && prayerLockProvider.lockEnd != null
                                ? 'Locked until ${prayerLockProvider.lockEnd!.toLocal().toString()}'
                                : 'Device locked for prayer',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
