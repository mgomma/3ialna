import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/task_voice_reminder.dart';

/// Persists parent-created task reminders separately from child profiles and
/// shareable configuration packs. Labels and recording references never leave
/// the device through this store.
class TaskVoiceReminderService {
  const TaskVoiceReminderService(this._preferences);

  static const String preferencesKey = 'local_parent_task_voice_reminders_v1';
  static const int maximumReminderSlots = 5;

  final SharedPreferences _preferences;

  List<TaskVoiceReminder> load() {
    final String? raw = _preferences.getString(preferencesKey);
    if (raw == null) return const <TaskVoiceReminder>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskVoiceReminder.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <TaskVoiceReminder>[];
    }
  }

  Future<void> save(List<TaskVoiceReminder> reminders) {
    return _preferences.setString(
      preferencesKey,
      jsonEncode(reminders.map((TaskVoiceReminder item) => item.toJson()).toList(growable: false)),
    );
  }

  TaskVoiceReminder createDraft() {
    final Set<int> usedSlots = load().map((TaskVoiceReminder item) => item.notificationSlot).toSet();
    final int slot = List<int>.generate(maximumReminderSlots, (int index) => index)
        .firstWhere((int candidate) => !usedSlots.contains(candidate), orElse: () => -1);
    if (slot < 0) {
      throw StateError('The local reminder limit has been reached.');
    }
    final String id = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    return TaskVoiceReminder(
      id: id,
      notificationSlot: slot,
      label: '',
      repeatHours: 1,
      enabled: false,
      hasVoiceNote: false,
    );
  }
}
