import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/settings_service.dart';
import '../../data/system/location_service.dart';
import '../../domain/models/prayer.dart';
import '../../domain/models/prayer_lock_settings.dart';
import '../../domain/services/prayer_calculation_method_policy.dart';
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
        title: 'Location Access Required',
        message:
            'This app collects location data to calculate accurate prayer times for your specific area, enabling the automated prayer lock feature.\n\nLocation data is calculated locally and is not shared with third parties.',
        icon: Icons.location_on,
        onAgree: () {}, // The actual request happens in getCoordinates
      );

      if (!agreed) {
        setState(() {
          _locationError = 'Location permission is required for prayer times.';
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
            'Failed to get location. '
            'Please check location permissions.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Lock Settings'),
        actions: <Widget>[TextButton(onPressed: _saveSettings, child: const Text('Save'))],
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
        title: const Text('Enable Prayer Locks'),
        subtitle: const Text('Lock your device during prayer times'),
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
            const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_settings.latitude != null && _settings.longitude != null)
              Text(
                'Lat: ${_settings.latitude!.toStringAsFixed(4)}, '
                'Lng: ${_settings.longitude!.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              const Text('Location not set', style: TextStyle(color: Colors.grey)),
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
                label: const Text('Refresh Location'),
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
      (name: 'Muslim World League', methodName: 'muslim_world_league'),
      (name: 'Egyptian General Authority', methodName: 'egyptian'),
      (name: 'University of Karachi', methodName: 'karachi'),
      (name: 'Umm al-Qura, Makkah', methodName: 'makkah'),
      (name: 'Islamic Society of North America', methodName: 'isna'),
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
            const Text('Calculation Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedName,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Method'),
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
            const Text('Lock Durations (minutes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...Prayer.values.map(
              (Prayer prayer) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(prayer.displayName)),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        controller: TextEditingController(text: (_settings.lockDurations[prayer] ?? 30).toString())
                          ..selection = TextSelection.fromPosition(TextPosition(offset: (_settings.lockDurations[prayer] ?? 30).toString().length)),
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
            const Text('Friday Dhuhr Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Special lock duration for Friday Dhuhr prayer', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Minutes'),
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
            const Text('Notification Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Voice notifications'),
              subtitle: const Text('Speak the same written message when the prayer lock begins'),
              value: _settings.voiceNotificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _settings = _settings.copyWith(voiceNotificationsEnabled: value);
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('Custom messages shown 2 minutes before each prayer and spoken when the lock begins', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...Prayer.values.map(
              (Prayer prayer) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(prayer.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter notification message'),
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
