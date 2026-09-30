import 'package:flutter/material.dart';
import '../../domain/models/schedule.dart';
import '../../data/local/parental_control_storage_service.dart';
import '../../l10n/app_localizations.dart';

/// Screen for managing schedule settings for app restrictions.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ParentalControlStorageService _storage =
      ParentalControlStorageService();

  Schedule _schedule = const Schedule(
    enabled: false,
    startTime: '09:00',
    endTime: '21:00',
    activeDays: [1, 2, 3, 4, 5, 6, 0],
  );
  bool _isLoading = true;

  final List<int> _dayValues = <int>[1, 2, 3, 4, 5, 6, 0];

  String _dayLabel(BuildContext context, int value) {
    final AppLocalizations l10n = context.l10n;
    return switch (value) {
      1 => l10n.dayMon,
      2 => l10n.dayTue,
      3 => l10n.dayWed,
      4 => l10n.dayThu,
      5 => l10n.dayFri,
      6 => l10n.daySat,
      _ => l10n.daySun,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final schedule = await _storage.getSchedule();
    setState(() {
      _schedule = schedule;
      _isLoading = false;
    });
  }

  Future<void> _saveSchedule() async {
    await _storage.setSchedule(_schedule);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.scheduleSaved),
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(isStart ? _schedule.startTime : _schedule.endTime),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _schedule = _schedule.copyWith(startTime: timeString);
        } else {
          _schedule = _schedule.copyWith(endTime: timeString);
        }
      });
      await _saveSchedule();
    }
  }

  Future<void> _selectWeekendTime(BuildContext context, bool isStart) async {
    final currentTime = isStart
        ? (_schedule.weekendStartTime ?? _schedule.startTime)
        : (_schedule.weekendEndTime ?? _schedule.endTime);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(currentTime),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _schedule = _schedule.copyWith(weekendStartTime: timeString);
        } else {
          _schedule = _schedule.copyWith(weekendEndTime: timeString);
        }
      });
      await _saveSchedule();
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 9, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _toggleDay(int day) {
    setState(() {
      final activeDays = List<int>.from(_schedule.activeDays);
      if (activeDays.contains(day)) {
        activeDays.remove(day);
      } else {
        activeDays.add(day);
        activeDays.sort();
      }
      _schedule = _schedule.copyWith(activeDays: activeDays);
    });
    _saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.scheduleSettings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable Switch
            Card(
              child: SwitchListTile(
                title: Text(context.l10n.enableSchedule),
                subtitle: Text(
                  context.l10n.scheduleEnableSubtitle,
                ),
                value: _schedule.enabled,
                onChanged: (value) {
                  setState(() {
                    _schedule = _schedule.copyWith(enabled: value);
                  });
                  _saveSchedule();
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_schedule.enabled) ...[
              // Active Days
              Text(
                context.l10n.activeDays,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dayValues.map((int day) {
                  final isActive = _schedule.activeDays.contains(day);
                  return FilterChip(
                    label: Text(_dayLabel(context, day)),
                    selected: isActive,
                    onSelected: (_) => _toggleDay(day),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Time Range
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.timeRange,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(context.l10n.startTime),
                        subtitle: Text(_schedule.startTime),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectTime(context, true),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text(context.l10n.endTime),
                        subtitle: Text(_schedule.endTime),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectTime(context, false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Different Weekend Rules
              Card(
                child: SwitchListTile(
                  title: Text(context.l10n.differentWeekendRules),
                  subtitle: Text(
                    context.l10n.weekendRulesSubtitle,
                  ),
                  value: _schedule.differentWeekendRules,
                  onChanged: (value) {
                    setState(() {
                      _schedule = _schedule.copyWith(
                        differentWeekendRules: value,
                      );
                    });
                    _saveSchedule();
                  },
                ),
              ),
              if (_schedule.differentWeekendRules) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.weekendTimeRange,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(context.l10n.startTime),
                          subtitle: Text(
                            _schedule.weekendStartTime ?? _schedule.startTime,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectWeekendTime(context, true),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(context.l10n.endTime),
                          subtitle: Text(
                            _schedule.weekendEndTime ?? _schedule.endTime,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectWeekendTime(context, false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Status Card
              Card(
                color: _schedule.isActiveNow()
                    ? colorScheme.errorContainer
                    : colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _schedule.isActiveNow()
                            ? Icons.lock
                            : Icons.lock_open,
                        color: _schedule.isActiveNow()
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _schedule.isActiveNow()
                                  ? context.l10n.restrictionsActive
                                  : context.l10n.restrictionsInactive,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _schedule.isActiveNow()
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _schedule.isActiveNow()
                                  ? context.l10n.restrictionsEnforced
                                  : context.l10n.restrictionsNotActive,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _schedule.isActiveNow()
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

