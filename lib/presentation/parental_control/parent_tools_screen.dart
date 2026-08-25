import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/local/device_pause_service.dart';
import '../../data/system/accessibility_service_helper.dart';
import '../../data/system/battery_optimization_service.dart';
import '../../data/system/kiosk_service.dart';
import '../../data/system/notification_service.dart';
import '../../data/system/first_run_permission_service.dart';
import '../../data/system/overlay_service.dart';
import '../../data/system/parent_voice_notification_service.dart';

class PauseControlScreen extends StatefulWidget {
  const PauseControlScreen({super.key, required this.childId, required this.childName});

  final String childId;
  final String childName;

  @override
  State<PauseControlScreen> createState() => _PauseControlScreenState();
}

class _PauseControlScreenState extends State<PauseControlScreen> {
  final DevicePauseService _pauseService = const DevicePauseService();
  DevicePauseState? _pause;
  int _minutes = 30;
  String _reason = 'family_time';

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  static const Map<String, List<String>> _reasons = <String, List<String>>{
    'family_time': <String>['وقت عائلي', 'Family time'],
    'prayer': <String>['وقت الصلاة', 'Prayer time'],
    'meal': <String>['وقت الطعام', 'Meal time'],
    'homework': <String>['الواجب المدرسي', 'Homework'],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final DevicePauseState? state = await _pauseService.loadActive();
    if (mounted) setState(() => _pause = state);
  }

