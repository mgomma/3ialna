import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/settings_service.dart';
import '../../data/system/overlay_service.dart';
import '../../domain/models/overlay_data.dart';
import '../../l10n/app_localizations.dart';

/// A minimal app used inside the overlay window.
class OverlayWarningApp extends StatelessWidget {
  const OverlayWarningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates:
          const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      home: const OverlayWarningScreen(),
    );
  }
}

/// The warning overlay content shown when time limit is exceeded.
class OverlayWarningScreen extends StatefulWidget {
  const OverlayWarningScreen({super.key});

  @override
  State<OverlayWarningScreen> createState() =>
      _OverlayWarningScreenState();
}

class _OverlayWarningScreenState
    extends State<OverlayWarningScreen> {
  String appName = 'Social App';
  int usedMinutes = 0;
  int limitMinutes = 0;

  @override
  void initState() {
    super.initState();
    _readOverlayContent();
  }

  Future<void> _readOverlayContent() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    final SettingsService settings =
        SettingsService(prefs);

    final OverlayData data =
        settings.loadOverlayData();

    setState(() {
      appName = data.appName;
      usedMinutes = data.usedMinutes;
      limitMinutes = data.limitMinutes;
    });
  }

  Future<void> _dismissOverlay() async {
    const OverlayService().closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.timeLimitReachedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.timeLimitReachedMessage(
                  appName: appName,
                  usedMinutes: usedMinutes,
                  limitMinutes: limitMinutes,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _dismissOverlay,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    child: Text(
                      context.l10n.takeABreak,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


