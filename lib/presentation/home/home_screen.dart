import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/social_media_apps.dart';
import '../../data/local/settings_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/accessibility_service_helper.dart';
import '../../data/system/child_shortcut_service.dart';
import '../../data/system/app_usage_service.dart';
import '../../data/local/age_safety_profile_service.dart';
import '../../data/system/drupal_sync_service.dart';
import '../../data/system/first_run_permission_service.dart';
import '../../data/system/social_auth_service.dart';
import '../../data/system/kiosk_service.dart';
import '../../data/system/notification_service.dart';
import '../../data/system/overlay_service.dart';
import '../../data/system/prayer_lock_scheduler.dart';
import '../../data/system/prayer_time_service.dart';
import '../../domain/models/daily_usage_report.dart';
import '../../domain/models/age_safety_profile.dart';
import '../../domain/models/country_word_profile.dart';
import '../../domain/models/local_user_profile.dart';
import '../../domain/models/overlay_data.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import '../../domain/models/social_auth_profile.dart';
import '../../l10n/app_localizations.dart';
import '../parental_control/parent_dashboard_screen.dart';
import '../parental_control/pin_auth_screen.dart';
import '../prayer_settings/prayer_lock_settings_screen.dart';
import '../widgets/disclosure_dialog.dart';

const MethodChannel _serviceChannel = MethodChannel('social_limiter/service');

