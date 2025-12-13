import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/social_media_apps.dart';
import '../../data/local/app_blocking_service.dart';
import '../../data/local/settings_service.dart';
import '../../data/system/accessibility_service_helper.dart';
import '../../data/system/app_blocking_channel.dart';
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
  String? packageName;
  final AppBlockingService _blockingService = AppBlockingService();
  final AppBlockingChannel _blockingChannel = AppBlockingChannel();
  final AccessibilityServiceHelper _accessibilityHelper = AccessibilityServiceHelper();

  @override
  void initState() {
    super.initState();
    _readOverlayContent();
    _checkAccessibilityServiceOnInit();
  }

  /// Checks if AccessibilityService is enabled when overlay first shows.
  /// If not enabled, shows a snackbar to inform user (non-blocking).
  Future<void> _checkAccessibilityServiceOnInit() async {
    try {
      final isEnabled = await _accessibilityHelper.isAccessibilityServiceEnabled();
      if (!isEnabled && mounted) {
        // Show a non-blocking snackbar to inform user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Enable Accessibility Service for app blocking to work.',
                ),
                action: SnackBarAction(
                  label: 'Open Settings',
                  onPressed: () async {
                    await _accessibilityHelper.openAccessibilitySettings();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      // Ignore errors
      debugPrint('Error checking AccessibilityService: $e');
    }
  }

  Future<void> _readOverlayContent() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    final SettingsService settings =
        SettingsService(prefs);

    final OverlayData data =
        settings.loadOverlayData();

    // First, try to get package name from SharedPreferences (saved by service)
    String? foundPackage = prefs.getString('flutter.overlay_package_name');

    // If not found, try to find package name from app name in socialMediaApps
    if (foundPackage == null || foundPackage.isEmpty) {
      for (final entry in socialMediaApps.entries) {
        if (entry.value == data.appName) {
          foundPackage = entry.key;
          break;
        }
      }
    }

    setState(() {
      appName = data.appName;
      usedMinutes = data.usedMinutes;
      limitMinutes = data.limitMinutes;
      packageName = foundPackage;
    });
  }

  Future<void> _dismissOverlay() async {
    const OverlayService().closeOverlay();
  }

  Future<void> _takeABreak() async {
    if (packageName == null || packageName!.isEmpty) {
      // If we don't have package name, just close overlay
      await _dismissOverlay();
      return;
    }

    try {
      // Check if AccessibilityService is enabled BEFORE blocking
      final isEnabled = await _accessibilityHelper.isAccessibilityServiceEnabled();
      
      if (!isEnabled) {
        // Show dialog to enable AccessibilityService and open settings
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Enable App Blocking'),
              content: const Text(
                'To block apps, you need to enable the Accessibility Service.\n\n'
                'This allows the app to prevent blocked apps from opening.\n\n'
                'Tap "Open Settings" to enable it, then return and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await _accessibilityHelper.openAccessibilitySettings();
            // Don't close overlay - let user come back and try again
            return;
          } else {
            // User cancelled - just close overlay
            await _dismissOverlay();
            return;
          }
        }
        return;
      }

      // AccessibilityService is enabled - proceed with blocking
      // Use native method channel to block app - this will:
      // 1. Save block to SharedPreferences
      // 2. Force close the app
      // 3. Return to home screen
      final success = await _blockingChannel.blockApp(packageName!, durationMinutes: 30);
      
      if (success) {
        // Close overlay after a short delay to ensure app is closed
        await Future.delayed(const Duration(milliseconds: 500));
        await _dismissOverlay();
      } else {
        // Fallback: try Flutter service method
        await _blockingService.blockApp(packageName!, durationMinutes: 30);
        await _blockingChannel.closeAppAndGoHome();
        await Future.delayed(const Duration(milliseconds: 500));
        await _dismissOverlay();
      }
    } catch (e) {
      // Error handling - still try to close
      await _dismissOverlay();
    }
  }

  Future<void> _addMoreTime() async {
    // Optional: Add 5-10 more minutes (snooze feature)
    // For now, just dismiss overlay
    await _dismissOverlay();
  }

  @override
  Widget build(BuildContext context) {
    // Get full screen dimensions including system UI areas
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;
    
    // Calculate full screen size including system UI
    // Add extra padding to ensure we cover navigation bar
    final fullWidth = screenSize.width;
    final fullHeight = screenSize.height + padding.top + padding.bottom + 100; // Extra 100px to cover navigation bar
    
    return GestureDetector(
      // Prevent all dragging gestures
      onPanStart: (_) {},
      onPanUpdate: (_) {},
      onPanEnd: (_) {},
      onHorizontalDragStart: (_) {},
      onHorizontalDragUpdate: (_) {},
      onHorizontalDragEnd: (_) {},
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      // Block all taps outside the content area
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: SizedBox(
          // Use explicit size to cover full screen including system UI
          width: fullWidth,
          height: fullHeight,
          child: Stack(
            // Use Stack to ensure full screen coverage
            children: [
              // Full screen blocking layer - covers entire screen including system UI
              // Use negative values to extend beyond visible area to cover navigation bar
              Positioned.fill(
                child: GestureDetector(
                  // Block all touches on the background
                  onTap: () {},
                  onPanStart: (_) {},
                  onPanUpdate: (_) {},
                  onPanEnd: (_) {},
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Centered content - buttons are clickable
              Center(
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
                        'Time limit exceeded for $appName',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve used this app for $usedMinutes minutes today',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily limit: $limitMinutes minutes',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.white60,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _takeABreak,
                          child: const Text(
                            'Take a Break',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white70,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _addMoreTime,
                          child: const Text(
                            'Add 5 More Minutes',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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


