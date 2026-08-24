import 'package:flutter/material.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/settings_service.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/location_service.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import '../../domain/services/prayer_calculation_method_policy.dart';
import '../parental_control/voice_reminder_screens.dart';
import '../../data/system/parent_voice_notification_service.dart';
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

  PrayerLockSettings _settings = PrayerLockSettings.defaults();
  bool _isLoading = false;
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
                    Expanded(child: Text(_prayerName(prayer))),
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
            if (_settings.voiceNotificationsEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm_on_outlined),
                title: Text(_text('Enable on-time background reminders', 'تفعيل التذكيرات في وقتها بالخلفية')),
                subtitle: Text(_text('Required once so reminders can arrive when 3ialna is closed or the screen is locked.', 'مطلوب مرة واحدة لوصول التذكيرات عند إغلاق عيالنا أو قفل الشاشة.')),
                trailing: const Icon(Icons.open_in_new),
                onTap: _requestBackgroundPrayerVoiceAccess,
              ),
            const SizedBox(height: 8),
            Text(_text('The next seven days are scheduled locally and refreshed when 3ialna opens. Android uses an exact reminder alarm; iPhone uses a notification sound shorter than 29 seconds.', 'تُجدول الأيام السبعة القادمة محليًا وتُحدّث عند فتح عيالنا. يستخدم Android منبّهًا دقيقًا، ويستخدم iPhone صوت إشعار أقصر من 29 ثانية.'), style: const TextStyle(color: Colors.grey)),
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