/// Main home screen that shows usage, time limits, and monitoring controls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
  late AgeSafetyProfileService _childProfiles;
  final AppUsageService _usageService = const AppUsageService();
  final FirstRunPermissionService _firstRunPermissions =
      const FirstRunPermissionService();
  final OverlayService _overlayService = const OverlayService();
  final PrayerTimeService _prayerTimeService = const PrayerTimeService();
  final NotificationService _notificationService = NotificationService();
  late PrayerLockScheduler _prayerLockScheduler;

  PrayerLockSettings? _prayerSettings;
  Timer? _prayerStatusTimer;

  final AccessibilityServiceHelper _accessibilityHelper = AccessibilityServiceHelper();
  bool _isAccessibilityEnabled = false;
  bool _isDeviceLocked = false;
  OverlayData? _lastOverlayData;
  CountryWordProfile? _countryWordProfile;
  final DrupalSyncService _drupalSyncService = DrupalSyncService();
  final SocialAuthService _socialAuthService = SocialAuthService();
  LocalUserProfile? _profile;
  bool _essentialPermissionGuideInProgress = false;
  bool _homeSettingsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _settings = SettingsService(prefs);
    _homeSettingsInitialized = true;

    _childProfiles = AgeSafetyProfileService(prefs);
    await _childProfiles.ensureDefaultChild();
    AgeSafetyProfileService.changes.addListener(_onChildProfileChanged);
    ChildShortcutService.listen((String childId) async {
      await _childProfiles.setActiveChild(childId);
      _loadSettings();
    });
    final String? shortcutChildId = await ChildShortcutService.consumeInitialChildId();
    if (shortcutChildId != null) await _childProfiles.setActiveChild(shortcutChildId);
    await ChildShortcutService.sync(_childProfiles.loadChildren());

    // Listen for device lock events from native side
    const MethodChannel('parental_control/kiosk').setMethodCallHandler((call) async {
      if (call.method == 'onDeviceLocked') {
        _loadSettings();
      }
    });
    const MethodChannel('parental_control/onboarding')
        .setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onUsageAccessSettingsResult') {
        await _refreshAfterSystemSettingsReturn();
      }
    });

    _prayerLockScheduler = PrayerLockScheduler(
      prayerTimeService: _prayerTimeService,
      notificationService: _notificationService,
      overlayService: _overlayService,
      settingsService: _settings,
    );

    _loadSettings();
    _loadPrayerSettings();
    await _runEssentialPermissionGuide();
    await _askPermissionBeforeSystemSettings();
    await _refreshUsage();
    _loadCountryWordProfile();
    _profile = await _drupalSyncService.getProfile();

    if (isMonitoring) {
      await _startBackgroundMonitoring();
      _startMonitoring();
    }

    _startPrayerStatusUpdates();
    _initializePrayerLockScheduler();
    await _ensureCountryProfileSelected();

    // Check accessibility service status
    _isAccessibilityEnabled = await _accessibilityHelper.isAccessibilityServiceEnabled();

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
    final PrayerLockSettings base = _settings.loadPrayerLockSettings();
    final AgeSafetyProfilePreset childPreset = _childProfiles.load();
    setState(() {
      _prayerSettings = base.copyWith(
        enabled: base.enabled && childPreset.prayerLockEnabled,
        lockDurations: <Prayer, int>{
          for (final Prayer prayer in Prayer.values) prayer: childPreset.prayerLockMinutes,
        },
        fridayDhuhrDuration: childPreset.prayerLockMinutes,
      );
    });
    _initializePrayerLockScheduler();
  }

  void _onChildProfileChanged() {
    if (!mounted) return;
    _loadSettings();
    _loadPrayerSettings();
    ChildShortcutService.sync(_childProfiles.loadChildren());
  }

  void _startPrayerStatusUpdates() {
    _prayerStatusTimer?.cancel();
    _prayerStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (mounted) {
        final bool isEnabled = await _accessibilityHelper.isAccessibilityServiceEnabled();
        setState(() {
          _isAccessibilityEnabled = isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AgeSafetyProfileService.changes.removeListener(_onChildProfileChanged);
    monitoringTimer?.cancel();
    _prayerStatusTimer?.cancel();
    _prayerLockScheduler.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAfterSystemSettingsReturn();
    }
  }

  Future<void> _refreshAfterSystemSettingsReturn() async {
    if (!mounted ||
        !_homeSettingsInitialized ||
        _essentialPermissionGuideInProgress) {
      return;
    }
    await _refreshUsage();
    if (!mounted) return;
    _loadPrayerSettings();
  }

  /// Loads saved time limit and monitoring state from settings.
  void _loadSettings() {
    setState(() {
      timeLimitMinutes = _settings.timeLimitMinutes;
      isMonitoring = _settings.isMonitoring;
      _isDeviceLocked = _settings.isDeviceLocked;
      if (_isDeviceLocked) {
        _lastOverlayData = _settings.loadOverlayData();
      }
    });
  }

  void _loadCountryWordProfile() {
    setState(() {
      _countryWordProfile = _settings.countryWordProfile;
    });
  }

  Future<void> _showRegisterDialog() async {
    final TextEditingController emailController = TextEditingController(text: _profile?.email ?? '');
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController firstNameController = TextEditingController(text: _profile?.firstName ?? '');
    final TextEditingController lastNameController = TextEditingController(text: _profile?.lastName ?? '');
    final TextEditingController phoneController = TextEditingController(text: _profile?.phone ?? '');
    String selectedCountry = _profile?.country.isNotEmpty == true ? _profile!.country : 'SA';
    String selectedLanguage = _profile?.language.isNotEmpty == true ? _profile!.language : 'ar';

    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.registerTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: firstNameController, decoration: InputDecoration(labelText: context.l10n.firstNameLabel)),
                    TextField(controller: lastNameController, decoration: InputDecoration(labelText: context.l10n.lastNameLabel)),
                    TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.l10n.emailLabel)),
                    TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: context.l10n.passwordLabel)),
                    TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.l10n.phoneLabel)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCountry,
                      decoration: InputDecoration(labelText: context.l10n.countryProfileCountryLabel),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: 'SA', child: Text('Saudi Arabia')),
                        DropdownMenuItem<String>(value: 'EG', child: Text('Egypt')),
                        DropdownMenuItem<String>(value: 'AE', child: Text('UAE')),
                        DropdownMenuItem<String>(value: 'KW', child: Text('Kuwait')),
                        DropdownMenuItem<String>(value: 'QA', child: Text('Qatar')),
                        DropdownMenuItem<String>(value: 'BH', child: Text('Bahrain')),
                        DropdownMenuItem<String>(value: 'IQ', child: Text('Iraq')),
                        DropdownMenuItem<String>(value: 'LB', child: Text('Lebanon')),
                        DropdownMenuItem<String>(value: 'JO', child: Text('Jordan')),
                        DropdownMenuItem<String>(value: 'SY', child: Text('Syria')),
                        DropdownMenuItem<String>(value: 'SD', child: Text('Sudan')),
                        DropdownMenuItem<String>(value: 'TN', child: Text('Tunisia')),
                        DropdownMenuItem<String>(value: 'DZ', child: Text('Algeria')),
                        DropdownMenuItem<String>(value: 'MA', child: Text('Maroc')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedCountry = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLanguage,
                      decoration: InputDecoration(labelText: context.l10n.languageLabel),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: 'ar', child: Text('Arabic')),
                        DropdownMenuItem<String>(value: 'en', child: Text('English')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedLanguage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop('google'),
                      icon: const Icon(Icons.g_mobiledata),
                      label: Text(context.l10n.registerWithGoogle),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop('facebook'),
                      icon: const Icon(Icons.facebook),
                      label: Text(context.l10n.registerWithFacebook),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop('apple'),
                      icon: const Icon(Icons.apple),
                      label: Text(context.l10n.registerWithApple),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop('cancel'), child: Text(context.l10n.notNow)),
                FilledButton(onPressed: () => Navigator.of(context).pop('manual'), child: Text(context.l10n.registerButton)),
              ],
            );
          },
        );
      },
    );

    if (action == null || action == 'cancel') {
      return;
    }

    if (action == 'google' || action == 'facebook' || action == 'apple') {
      await _registerWithSocialProvider(
        action,
        country: selectedCountry,
        language: selectedLanguage,
      );
      return;
    }

    final LocalUserProfile draft = LocalUserProfile(
      email: emailController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      phone: phoneController.text.trim(),
      country: selectedCountry,
      language: selectedLanguage,
      isRegistered: false,
    );

    await _drupalSyncService.saveLocalProfile(draft);

    if (draft.email.isEmpty || passwordController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileSavedLocalOnly)));
      setState(() {
        _profile = draft;
      });
      return;
    }

    try {
      final LocalUserProfile registered = await _drupalSyncService.registerAndLinkDevice(
        profile: draft,
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _profile = registered;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.registerSuccess)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = draft;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.registerFailedLocalMode)));
    }
  }

  Future<void> _registerWithSocialProvider(
    String provider, {
    required String country,
    required String language,
  }) async {
    SocialAuthProfile? social;
    try {
      switch (provider) {
        case 'google':
          social = await _socialAuthService.signInWithGoogle();
          break;
        case 'facebook':
          social = await _socialAuthService.signInWithFacebook();
          break;
        case 'apple':
          social = await _socialAuthService.signInWithApple();
          break;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.socialSignInFailed)),
      );
      return;
    }

    if (social == null) {
      return;
    }

    if (social.email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.socialMissingEmail)),
      );
      return;
    }

    final LocalUserProfile draft = LocalUserProfile(
      email: social.email,
      firstName: social.firstName,
      lastName: social.lastName,
      phone: _profile?.phone ?? '',
      country: country,
      language: language,
      authProvider: social.provider,
      providerUserId: social.providerUserId,
      isRegistered: false,
    );

    await _drupalSyncService.saveLocalProfile(draft);

    try {
      final LocalUserProfile registered = await _drupalSyncService.registerAndLinkDeviceWithSocial(
        profile: draft,
        social: social,
      );
      if (!mounted) return;
      setState(() {
        _profile = registered;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.registerSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = draft;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.registerFailedLocalMode)),
      );
    }
  }

  Future<void> _submitDailyReport() async {
    await _refreshUsage();

    final String date = DateTime.now().toIso8601String().split('T').first;
    final DailyUsageReport report = DailyUsageReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      totalUsageMinutes: totalUsageMinutes,
      appUsage: usageDataMinutes,
      categoryUsage: <String, int>{
        'social_media': usageDataMinutes.values.fold<int>(0, (int acc, int v) => acc + v),
      },
      isSynced: false,
    );

    await _drupalSyncService.submitReport(report);
    await _drupalSyncService.syncPendingReports();
    _profile = await _drupalSyncService.getProfile();

    if (!mounted) return;
    final bool isRegistered = _profile?.isRegistered ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRegistered ? context.l10n.reportSubmittedOrQueued : context.l10n.reportSavedLocally),
      ),
    );
  }

  Future<void> _ensureCountryProfileSelected() async {
    if (_settings.selectedCountry == null) {
      await _settings.setSelectedCountry(
        CountryWordProfile.supportedCountries.first,
      );
    }
    _loadCountryWordProfile();
  }

  Future<void> _showCountryProfileDialog({bool isMandatory = false}) async {
    String selectedCountry = _settings.selectedCountry ?? CountryWordProfile.supportedCountries.first;

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(context.l10n.countryProfileTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.l10n.countryProfileHint),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCountry,
                    decoration: InputDecoration(
                      labelText: context.l10n.countryProfileCountryLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: CountryWordProfile.supportedCountries
                        .map(
                          (String country) => DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) async {
                      if (value == null) {
                        return;
                      }
                      setStateDialog(() {
                        selectedCountry = value;
                      });
                      await _settings.setSelectedCountry(value);
                      _loadCountryWordProfile();
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                if (!isMandatory)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.notNow),
                  ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selectedCountry),
                  child: Text(context.l10n.gotIt),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    await _settings.setSelectedCountry(result);
    _loadCountryWordProfile();

    if (!mounted || _countryWordProfile == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.countryProfileSaved(
            country: _countryWordProfile!.country,
            word: _countryWordProfile!.welcomeWord,
          ),
        ),
      ),
    );
  }

  /// Saves time limit and monitoring state to settings.
  Future<void> _saveSettings() async {
    await _settings.setTimeLimitMinutes(timeLimitMinutes);
    await _settings.setIsMonitoring(isMonitoring);
  }

  /// Shows an in-app dialog before navigating to system settings
  /// for overlay permissions.
  Future<void> _askPermissionBeforeSystemSettings() async {
    final bool alreadyGranted = await _overlayService.hasOverlayPermission();
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.notNow)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.l10n.continueLabel)),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      await _overlayService.ensurePermissions();
    }
  }

  Future<void> _runEssentialPermissionGuide() async {
    if (_essentialPermissionGuideInProgress ||
        _settings.essentialPermissionsPrompted) {
      return;
    }
    _essentialPermissionGuideInProgress = true;
    try {
      await _requestLocationForFirstRun();
      if (!mounted) return;
      await _requestUsageAccessForFirstRun();
      await _settings.setEssentialPermissionsPrompted();
    } finally {
      _essentialPermissionGuideInProgress = false;
    }
  }

  Future<void> _requestLocationForFirstRun() async {
    if (await _firstRunPermissions.hasLocationPermission() || !mounted) return;
    final bool? continueRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(LocaleController.instance.isArabic
            ? 'إذن الموقع لمواقيت الصلاة'
            : 'Location for prayer times'),
        content: Text(LocaleController.instance.isArabic
            ? 'يُستخدم موقع الجهاز لحساب مواقيت الصلاة بدقة. يمكنك تغيير الموقع أو طريقة الحساب لاحقًا من إعدادات الصلاة.'
            : 'Device location helps calculate prayer times accurately. You can change the location or calculation method later in Prayer settings.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.continueLabel),
          ),
        ],
      ),
    );
    if (continueRequest != true) return;

    final PermissionStatus status =
        await _firstRunPermissions.requestLocationPermission();
    if (status.isPermanentlyDenied && mounted) {
      final bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(LocaleController.instance.isArabic
              ? 'فعّل الموقع من الإعدادات'
              : 'Enable location in Settings'),
          content: Text(LocaleController.instance.isArabic
              ? 'بعد التفعيل استخدم زر الرجوع للعودة إلى عيالنا تلقائيًا.'
              : 'After enabling it, use Back to return to 3ialna automatically.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.notNow),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.continueLabel),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await _firstRunPermissions.openLocationSettings();
      }
    }
  }

  Future<void> _requestUsageAccessForFirstRun() async {
    if (await _firstRunPermissions.hasUsageAccess() || !mounted) return;
    final bool? openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.usageAccessTitle),
        content: Text(LocaleController.instance.isArabic
            ? 'يحتاج عيالنا إلى إذن بيانات الاستخدام لتطبيق الحدود الزمنية. ستفتح إعدادات Android؛ استخدم زر الرجوع للعودة إلى التطبيق.'
            : '3ialna needs Usage access to apply time limits. Android Settings will open; use Back to return to the app.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.continueLabel),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await _firstRunPermissions.openUsageAccessSettings();
    }
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
  Future<void> _checkAppUsage() async {
    final AppUsageSummary usageSummary = await _usageService.loadTodayUsageSummary();

    if (!mounted) {
      return;
    }

    setState(() {
      usageDataMinutes = usageSummary.perAppMinutes;
      totalUsageMinutes = usageSummary.totalMinutes;
    });

    // DON'T show overlay from Flutter side - let native service handle it
    // The native MonitorForegroundService has proper foreground app checks
  }

  /// Starts periodic monitoring every 30 seconds.
  void _startMonitoring() {
    monitoringTimer?.cancel();
    monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAppUsage();
      _checkPrayerLocks();
    });
  }

  /// Checks if we're in a prayer lock period and shows overlay if needed.
  Future<void> _checkPrayerLocks() async {
    if (_prayerSettings == null || !_prayerSettings!.enabled) {
      return;
    }

    if (_prayerSettings!.latitude == null || _prayerSettings!.longitude == null) {
      return;
    }

    final DateTime now = DateTime.now();
    final Map<Prayer, DateTime>? prayerTimes = _prayerTimeService.calculatePrayerTimes(now, _prayerSettings!);

    if (prayerTimes == null) {
      return;
    }

    // Check each prayer to see if we're in its lock period
    for (final MapEntry<Prayer, DateTime> entry in prayerTimes.entries) {
      final Prayer prayer = entry.key;
      final DateTime prayerTime = entry.value;
      final int lockDuration = _prayerSettings!.getLockDuration(prayer, prayerTime);
      final DateTime lockEndTime = prayerTime.add(Duration(minutes: lockDuration));

      // Check if current time is between prayer time and lock end time
      if (now.isAfter(prayerTime) && now.isBefore(lockEndTime)) {
        // DON'T show overlay from Flutter side - let native service handle it
        break; // Only one prayer can be active at a time
      }
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
    final int newLimit = (timeLimitMinutes + delta).clamp(5, 24 * 60);
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
      await _serviceChannel.invokeMethod('startMonitoringService');
    } catch (_) {
      // On non-Android platforms this will fail; we can safely ignore.
    }
  }

  /// Stops the native Android foreground service.
  Future<void> _stopBackgroundMonitoring() async {
    try {
      await _serviceChannel.invokeMethod('stopMonitoringService');
    } catch (_) {
      // Ignore errors on unsupported platforms.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          appBar: _buildAppBar(),
          floatingActionButton: FloatingActionButton(onPressed: _refreshUsage, child: const Icon(Icons.refresh)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_countryWordProfile != null) ...<Widget>[
                    _buildCountryWordCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildPrayerStatusCard(),
                  const SizedBox(height: 16),
                  _buildAccessibilityStatusCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildTimeLimitCard(),
                  const SizedBox(height: 16),
                  _buildMonitorToggle(),
                  const SizedBox(height: 16),
                  Expanded(child: isLoading ? const Center(child: CircularProgressIndicator()) : _buildUsageList(colorScheme)),
                ],
              ),
            ),
          ),
        ),
        if (_isDeviceLocked) _buildLockOverlay(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(context.l10n.appTitle),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.family_restroom),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
          },
          tooltip: 'Parental Controls',
        ),
        IconButton(
          icon: const Icon(Icons.app_registration),
          onPressed: _showRegisterDialog,
          tooltip: context.l10n.registerButton,
        ),
        IconButton(
          icon: const Icon(Icons.cloud_upload),
          onPressed: _submitDailyReport,
          tooltip: context.l10n.submitReportButton,
        ),
        IconButton(
          icon: const Icon(Icons.public),
          onPressed: () => _showCountryProfileDialog(),
          tooltip: context.l10n.countryProfileTitle,
        ),
        IconButton(icon: const Icon(Icons.settings), onPressed: _navigateToPrayerSettings, tooltip: 'Prayer Lock Settings'),
      ],
    );
  }

  Widget _buildCountryWordCard() {
    final CountryWordProfile profile = _countryWordProfile!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.countryProfileCardTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(profile.country)),
                Chip(label: Text(profile.welcomeWord)),
                Chip(label: Text(profile.childWord)),
                Chip(label: Text(profile.praiseWord)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOverlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final data = _lastOverlayData ?? _settings.loadOverlayData();

    return Container(
      color: Colors.black.withAlpha(230),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.error, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 64, color: colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Device Locked',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Time limit reached for:\n${data.appName}',
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Used: ${data.usedMinutes}m / Limit: ${data.limitMinutes}m',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onErrorContainer.withAlpha(200)),
                textAlign: TextAlign.center,
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _showUnlockPinAuth,
                    icon: const Icon(Icons.security),
                    label: const Text('Parent Unlock'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAdjustLimitPinAuth,
                    icon: const Icon(Icons.edit),
                    label: const Text('Adjust Limit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      foregroundColor: colorScheme.onErrorContainer,
                      side: BorderSide(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUnlockPinAuth() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinAuthScreen(
          onAuthenticated: () async {
            Navigator.of(context).pop();
            await _unlockDevice();
          },
        ),
      ),
    );
  }

  Future<void> _showAdjustLimitPinAuth() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinAuthScreen(
          onAuthenticated: () async {
            Navigator.of(context).pop();
            await _showAdjustLimitDialog();
          },
        ),
      ),
    );
  }

  Future<void> _showAdjustLimitDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Daily Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add more minutes to today\'s limit?'),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildAdjustOption(5), _buildAdjustOption(15), _buildAdjustOption(30)]),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
      ),
    );

    if (result != null) {
      await _adjustTimeLimit(result);
      await _unlockDevice();
    }
  }

  Widget _buildAdjustOption(int minutes) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(minutes),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text('+$minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        const Text('min', style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Future<void> _unlockDevice() async {
    final kioskService = KioskService();
    await kioskService.stopKioskMode();
    await _settings.setIsDeviceLocked(false);
    setState(() {
      _isDeviceLocked = false;
    });
  }

  Widget _buildTimeLimitCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.l10n.dailyTimeLimit, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$timeLimitMinutes '
                    '${context.l10n.minutesSuffix}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used today: $totalUsageMinutes '
                    '${context.l10n.minutesSuffix}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                IconButton(icon: const Icon(Icons.remove), onPressed: () => _adjustTimeLimit(-5)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => _adjustTimeLimit(5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorToggle() {
    final bool active = isMonitoring;
    final Color backgroundColor = active ? Colors.red : Colors.green;
    final IconData icon = active ? Icons.pause : Icons.play_arrow;
    final String label = active ? context.l10n.stopMonitoring : context.l10n.startMonitoring;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Icon(Icons.analytics_outlined, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(context.l10n.noUsageTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.l10n.noUsageSubtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    final List<MapEntry<String, int>> entries = usageDataMinutes.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, int> entry = entries[index];
        final String packageName = entry.key;
        final int usedMinutes = entry.value;
        final String appName = socialMediaApps[packageName] ?? packageName;
        final int safeTimeLimit = timeLimitMinutes <= 0 ? 1 : timeLimitMinutes;

        final double progress = (usedMinutes / safeTimeLimit).clamp(0, 2).toDouble();
        final bool overLimit = usedMinutes > timeLimitMinutes;

        final Color progressColor = overLimit ? Colors.red : Colors.blue;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(appName.isNotEmpty ? appName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text(appName, style: Theme.of(context).textTheme.titleMedium)),
                          if (overLimit) Icon(Icons.warning_amber, color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress > 1 ? 1 : progress,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$usedMinutes min / '
                        '$timeLimitMinutes min',
                        style: Theme.of(context).textTheme.bodySmall,
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
    final PrayerLockSettings? result = await Navigator.of(
      context,
    ).push<PrayerLockSettings>(MaterialPageRoute<PrayerLockSettings>(builder: (BuildContext context) => const PrayerLockSettingsScreen()));

    if (result != null) {
      await _settings.savePrayerLockSettings(result);
      _loadPrayerSettings();
    }
  }

  Widget _buildPrayerStatusCard() {
    if (_prayerSettings == null || !_prayerSettings!.enabled) {
      return const SizedBox.shrink();
    }

    final ({Prayer prayer, DateTime time})? nextPrayer = _prayerTimeService.getNextPrayer(_prayerSettings!);

    if (nextPrayer == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const Icon(Icons.location_off, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Location not set for prayer times', style: TextStyle(color: Colors.grey)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(Icons.access_time, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Next Prayer: ${nextPrayer.prayer.displayName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(timeString, style: Theme.of(context).textTheme.bodyMedium),
                  Text('At ${_formatTime(nextPrayer.time)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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

  Widget _buildAccessibilityStatusCard(ColorScheme colorScheme) {
    final bool isEnabled = _isAccessibilityEnabled;
    final Color statusColor = isEnabled ? Colors.green : Colors.orange;
    final IconData statusIcon = isEnabled ? Icons.check_circle : Icons.warning_amber;
    final String statusText = isEnabled ? 'App Blocking Enabled' : 'App Blocking Disabled';
    final String subtitleText = isEnabled ? 'Apps can be blocked when limits are exceeded' : 'Tap to enable Accessibility Service for app blocking';

    return Card(
      elevation: isEnabled ? 2 : 4,
      color: isEnabled ? null : colorScheme.errorContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEnabled ? BorderSide.none : BorderSide(color: colorScheme.error.withValues(alpha: 0.5), width: 2),
      ),
      child: InkWell(
        onTap: isEnabled
            ? null
            : () async {
                // Show prominent disclosure first
                await DisclosureDialog.show(
                  context: context,
                  title: 'Accessibility Service Required',
                  message:
                      'This app uses Accessibility Services to detect when a restricted app is in the foreground and block it if time limits are exceeded.\n\nThis service is required for the parental control features to work. We do not collect or transmit your personal data.',
                  icon: Icons.accessibility_new,
                  onAgree: () async {
                    await _accessibilityHelper.openAccessibilitySettings();
                    // Recheck status after a delay
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) {
                      final bool newStatus = await _accessibilityHelper.isAccessibilityServiceEnabled();
                      setState(() {
                        _isAccessibilityEnabled = newStatus;
                      });
                    }
                  },
                );
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(statusIcon, size: 32, color: statusColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      statusText,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isEnabled ? null : colorScheme.error),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitleText, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (!isEnabled) Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}
