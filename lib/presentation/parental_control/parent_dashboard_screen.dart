import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/parental_control_storage_service.dart';
import '../../data/local/settings_service.dart';
import '../../data/system/accessibility_service_helper.dart';
import '../../data/system/kiosk_service.dart';
import '../../data/system/pin_auth_service.dart';
import 'app_management_screen.dart';
import 'pin_auth_screen.dart';
import 'schedule_screen.dart';
import 'safe_content_screen.dart';

/// Main dashboard screen for parental controls.
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final KioskService _kioskService = KioskService();
  final ParentalControlStorageService _storage = ParentalControlStorageService();
  final PinAuthService _pinAuthService = PinAuthService();
  final AccessibilityServiceHelper _accessibilityHelper = AccessibilityServiceHelper();

  bool _isAuthenticated = false;
  bool _isDeviceAdminEnabled = false;
  bool _isKioskModeActive = false;
  bool _isAccessibilityServiceEnabled = false;
  bool _isStrictMode = false;
  late SettingsService _settings;
  int _blockedAppsCount = 0;
  int _appsWithTimeLimits = 0;

  bool get _isIos => Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadSettings();
  }

  Future<void> _checkAuthentication() async {
    final hasPin = await _pinAuthService.hasPin();
    if (!hasPin) {
      // No PIN set, navigate to setup
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PinAuthScreen(
              isSetupMode: true,
              onAuthenticated: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ParentDashboardScreen()));
              },
            ),
          ),
        );
      }
    } else {
      // PIN exists, require authentication
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PinAuthScreen(
              onAuthenticated: () {
                Navigator.of(context).pop();
                setState(() {
                  _isAuthenticated = true;
                });
                _loadSettings();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    if (!_isAuthenticated) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _settings = SettingsService(prefs);

    final isDeviceAdmin = await _kioskService.isDeviceAdminEnabled();
    final isKioskActive = await _kioskService.isKioskModeActive();
    final isAccessibilityEnabled = await _accessibilityHelper.isAccessibilityServiceEnabled();
    final blockedApps = await _storage.getBlockedApps();
    final timeLimits = await _storage.getTimeLimits();

    setState(() {
      _isDeviceAdminEnabled = isDeviceAdmin;
      _isKioskModeActive = isKioskActive;
      _isAccessibilityServiceEnabled = isAccessibilityEnabled;
      _isStrictMode = _settings.isStrictMode;
      _blockedAppsCount = blockedApps.length;
      _appsWithTimeLimits = timeLimits.length;
    });
  }

  Future<void> _toggleStrictMode(bool value) async {
    await _settings.setIsStrictMode(value);
    setState(() {
      _isStrictMode = value;
    });
  }

  Future<void> _toggleKioskMode() async {
    if (!_isDeviceAdminEnabled) {
      // Request device admin permission
      await _kioskService.requestDeviceAdmin();
      await _loadSettings();
      return;
    }

    if (_isKioskModeActive) {
      await _kioskService.stopKioskMode();
    } else {
      await _kioskService.startKioskMode();
    }
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Controls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show settings dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Settings'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Change PIN'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PinAuthScreen(
                                isSetupMode: true,
                                onAuthenticated: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.accessibility_new),
                        title: const Text('Accessibility Settings'),
                        subtitle: Text(_isAccessibilityServiceEnabled ? 'Enabled - App blocking is active' : 'Disabled - Enable for app blocking'),
                        trailing: Icon(
                          _isAccessibilityServiceEnabled ? Icons.check_circle : Icons.error_outline,
                          color: _isAccessibilityServiceEnabled ? Colors.green : Colors.orange,
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _accessibilityHelper.openAccessibilitySettings();
                          // Refresh status after returning
                          await Future.delayed(const Duration(seconds: 1));
                          await _loadSettings();
                        },
                      ),
                    ],
                  ),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kiosk Mode & Protection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Protection & Hard Lock', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Device Admin status: ${_isDeviceAdminEnabled ? "Enabled" : "Disabled"}', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Enabled device admin prevents the app from being uninstalled and allows Hard Locking.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_isIos) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'iOS limitation: Kiosk mode, accessibility-based blocking, and anti-uninstall protection are Android-only. '
                            'On iOS, use Screen Time / Family Controls for stronger enforcement.',
                          ),
                        ),
                      ] else if (!_isDeviceAdminEnabled)
                        FilledButton.icon(
                          onPressed: () async {
                            await _kioskService.requestDeviceAdmin();
                            await _loadSettings();
                          },
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Enable Anti-Uninstall Protection'),
                        )
                      else ...[
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Strict Mode (Hard Lock)'),
                          subtitle: const Text('Uses Kiosk Mode to make the lock screen impossible to bypass without a PIN.'),
                          value: _isStrictMode,
                          onChanged: _toggleStrictMode,
                          secondary: Icon(Icons.gpp_maybe, color: _isStrictMode ? Colors.red : Colors.grey),
                        ),
                        SwitchListTile(
                          title: const Text('Kiosk Mode (Manual Lock)'),
                          subtitle: const Text('Manually lock the entire device into this app right now.'),
                          value: _isKioskModeActive,
                          onChanged: (_) => _toggleKioskMode(),
                          secondary: const Icon(Icons.screen_lock_portrait),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Accessibility Service Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.accessibility_new, color: _isAccessibilityServiceEnabled ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Text('App Blocking Service', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            _isAccessibilityServiceEnabled ? Icons.check_circle : Icons.error_outline,
                            color: _isAccessibilityServiceEnabled ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAccessibilityServiceEnabled
                                  ? 'Accessibility Service is enabled. App blocking is active.'
                                  : 'Accessibility Service is disabled. Enable it to block apps when time limits are exceeded.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isIos
                            ? null
                            : () async {
                                await _accessibilityHelper.openAccessibilitySettings();
                                // Refresh status after returning
                                await Future.delayed(const Duration(seconds: 1));
                                await _loadSettings();
                              },
                        icon: const Icon(Icons.settings),
                        label: Text(
                          _isIos
                              ? 'Android-only feature'
                              : (_isAccessibilityServiceEnabled ? 'Open Accessibility Settings' : 'Enable Accessibility Service'),
                        ),
                        style: FilledButton.styleFrom(backgroundColor: _isAccessibilityServiceEnabled ? Colors.green : colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(icon: Icons.block, label: 'Blocked Apps', value: '$_blockedAppsCount', color: colorScheme.error),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(icon: Icons.timer, label: 'Time Limits', value: '$_appsWithTimeLimits', color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _ActionCard(
                    icon: Icons.apps,
                    label: 'Manage Apps',
                    color: colorScheme.primary,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AppManagementScreen()));
                    },
                  ),
                  _ActionCard(
                    icon: Icons.schedule,
                    label: 'Schedule',
                    color: colorScheme.secondary,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ScheduleScreen()));
                    },
                  ),
                  _ActionCard(
                    icon: Icons.shield_outlined,
                    label: 'Safe Content',
                    color: colorScheme.tertiary,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SafeContentScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
