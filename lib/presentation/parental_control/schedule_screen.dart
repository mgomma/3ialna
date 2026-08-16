import 'package:flutter/material.dart';
import '../../domain/models/schedule.dart';
import '../../data/local/parental_control_storage_service.dart';

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

  final List<Map<String, dynamic>> _days = [
    {'value': 1, 'label': 'Mon'},
    {'value': 2, 'label': 'Tue'},
    {'value': 3, 'label': 'Wed'},
    {'value': 4, 'label': 'Thu'},
    {'value': 5, 'label': 'Fri'},
    {'value': 6, 'label': 'Sat'},
    {'value': 0, 'label': 'Sun'},
  ];

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
        const SnackBar(
          content: Text('Schedule saved successfully'),
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
        title: const Text('Schedule Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable Switch
            Card(
              child: SwitchListTile(
                title: const Text('Enable Schedule'),
                subtitle: const Text(
                  'Restrictions will only apply during scheduled hours',
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
                'Active Days',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((day) {
                  final isActive = _schedule.activeDays.contains(day['value']);
                  return FilterChip(
                    label: Text(day['label'] as String),
                    selected: isActive,
                    onSelected: (_) => _toggleDay(day['value'] as int),
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
                        'Time Range',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Start Time'),
                        subtitle: Text(_schedule.startTime),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectTime(context, true),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('End Time'),
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
                  title: const Text('Different Weekend Rules'),
                  subtitle: const Text(
                    'Use different time restrictions for weekends',
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
                          'Weekend Time Range',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('Start Time'),
                          subtitle: Text(
                            _schedule.weekendStartTime ?? _schedule.startTime,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectWeekendTime(context, true),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('End Time'),
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
                                  ? 'Restrictions Active'
                                  : 'Restrictions Inactive',
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
                                  ? 'App restrictions are currently enforced'
                                  : 'App restrictions are not active',
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

