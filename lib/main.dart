import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/overlay/overlay_warning_screen.dart';

/// Entry point for the main application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocialMediaLimiterApp());
}

/// Entry point for the overlay window.
///
/// This needs to be a top-level function so that it can be used from the
/// background isolate started by `flutter_overlay_window`.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayWarningApp());
}

/// Root application widget using Material 3 theming.
class SocialMediaLimiterApp extends StatelessWidget {
  const SocialMediaLimiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color seedColor = Colors.deepPurple;

    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}