  Future<void> _pauseNow() async {
    final DevicePauseState state = await _pauseService.pause(
      reason: _reason,
      minutes: _minutes,
      childId: widget.childId,
    );
    if (!mounted) return;
    setState(() => _pause = state);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_ar ? 'تم إيقاف قيود الطفل مؤقتًا.' : 'Child safeguards paused temporarily.')),
    );
  }

  Future<void> _resumeNow() async {
    await _pauseService.clear();
    if (!mounted) return;
    setState(() => _pause = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _pause?.isActive ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'إيقاف مؤقت' : 'Pause safeguards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(_ar ? 'الطفل الحالي: ${widget.childName}' : 'Current child: ${widget.childName}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_ar ? 'أوقف قيود الوقت والتطبيقات مؤقتًا لسبب واضح، ثم استأنفها يدويًا أو اتركها تعود بعد المدة.' : 'Temporarily pause time and app safeguards for a clear reason, then resume them manually or let them return after the duration.'),
                const SizedBox(height: 16),
                if (active) ...<Widget>[
                  ListTile(leading: const Icon(Icons.pause_circle_filled), title: Text(_ar ? 'الإيقاف نشط' : 'Pause is active'), subtitle: Text(_ar ? 'متبقٍ تقريبًا ${_pause!.remainingMinutes} دقيقة' : 'About ${_pause!.remainingMinutes} minutes remaining')), 
                  FilledButton.icon(onPressed: _resumeNow, icon: const Icon(Icons.play_arrow), label: Text(_ar ? 'استئناف الحماية الآن' : 'Resume safeguards now')),
                ] else ...<Widget>[
                  DropdownButtonFormField<String>(
                    value: _reason,
                    decoration: InputDecoration(labelText: _ar ? 'السبب' : 'Reason'),
                    items: _reasons.entries.map((MapEntry<String, List<String>> entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value[_ar ? 0 : 1]))).toList(),
                    onChanged: (String? value) => setState(() => _reason = value ?? _reason),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _minutes,
                    decoration: InputDecoration(labelText: _ar ? 'المدة' : 'Duration'),
                    items: <int>[15, 30, 60, 120].map((int value) => DropdownMenuItem<int>(value: value, child: Text(_ar ? '$value دقيقة' : '$value minutes'))).toList(),
                    onChanged: (int? value) => setState(() => _minutes = value ?? _minutes),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _pauseNow, icon: const Icon(Icons.pause), label: Text(_ar ? 'إيقاف الحماية مؤقتًا' : 'Pause safeguards'))),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(_ar ? 'لا يرسل هذا الإجراء بيانات إلى السحابة؛ الحالة محفوظة على الجهاز فقط.' : 'This action sends no data to the cloud; the state is stored on-device only.', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class ReliabilityCenterScreen extends StatefulWidget {
  const ReliabilityCenterScreen({super.key});

  @override
  State<ReliabilityCenterScreen> createState() => _ReliabilityCenterScreenState();
}

class _ReliabilityCenterScreenState extends State<ReliabilityCenterScreen> {
  final AccessibilityServiceHelper _accessibility = AccessibilityServiceHelper();
  final KioskService _kiosk = KioskService();
  final BatteryOptimizationService _battery = const BatteryOptimizationService();
  final NotificationService _notifications = NotificationService();
  final FirstRunPermissionService _firstRun = const FirstRunPermissionService();
  final OverlayService _overlay = const OverlayService();
  final ParentVoiceNotificationService _voice = ParentVoiceNotificationService();
  bool? _accessibilityEnabled;
  bool? _deviceAdminEnabled;
  bool? _batteryOptimized;
  bool? _notificationsEnabled;
  bool? _usageAccessEnabled;
  bool? _overlayEnabled;
  bool? _exactAlarmEnabled;
  bool? _locationEnabled;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool get _android => Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!_android) {
      if (mounted) setState(() {});
      return;
    }
    final List<bool> values = await Future.wait<bool>(<Future<bool>>[
      _accessibility.isAccessibilityServiceEnabled(),
      _kiosk.isDeviceAdminEnabled(),
      _battery.isIgnoringBatteryOptimizations(),
      _notifications.hasNotificationPermission(),
      _firstRun.hasUsageAccess(),
      _overlay.hasOverlayPermission(),
      _voice.canScheduleExactAlarms(),
      _firstRun.hasLocationPermission(),
    ]);
    if (!mounted) return;
    setState(() {
      _accessibilityEnabled = values[0];
      _deviceAdminEnabled = values[1];
      _batteryOptimized = values[2];
      _notificationsEnabled = values[3];
      _usageAccessEnabled = values[4];
      _overlayEnabled = values[5];
      _exactAlarmEnabled = values[6];
      _locationEnabled = values[7];
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_ReliabilityItem> items = _android
        ? <_ReliabilityItem>[
            _ReliabilityItem(_ar ? 'حظر التطبيقات' : 'App blocking', _accessibilityEnabled, _accessibility.openAccessibilitySettings),
            _ReliabilityItem(_ar ? 'الحماية من إزالة التطبيق' : 'Anti-uninstall protection', _deviceAdminEnabled, _kiosk.requestDeviceAdmin),
            _ReliabilityItem(_ar ? 'تحسين البطارية' : 'Battery optimization', _batteryOptimized, _battery.openSystemSettings),
            _ReliabilityItem(_ar ? 'الإشعارات' : 'Notifications', _notificationsEnabled, _notifications.requestNotificationPermission),
            _ReliabilityItem(_ar ? 'وصول الاستخدام' : 'Usage Access', _usageAccessEnabled, () async { await _firstRun.openUsageAccessSettings(); }),
            _ReliabilityItem(_ar ? 'إذن الظهور فوق التطبيقات' : 'Overlay permission', _overlayEnabled, _overlay.ensurePermissions),
            _ReliabilityItem(_ar ? 'المنبّهات الدقيقة' : 'Exact alarms', _exactAlarmEnabled, _voice.requestExactAlarmPermission),
            _ReliabilityItem(_ar ? 'الموقع لأوقات الصلاة' : 'Location for prayer times', _locationEnabled, () async { await _firstRun.requestLocationPermission(); }),
          ]
        : <_ReliabilityItem>[];
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'مركز الموثوقية' : 'Reliability Center')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(_ar ? 'راجع هذه الحالات بعد التثبيت أو عند ملاحظة أن الحماية لا تعمل كما توقعت.' : 'Review these statuses after installation or whenever protection does not behave as expected.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (!_android) Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(_ar ? 'حالة iOS' : 'iOS status'), subtitle: Text(_ar ? 'استخدم إعداد رقابة iOS لمراجعة Family Controls. بعض قدرات Android غير متاحة على iOS.' : 'Use iOS Controls Setup to review Family Controls. Some Android capabilities are not available on iOS.'))),
            for (final _ReliabilityItem item in items)
              Card(
                child: ListTile(
                  leading: Icon(item.enabled == true ? Icons.check_circle : Icons.error_outline, color: item.enabled == true ? Colors.green : Colors.orange),
                  title: Text(item.title),
                  subtitle: Text(item.enabled == true ? (_ar ? 'مفعّل' : 'Enabled') : (_ar ? 'يحتاج إلى مراجعة' : 'Needs review')),
                  trailing: item.enabled == true ? null : IconButton(icon: const Icon(Icons.open_in_new), onPressed: () async { await item.open(); await _refresh(); }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReliabilityItem {
  const _ReliabilityItem(this.title, this.enabled, this.open);

  final String title;
  final bool? enabled;
  final Future<void> Function() open;
}
