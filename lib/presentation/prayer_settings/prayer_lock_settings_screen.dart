import 'package:flutter/material.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/settings_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/location_service.dart';
import '../../data/system/prayer_time_service.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import '../../domain/services/prayer_calculation_method_policy.dart';
import '../parental_control/voice_reminder_screens.dart';
import '../../data/system/parent_voice_notification_service.dart';
import '../../data/system/battery_optimization_service.dart';
import '../../data/system/prayer_voice_reminder_verification.dart';
import '../widgets/disclosure_dialog.dart';

/// Screen for configuring prayer time lock settings.
class PrayerLockSettingsScreen extends StatefulWidget {
  const PrayerLockSettingsScreen({super.key});

  @override
  State<PrayerLockSettingsScreen> createState() => _PrayerLockSettingsScreenState();
}

class _PrayerLockSettingsScreenState extends State<PrayerLockSettingsScreen> {
  late SettingsService _settingsService;
  final LocationService _locationService = const LocationService();
  final PrayerTimeService _prayerTimeService = const PrayerTimeService();

  PrayerLockSettings _settings = PrayerLockSettings.defaults();
  Map<Prayer, DateTime> _prayerTimes = <Prayer, DateTime>{};
  bool _isLoading = false;
  bool _isSchedulingVoiceReminderTest = false;
  bool _isSchedulingAzanTest = false;
  String? _locationError;
  Future<void>? _pendingMethodWrite;

  bool get _isArabic => LocaleController.instance.isArabic;

  String _text(String english, String arabic) => _isArabic ? arabic : english;

  String _prayerName(Prayer prayer) {
    if (!_isArabic) return prayer.displayName;
    return switch (prayer) {
      Prayer.fajr => 'الفجر',
      Prayer.dhuhr => 'الظهر',
      Prayer.asr => 'العصر',
      Prayer.maghrib => 'المغرب',
      Prayer.isha => 'العشاء',
    };
  }

  String _formatPrayerTime(DateTime? time) {
    if (time == null) return _text('Time unavailable', 'الوقت غير متاح');
    final DateTime local = time.toLocal();
    final int hour = local.hour;
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String period = _isArabic
        ? (hour >= 12 ? 'م' : 'ص')
        : (hour >= 12 ? 'PM' : 'AM');
    return '$displayHour:${local.minute.toString().padLeft(2, '0')} $period';
  }

