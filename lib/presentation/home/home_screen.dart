import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/social_media_apps.dart';
import '../../data/local/settings_service.dart';
import '../../data/system/app_usage_service.dart';
import '../../data/system/notification_service.dart';
import '../../data/system/overlay_service.dart';
import '../../data/system/prayer_lock_scheduler.dart';
import '../../data/system/prayer_time_service.dart';
import '../../domain/models/overlay_data.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import '../../l10n/app_localizations.dart';
import '../prayer_settings/prayer_lock_settings_screen.dart';

const MethodChannel _serviceChannel =
    MethodChannel('social_limiter/service');

/// Main home screen that shows usage, time limits, and monitoring controls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Usage data in whole minutes per package name.
  Map<String, int> usageDataMinutes = {};

  /// Total device usage in minutes.
  int totalUsageMinutes = 0;

  /// Daily time limit in minutes.
  int timeLimitMinutes = 1;

  /// Whether monitoring is currently active.
  bool isMonitoring = false;

  /// Timer used to periodically check usage.
  Timer? monitoringTimer;

  bool isLoading = false;

  late SettingsService _settings;
  final AppUsageService _usageService =
      const AppUsageService();
  final OverlayService _overlayService =
      const OverlayService();
  final PrayerTimeService _prayerTimeService =
      const PrayerTimeService();
  final NotificationService _notificationService =
      NotificationService();
  late PrayerLockScheduler _prayerLockScheduler;

  PrayerLockSettings? _prayerSettings;
  Timer? _prayerStatusTimer;
  bool _prayerLockOverlayShown = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    _settings = SettingsService(prefs);

    _prayerLockScheduler = PrayerLockScheduler(
      prayerTimeService: _prayerTimeService,
      notificationService: _notificationService,
      overlayService: _overlayService,
      settingsService: _settings,
    );

    _loadSettings();
    _loadPrayerSettings();
    await _askPermissionBeforeSystemSettings();
    await _askUsageAccessInfoDialog();
    await _refreshUsage();

    if (isMonitoring) {
      await _startBackgroundMonitoring();
      _startMonitoring();
    }

    _startPrayerStatusUpdates();
    _initializePrayerLockScheduler();
    
    // Check prayer locks immediately on startup
    await _checkPrayerLocks();
  }

  void _initializePrayerLockScheduler() {
    if (_prayerSettings != null && _prayerSettings!.enabled) {
      _prayerLockScheduler.start(_prayerSettings!);
    } else {
      _prayerLockScheduler.stop();
    }
  }

  void _loadPrayerSettings() {
    setState(() {
      _prayerSettings = _settings.loadPrayerLockSettings();
    });
    _initializePrayerLockScheduler();
  }

  void _startPrayerStatusUpdates() {
    _prayerStatusTimer?.cancel();
    _prayerStatusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    monitoringTimer?.cancel();
    _prayerStatusTimer?.cancel();
    _prayerLockScheduler.stop();
    super.dispose();
  }

  /// Loads saved time limit and monitoring state from settings.
  void _loadSettings() {
    setState(() {
      timeLimitMinutes = _settings.timeLimitMinutes;
      isMonitoring = _settings.isMonitoring;
    });
  }

  /// Saves time limit and monitoring state to settings.
  Future<void> _saveSettings() async {
    await _settings.setTimeLimitMinutes(timeLimitMinutes);
    await _settings.setIsMonitoring(isMonitoring);
  }

  /// Shows an in-app dialog before navigating to system settings
  /// for overlay permissions.
  Future<void> _askPermissionBeforeSystemSettings() async {
    final bool alreadyGranted =
        await _overlayService.hasOverlayPermission();
    if (alreadyGranted) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.overlayPermissionTitle),
          content: Text(context.l10n.overlayPermissionBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.notNow),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.continueLabel),
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      await _overlayService.ensurePermissions();
    }
  }

  /// Shows an informational dialog about usage data access.
  ///
  /// The user needs to enable "Usage access" in system settings so the app
  /// can read how long social media apps have been used.
  Future<void> _askUsageAccessInfoDialog() async {
    if (_settings.usageDialogShown) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.usageAccessTitle),
          content: Text(context.l10n.usageAccessBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.gotIt),
            ),
          ],
        );
      },
    );
    await _settings.setUsageDialogShown();
  }

  /// Manually refreshes usage data once.
  Future<void> _refreshUsage() async {
    setState(() {
      isLoading = true;
    });
    await _checkAppUsage();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetches app usage for today and updates state.
  ///
  /// Also triggers overlay when any social app or total usage exceeds the limit.
  Future<void> _checkAppUsage() async {
    final AppUsageSummary usageSummary =
        await _usageService.loadTodayUsageSummary();

    if (!mounted) {
      return;
    }

    setState(() {
      usageDataMinutes = usageSummary.perAppMinutes;
      totalUsageMinutes = usageSummary.totalMinutes;
    });

    bool overlayShown = false;
    for (final MapEntry<String, int> entry
        in usageDataMinutes.entries) {
      // Trigger blocker as soon as usage meets or exceeds the limit.
      if (entry.value >= timeLimitMinutes) {
        overlayShown = true;
        await _showOverlayWarning(
          packageName: entry.key,
          minutesUsed: entry.value,
        );
        break;
      }
    }

    if (!overlayShown &&
        usageSummary.totalMinutes >= timeLimitMinutes) {
      await _showOverlayWarning(
        packageName: totalUsagePackage,
        minutesUsed: usageSummary.totalMinutes,
      );
    }
  }

  /// Shows an overlay warning for the specified app.
  Future<void> _showOverlayWarning({
    required String packageName,
    required int minutesUsed,
  }) async {
    final String appName =
        socialMediaApps[packageName] ?? packageName;

    final OverlayData data = OverlayData(
      appName: appName,
      usedMinutes: minutesUsed,
      limitMinutes: timeLimitMinutes,
    );

    await _settings.saveOverlayData(data);
    await _overlayService.showLimitWarning(data);
  }

  /// Starts periodic monitoring every 30 seconds.
  void _startMonitoring() {
    monitoringTimer?.cancel();
    monitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _checkAppUsage();
        _checkPrayerLocks();
      },
    );
  }

  /// Checks if we're in a prayer lock period and shows overlay if needed.
  Future<void> _checkPrayerLocks() async {
    if (_prayerSettings == null || !_prayerSettings!.enabled) {
      return;
    }

    if (_prayerSettings!.latitude == null ||
        _prayerSettings!.longitude == null) {
      return;
    }

    final DateTime now = DateTime.now();
    final Map<Prayer, DateTime>? prayerTimes =
        _prayerTimeService.calculatePrayerTimes(now, _prayerSettings!);

    if (prayerTimes == null) {
      return;
    }

    // Check each prayer to see if we're in its lock period
    bool inLockPeriod = false;
    for (final MapEntry<Prayer, DateTime> entry in prayerTimes.entries) {
      final Prayer prayer = entry.key;
      final DateTime prayerTime = entry.value;
      final int lockDuration =
          _prayerSettings!.getLockDuration(prayer, prayerTime);
      final DateTime lockEndTime =
          prayerTime.add(Duration(minutes: lockDuration));

      // Check if current time is between prayer time and lock end time
      if (now.isAfter(prayerTime) && now.isBefore(lockEndTime)) {
        inLockPeriod = true;
        // We're in a lock period - show overlay if not already shown
        if (!_prayerLockOverlayShown) {
          final OverlayData data = OverlayData(
            appName: 'Prayer Time Lock - ${prayer.displayName}',
            usedMinutes: 0,
            limitMinutes: lockDuration,
          );

          await _settings.saveOverlayData(data);
          await _overlayService.showLimitWarning(data);
          _prayerLockOverlayShown = true;
        }
        break; // Only one prayer can be active at a time
      }
    }
    
    // Reset flag if we're not in any lock period
    if (!inLockPeriod) {
      _prayerLockOverlayShown = false;
    }
  }

  /// Stops periodic monitoring.
  void _stopMonitoring() {
    monitoringTimer?.cancel();
    monitoringTimer = null;
  }

  /// Toggles monitoring state and persists the change.
  Future<void> _toggleMonitoring() async {
    setState(() {
      isMonitoring = !isMonitoring;
    });

    if (isMonitoring) {
      await _startBackgroundMonitoring();
      _startMonitoring();
      await _checkAppUsage();
    } else {
      await _stopBackgroundMonitoring();
      _stopMonitoring();
    }

    await _saveSettings();
  }

  /// Adjusts the time limit in 5-minute increments.
  Future<void> _adjustTimeLimit(int delta) async {
    final int newLimit = (timeLimitMinutes + delta)
        .clamp(5, 24 * 60);
    if (newLimit == timeLimitMinutes) {
      return;
    }

    setState(() {
      timeLimitMinutes = newLimit;
    });
    await _saveSettings();
  }

  /// Starts the native Android foreground service for real background checks.
  Future<void> _startBackgroundMonitoring() async {
    try {
      await _serviceChannel.invokeMethod(
        'startMonitoringService',
      );
    } catch (_) {
      // On non-Android platforms this will fail; we can safely ignore.
    }
  }

  /// Stops the native Android foreground service.
  Future<void> _stopBackgroundMonitoring() async {
    try {
      await _serviceChannel.invokeMethod(
        'stopMonitoringService',
      );
    } catch (_) {
      // Ignore errors on unsupported platforms.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToPrayerSettings,
            tooltip: 'Prayer Lock Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshUsage,
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildPrayerStatusCard(colorScheme),
              const SizedBox(height: 16),
              _buildTimeLimitCard(colorScheme),
              const SizedBox(height: 16),
              _buildMonitorToggle(colorScheme),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildUsageList(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeLimitCard(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.dailyTimeLimit,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$timeLimitMinutes '
                    '${context.l10n.minutesSuffix}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used today: $totalUsageMinutes '
                    '${context.l10n.minutesSuffix}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () =>
                      _adjustTimeLimit(-5),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () =>
                      _adjustTimeLimit(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorToggle(ColorScheme colorScheme) {
    final bool active = isMonitoring;
    final Color backgroundColor = active
        ? Colors.red
        : Colors.green;
    final IconData icon =
        active ? Icons.pause : Icons.play_arrow;
    final String label = active
        ? context.l10n.stopMonitoring
        : context.l10n.startMonitoring;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _toggleMonitoring,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildUsageList(ColorScheme colorScheme) {
    if (usageDataMinutes.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noUsageTitle,
            style:
                Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noUsageSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      );
    }

    final List<MapEntry<String, int>> entries =
        usageDataMinutes.entries.toList()
          ..sort(
            (MapEntry<String, int> a,
                    MapEntry<String, int> b) =>
                b.value.compareTo(a.value),
          );

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, int> entry =
            entries[index];
        final String packageName = entry.key;
        final int usedMinutes = entry.value;
        final String appName =
            socialMediaApps[packageName] ??
                packageName;

        final double progress =
            (usedMinutes / timeLimitMinutes)
                .clamp(0, 2)
                .toDouble();
        final bool overLimit =
            usedMinutes > timeLimitMinutes;

        final Color progressColor =
            overLimit ? Colors.red : Colors.blue;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor:
                      colorScheme.primaryContainer,
                  child: Text(
                    appName.isNotEmpty
                        ? appName[0]
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ),
                          if (overLimit)
                            Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress > 1
                              ? 1
                              : progress,
                          minHeight: 8,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(progressColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$usedMinutes min / '
                        '$timeLimitMinutes min',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToPrayerSettings() async {
    final PrayerLockSettings? result =
        await Navigator.of(context).push<PrayerLockSettings>(
      MaterialPageRoute<PrayerLockSettings>(
        builder: (BuildContext context) =>
            const PrayerLockSettingsScreen(),
      ),
    );

    if (result != null) {
      await _settings.savePrayerLockSettings(result);
      _loadPrayerSettings();
    }
  }

  Widget _buildPrayerStatusCard(ColorScheme colorScheme) {
    if (_prayerSettings == null || !_prayerSettings!.enabled) {
      return const SizedBox.shrink();
    }

    final ({Prayer prayer, DateTime time})? nextPrayer =
        _prayerTimeService.getNextPrayer(_prayerSettings!);

    if (nextPrayer == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const Icon(Icons.location_off, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location not set for prayer times',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Duration timeUntil = nextPrayer.time.difference(DateTime.now());
    final String timeString = _formatDuration(timeUntil);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.access_time,
              size: 32,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Next Prayer: ${nextPrayer.prayer.displayName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'At ${_formatTime(nextPrayer.time)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Prayer time passed';
    }

    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatTime(DateTime time) {
    // Ensure we're working with local time
    final DateTime localTime = time.toLocal();
    final int hour = localTime.hour;
    final int minute = localTime.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    // Get timezone abbreviation if available
    final String timeZoneName = _getTimeZoneAbbreviation(localTime);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period $timeZoneName';
  }
  
  String _getTimeZoneAbbreviation(DateTime dateTime) {
    // Get timezone offset
    final Duration offset = dateTime.timeZoneOffset;
    final int hours = offset.inHours;
    final int minutes = (offset.inMinutes % 60).abs();
    
    // Format as +/-HH:MM
    final String sign = hours >= 0 ? '+' : '-';
    final String hoursStr = hours.abs().toString().padLeft(2, '0');
    final String minutesStr = minutes.toString().padLeft(2, '0');
    
    return 'UTC$sign$hoursStr:$minutesStr';
  }
}