  void _refreshPrayerTimes() {
    final Map<Prayer, DateTime>? calculated =
        _prayerTimeService.calculatePrayerTimes(DateTime.now(), _settings);
    if (!mounted) return;
    setState(() {
      _prayerTimes = calculated ?? <Prayer, DateTime>{};
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _settingsService = SettingsService(prefs);

    setState(() {
      _settings = _settingsService.loadPrayerLockSettings();
    });
    _refreshPrayerTimes();

    // Load location if not set, then use it for the automatic method default.
    if (_settings.latitude == null || _settings.longitude == null) {
      await _refreshLocation();
    } else if (!_settingsService.isPrayerCalculationMethodManuallySelected) {
      _applyLocationDefault(latitude: _settings.latitude!, longitude: _settings.longitude!);
    }
  }

  void _applyLocationDefault({required double latitude, required double longitude}) {
    if (_settingsService.isPrayerCalculationMethodManuallySelected) return;
    final String method = PrayerCalculationMethodPolicy.forLocation(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    setState(() {
      _settings = _settings.copyWith(calculationMethodName: method);
    });
    _refreshPrayerTimes();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    // Check permission first
    final bool hasPermission = await _locationService.hasLocationPermission();

    if (!hasPermission) {
      if (!mounted) return;

      // Show prominent disclosure
      final bool agreed = await DisclosureDialog.show(
        context: context,
        title: _text('Location Access Required', 'مطلوب إذن الموقع'),
        message:
            _text(
              'This app collects location data to calculate accurate prayer times for your specific area, enabling the automated prayer lock feature.\n\nLocation data is calculated locally and is not shared with third parties.',
              'يُستخدم الموقع لحساب مواقيت الصلاة بدقة لمنطقتك وتشغيل القفل التلقائي أثناء الصلاة.\n\nتُعالج بيانات الموقع محليًا ولا تُشارك مع جهات خارجية.',
            ),
        icon: Icons.location_on,
        onAgree: () {}, // The actual request happens in getCoordinates
      );

      if (!agreed) {
        setState(() {
          _locationError = _text('Location permission is required for prayer times.', 'إذن الموقع مطلوب لحساب مواقيت الصلاة.');
          _isLoading = false;
        });
        return;
      }
    }

    final ({double latitude, double longitude})? coords = await _locationService.getCoordinates();

    if (coords != null) {
      setState(() {
        _settings = _settings.copyWith(latitude: coords.latitude, longitude: coords.longitude);
        _isLoading = false;
      });
      _applyLocationDefault(latitude: coords.latitude, longitude: coords.longitude);
      _refreshPrayerTimes();
    } else {
      setState(() {
        _locationError =
            _text(
              'Failed to get location. Please check location permissions.',
              'تعذر الحصول على الموقع. تحقق من أذونات الموقع.',
            );
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await _pendingMethodWrite;
    await _settingsService.savePrayerLockSettings(_settings);
    if (mounted) {
      Navigator.of(context).pop(_settings);
    }
  }

  Future<void> _requestBackgroundPrayerVoiceAccess() async {
    final ParentVoiceNotificationService voiceService =
        ParentVoiceNotificationService(
      recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
    );
    if (Platform.isAndroid) {
      final bool allowed = await voiceService.canScheduleExactAlarms();
      if (!allowed) {
        await voiceService.requestExactAlarmPermission();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_text(
                'Allow Alarms & reminders, then return to 3ialna so prayer voice reminders can run on time while the phone is locked.',
                'اسمح بخيار المنبّهات والتذكيرات ثم عُد إلى عيالنا لتعمل تذكيرات الصلاة الصوتية في وقتها حتى عند قفل الهاتف.',
              )),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              'Alarms & reminders is ready. Record a note, then run the one-minute test below.',
              'خيار المنبّهات والتذكيرات جاهز. سجّل ملاحظة ثم شغّل اختبار الدقيقة الواحدة أدناه.',
            )),
          ),
        );
      }
    } else if (Platform.isIOS) {
      final bool granted = await voiceService.requestVoiceNotificationPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              'Allow notifications in iPhone Settings so the scheduled prayer sound can play while 3ialna is closed.',
              'اسمح بالإشعارات في إعدادات iPhone ليعمل صوت تذكير الصلاة المجدول حتى عند إغلاق عيالنا.',
            )),
          ),
        );
      }
    }
    await voiceService.dispose();
  }

  Future<void> _scheduleVoiceReminderVerification() async {
    if (!_settings.voiceNotificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(
            'Enable prayer voice notifications before running the test.',
            'فعّل إشعارات صوت تذكير الصلاة قبل تشغيل الاختبار.',
          )),
        ),
      );
      return;
    }

    setState(() => _isSchedulingVoiceReminderTest = true);
    final ParentVoiceNotificationService voiceService =
        ParentVoiceNotificationService(
      recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
    );
    try {
      final bool hasRecording = await voiceService.getRecording() != null;
      bool platformPermissionGranted = true;
      if (Platform.isAndroid) {
        platformPermissionGranted = await voiceService.canScheduleExactAlarms();
      } else if (Platform.isIOS) {
        platformPermissionGranted =
            await voiceService.requestVoiceNotificationPermission();
      }

      if (!PrayerVoiceReminderVerification.canSchedule(
        hasRecording: hasRecording,
        platformPermissionGranted: platformPermissionGranted,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              hasRecording
                  ? 'Allow the required reminder permission, then try the test again.'
                  : 'Record a prayer reminder voice note before running the test.',
              hasRecording
                  ? 'اسمح بإذن التذكير المطلوب ثم أعد الاختبار.'
                  : 'سجّل ملاحظة صوتية لتذكير الصلاة قبل تشغيل الاختبار.',
            )),
          ),
        );
        return;
      }

      final DateTime scheduledAt =
          PrayerVoiceReminderVerification.scheduledAt(DateTime.now());
      final bool scheduled =
          await voiceService.scheduleBackgroundPlayback(scheduledAt);
      if (!mounted) return;
      if (!scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              '3ialna could not schedule the test. Review reminder permissions and try again.',
              'تعذر على عيالنا جدولة الاختبار. راجع أذونات التذكير ثم حاول مرة أخرى.',
            )),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(_text('One-minute test scheduled', 'تمت جدولة اختبار الدقيقة الواحدة')),
          content: Text(_text(
            'Lock the phone now. Keep 3ialna closed if you wish. The local prayer voice reminder should play in about one minute.',
            'اقفل الهاتف الآن. يمكنك إبقاء عيالنا مغلقًا. ينبغي أن يعمل صوت تذكير الصلاة المحلي خلال نحو دقيقة واحدة.',
          )),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_text('Done', 'حسنًا')),
            ),
          ],
        ),
      );
    } finally {
      await voiceService.dispose();
      if (mounted) setState(() => _isSchedulingVoiceReminderTest = false);
    }
  }

  Future<void> _scheduleAutomaticAzanVerification() async {
    if (!_settings.automaticAzanEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(
            'Enable automatic Azan before running the test.',
            'فعّل الأذان التلقائي قبل تشغيل الاختبار.',
          )),
        ),
      );
      return;
    }

    setState(() => _isSchedulingAzanTest = true);
    final ParentVoiceNotificationService voiceService =
        ParentVoiceNotificationService(
      recordingKey: ParentVoiceNotificationService.prayerAzanRecordingKey,
    );
    try {
      final bool hasRecording = await voiceService.getRecording() != null;
      bool platformPermissionGranted = true;
      if (Platform.isAndroid) {
        platformPermissionGranted = await voiceService.canScheduleExactAlarms();
      } else if (Platform.isIOS) {
        platformPermissionGranted =
            await voiceService.requestVoiceNotificationPermission();
      }

      if (!PrayerVoiceReminderVerification.canSchedule(
        hasRecording: hasRecording,
        platformPermissionGranted: platformPermissionGranted,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              hasRecording
                  ? 'Allow the required reminder permission, then try the Azan test again.'
                  : 'Record a short local Azan before running the test.',
              hasRecording
                  ? 'اسمح بإذن التذكير المطلوب ثم أعد اختبار الأذان.'
                  : 'سجّل أذانًا محليًا قصيرًا قبل تشغيل الاختبار.',
            )),
          ),
        );
        return;
      }

      final bool scheduled = await voiceService.scheduleBackgroundPlayback(
        PrayerVoiceReminderVerification.scheduledAt(DateTime.now()),
      );
      if (!mounted) return;
      if (!scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_text(
              '3ialna could not schedule the Azan test. Review reminder permissions and try again.',
              'تعذر على عيالنا جدولة اختبار الأذان. راجع أذونات التذكير ثم حاول مرة أخرى.',
            )),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(_text('One-minute Azan test scheduled', 'تمت جدولة اختبار الأذان لمدة دقيقة واحدة')),
          content: Text(_text(
            'Lock the phone now. The local Azan recording should play in about one minute without keeping 3ialna open.',
            'اقفل الهاتف الآن. ينبغي أن يعمل تسجيل الأذان المحلي خلال نحو دقيقة واحدة دون إبقاء عيالنا مفتوحًا.',
          )),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_text('Done', 'حسنًا')),
            ),
          ],
        ),
      );
    } finally {
      await voiceService.dispose();
      if (mounted) setState(() => _isSchedulingAzanTest = false);
    }
  }

  Future<void> _reviewBatteryOptimization() async {
    const BatteryOptimizationService batteryOptimizationService =
        BatteryOptimizationService();
    final bool alreadyExempt =
        await batteryOptimizationService.isIgnoringBatteryOptimizations();
    if (!alreadyExempt) {
      await batteryOptimizationService.openSystemSettings();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text(
            '3ialna is already exempt from battery optimization on this device.',
            'عيالنا مُستثنى بالفعل من تحسين البطارية على هذا الجهاز.',
          )),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_text('Prayer Lock Settings', 'إعدادات قفل الصلاة')),
        actions: <Widget>[TextButton(onPressed: _saveSettings, child: Text(_text('Save', 'حفظ')))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildEnableToggle(),
            const SizedBox(height: 24),
            _buildLocationSection(),
            const SizedBox(height: 24),
            _buildCalculationMethodSection(),
            const SizedBox(height: 24),
            _buildLockDurationsSection(),
            const SizedBox(height: 24),
            _buildFridayDhuhrSection(),
            const SizedBox(height: 24),
            _buildNotificationMessagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Card(
      child: SwitchListTile(
        title: Text(_text('Enable Prayer Locks', 'تفعيل أقفال الصلاة')),
        subtitle: Text(_text('Lock your device during prayer times', 'قفل الجهاز خلال أوقات الصلاة')),
        value: _settings.enabled,
        onChanged: (bool value) {
          setState(() {
            _settings = _settings.copyWith(enabled: value);
          });
        },
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_text('Location', 'الموقع'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_settings.latitude != null && _settings.longitude != null)
              Text(
                _text(
                  'Lat: ${_settings.latitude!.toStringAsFixed(4)}, Lng: ${_settings.longitude!.toStringAsFixed(4)}',
                  'خط العرض: ${_settings.latitude!.toStringAsFixed(4)}، خط الطول: ${_settings.longitude!.toStringAsFixed(4)}',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(_text('Location not set', 'لم يتم تحديد الموقع'), style: const TextStyle(color: Colors.grey)),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_locationError!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _refreshLocation,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(_text('Refresh Location', 'تحديث الموقع')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setManualCalculationMethod(String methodName) async {
    await _settingsService.setPrayerCalculationMethodOverride(methodName);
    if (!mounted) return;
    setState(() {
      _settings = _settings.copyWith(calculationMethodName: methodName);
    });
    _refreshPrayerTimes();
  }

  Widget _buildCalculationMethodSection() {
    final List<({String name, String methodName})> methods = [
      (name: _text('Muslim World League', 'رابطة العالم الإسلامي'), methodName: 'muslim_world_league'),
      (name: _text('Egyptian General Authority', 'الهيئة المصرية العامة للمساحة'), methodName: 'egyptian'),
      (name: _text('University of Karachi', 'جامعة كراتشي'), methodName: 'karachi'),
      (name: _text('Umm al-Qura, Makkah', 'أم القرى، مكة'), methodName: 'makkah'),
      (name: _text('Islamic Society of North America', 'الجمعية الإسلامية لأمريكا الشمالية'), methodName: 'isna'),
    ];

    // Find the currently selected method
    String selectedName = methods.first.name;
    for (final method in methods) {
      if (method.methodName == _settings.calculationMethodName) {
        selectedName = method.name;
        break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_text('Calculation Method', 'طريقة الحساب'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedName,
              decoration: InputDecoration(border: const OutlineInputBorder(), labelText: _text('Method', 'الطريقة')),
              items: methods
                  .map((({String name, String methodName}) method) => DropdownMenuItem<String>(value: method.name, child: Text(method.name)))
                  .toList(),
              onChanged: (String? value) async {
                if (value != null) {
                  for (final method in methods) {
                    if (method.name == value) {
                      _pendingMethodWrite = _setManualCalculationMethod(method.methodName);
                      await _pendingMethodWrite;
                      break;
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockDurationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_text('Lock Durations (minutes)', 'مدد القفل (بالدقائق)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...Prayer.values.map(
              (Prayer prayer) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_prayerName(prayer)),
                          const SizedBox(height: 4),
                          Text(
                            _formatPrayerTime(_prayerTimes[prayer]),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        controller: TextEditingController(text: (_settings.lockDurations[prayer] ?? PrayerLockSettings.defaultLockDurationMinutes).toString())
                          ..selection = TextSelection.fromPosition(TextPosition(offset: (_settings.lockDurations[prayer] ?? PrayerLockSettings.defaultLockDurationMinutes).toString().length)),
                        onChanged: (String value) {
                          final int? duration = int.tryParse(value);
                          if (duration != null && duration > 0) {
                            setState(() {
                              final Map<Prayer, int> newDurations = Map<Prayer, int>.from(_settings.lockDurations);
                              newDurations[prayer] = duration;
                              _settings = _settings.copyWith(lockDurations: newDurations);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFridayDhuhrSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_text('Friday Dhuhr Duration', 'مدة قفل ظهر الجمعة'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_text('Special lock duration for Friday Dhuhr prayer', 'مدة قفل خاصة لصلاة ظهر يوم الجمعة'), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: const OutlineInputBorder(), labelText: _text('Minutes', 'دقائق')),
                controller: TextEditingController(text: _settings.fridayDhuhrDuration.toString())
                  ..selection = TextSelection.fromPosition(TextPosition(offset: _settings.fridayDhuhrDuration.toString().length)),
                onChanged: (String value) {
                  final int? duration = int.tryParse(value);
                  if (duration != null && duration > 0) {
                    setState(() {
                      _settings = _settings.copyWith(fridayDhuhrDuration: duration);
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationMessagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_text('Notification Messages', 'رسائل الإشعارات'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_text('Voice notifications', 'إشعارات صوت الوالدين')),
              subtitle: Text(_text('Schedule the local parent voice two minutes before each prayer, including while the phone is locked.', 'جدولة صوت الوالدين المحلي قبل كل صلاة بدقيقتين، حتى عند قفل الهاتف.')),
              value: _settings.voiceNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _settings = _settings.copyWith(voiceNotificationsEnabled: value);
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_text('Automatic Azan at prayer time', 'أذان تلقائي عند دخول وقت الصلاة')),
              subtitle: Text(_text('Use a separate local recording at the calculated start of each prayer. This optional setting does not replace the two-minute parent reminder.', 'استخدم تسجيلًا محليًا منفصلًا عند بداية وقت كل صلاة المحسوب. هذا الخيار لا يستبدل تذكير الوالد قبل الصلاة بدقيقتين.')),
              value: _settings.automaticAzanEnabled,
              onChanged: (bool value) {
                setState(() {
                  _settings = _settings.copyWith(automaticAzanEnabled: value);
                });
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mic_none_outlined),
              title: Text(_text('Prayer reminder voice note', 'ملاحظة صوتية لتذكير الصلاة')),
              subtitle: Text(_text('Recorded locally. Android can play it from a scheduled reminder; iPhone delivers it as a notification sound.', 'تُسجل محليًا. يمكن لـ Android تشغيلها من التذكير المجدول، ويقدّمها iPhone كصوت إشعار.')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VoiceReminderRecordingScreen(
                      recordingKey: ParentVoiceNotificationService.prayerReminderRecordingKey,
                      title: _text('Prayer reminder voice', 'صوت تذكير الصلاة'),
                      description: _text('Record a parent voice note for the child to hear after opening a prayer reminder.', 'سجّل ملاحظة بصوت الوالدين ليستمع إليها الطفل بعد فتح تذكير الصلاة.'),
                    ),
                  ),
                );
              },
            ),
            if (_settings.automaticAzanEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.volume_up_outlined),
                title: Text(_text('Automatic Azan recording', 'تسجيل الأذان التلقائي')),
                subtitle: Text(_text('Record a short Azan locally. Android plays it at the prayer start; iPhone delivers it as a notification sound shorter than 29 seconds.', 'سجّل أذانًا قصيرًا محليًا. يشغّله Android عند دخول وقت الصلاة، ويقدّمه iPhone كصوت إشعار أقصر من 29 ثانية.')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VoiceReminderRecordingScreen(
                        recordingKey: ParentVoiceNotificationService.prayerAzanRecordingKey,
                        title: _text('Automatic Azan recording', 'تسجيل الأذان التلقائي'),
                        description: _text('Record a short local Azan. When enabled, it is scheduled at the calculated start of every prayer.', 'سجّل أذانًا محليًا قصيرًا. عند تفعيله، يُجدول عند بداية وقت كل صلاة.'),
                      ),
                    ),
                  );
                },
              ),
            if (_settings.voiceNotificationsEnabled || _settings.automaticAzanEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm_on_outlined),
                title: Text(_text('Enable on-time background reminders', 'تفعيل التذكيرات في وقتها بالخلفية')),
                subtitle: Text(_text('Step 1: required once so reminders can arrive when 3ialna is closed or the screen is locked.', 'الخطوة 1: مطلوب مرة واحدة لوصول التذكيرات عند إغلاق عيالنا أو قفل الشاشة.')),
                trailing: const Icon(Icons.open_in_new),
                onTap: _requestBackgroundPrayerVoiceAccess,
              ),
            if ((_settings.voiceNotificationsEnabled || _settings.automaticAzanEnabled) && Platform.isAndroid)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.battery_saver_outlined),
                title: Text(_text(
                  'Review battery optimization (optional)',
                  'مراجعة تحسين البطارية (اختياري)',
                )),
                subtitle: Text(_text(
                  'Step 2 (optional): exact alarms already work through Android Doze. Open the system list only if this phone delays reminders; 3ialna never requests automatic whitelisting.',
                  'الخطوة 2 (اختيارية): تعمل المنبهات الدقيقة خلال وضع السكون في Android. افتح قائمة النظام فقط إذا كان الهاتف يؤخر التذكيرات؛ لا يطلب عيالنا إضافة تلقائية إلى القائمة البيضاء.',
                )),
                trailing: const Icon(Icons.open_in_new),
                onTap: _reviewBatteryOptimization,
              ),
            if (_settings.voiceNotificationsEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _isSchedulingVoiceReminderTest
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                title: Text(_text(
                  'Test a one-minute locked-device reminder',
                  'اختبر تذكيرًا لمدة دقيقة واحدة عند قفل الجهاز',
                )),
                subtitle: Text(_text(
                  'Step 3: schedule a safe local test, lock the phone, and confirm the reminder arrives without keeping 3ialna open.',
                  'الخطوة 3: جدولة اختبار محلي آمن، ثم اقفل الهاتف وتأكد من وصول التذكير دون إبقاء عيالنا مفتوحًا.',
                )),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: _isSchedulingVoiceReminderTest
                    ? null
                    : _scheduleVoiceReminderVerification,
              ),
            if (_settings.automaticAzanEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _isSchedulingAzanTest
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_up_outlined),
                title: Text(_text('Test a one-minute automatic Azan', 'اختبر أذانًا تلقائيًا لمدة دقيقة واحدة')),
                subtitle: Text(_text('Schedule a safe local Azan test, lock the phone, and confirm it plays without keeping 3ialna open.', 'جدولة اختبار أذان محلي آمن، ثم اقفل الهاتف وتأكد من تشغيله دون إبقاء عيالنا مفتوحًا.')),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: _isSchedulingAzanTest
                    ? null
                    : _scheduleAutomaticAzanVerification,
              ),
            const SizedBox(height: 8),
            Text(_text('The next seven days are scheduled locally and refreshed when 3ialna opens. Android uses an exact reminder alarm; iPhone uses notification sounds shorter than 29 seconds. When both prayer audio options are enabled on iPhone, 30 events each are scheduled to stay within the system pending-notification limit.', 'تُجدول الأيام السبعة القادمة محليًا وتُحدّث عند فتح عيالنا. يستخدم Android منبّهًا دقيقًا، ويستخدم iPhone أصوات إشعار أقصر من 29 ثانية. عند تفعيل خياري صوت الصلاة معًا على iPhone، يُجدول 30 موعدًا لكل منهما للبقاء ضمن حد الإشعارات المعلّقة في النظام.'), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...Prayer.values.map(
              (Prayer prayer) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_prayerName(prayer), style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(border: const OutlineInputBorder(), hintText: _text('Enter notification message', 'اكتب رسالة الإشعار')),
                      maxLines: 2,
                      controller: TextEditingController(text: _settings.notificationMessages[prayer] ?? '')
                        ..selection = TextSelection.fromPosition(TextPosition(offset: (_settings.notificationMessages[prayer] ?? '').length)),
                      onChanged: (String value) {
                        setState(() {
                          final Map<Prayer, String> newMessages = Map<Prayer, String>.from(_settings.notificationMessages);
                          newMessages[prayer] = value;
                          _settings = _settings.copyWith(notificationMessages: newMessages);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
