import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/task_voice_reminder_service.dart';
import 'package:mu_super_app/data/system/notification_service.dart';
import 'package:mu_super_app/domain/models/task_voice_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists task reminders locally with only supported repeat intervals', () async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TaskVoiceReminderService service = TaskVoiceReminderService(preferences);
    final TaskVoiceReminder draft = service.createDraft();
    final TaskVoiceReminder reminder = draft.copyWith(
      label: 'Drink water',
      repeatHours: 2,
      enabled: true,
      hasVoiceNote: true,
    );

    await service.save(<TaskVoiceReminder>[reminder]);

    final List<TaskVoiceReminder> restored = service.load();
    expect(restored, hasLength(1));
    expect(restored.single.label, 'Drink water');
    expect(restored.single.repeatHours, 2);
    expect(restored.single.hasVoiceNote, isTrue);
    expect(restored.single.notificationSlot, 0);
  });

  test('normalizes unsupported reminder repeat intervals to hourly', () {
    final TaskVoiceReminder restored = TaskVoiceReminder.fromJson(<String, dynamic>{
      'id': 'reminder-id',
      'notificationSlot': 1,
      'label': 'Lunch',
      'repeatHours': 4,
      'enabled': true,
      'hasVoiceNote': true,
    });

    expect(restored.repeatHours, 1);
    expect(restored.hasSupportedRepeatInterval, isTrue);
  });

  test('accepts only privacy-safe parent voice action payloads', () {
    const VoiceReminderAction action = VoiceReminderAction(
      kind: 'task',
      recordingKey: 'task_reminder_123',
    );

    expect(VoiceReminderAction.tryParse(action.payload)?.recordingKey, 'task_reminder_123');
    expect(VoiceReminderAction.tryParse('voice-reminder-v1|task|'), isNull);
    expect(VoiceReminderAction.tryParse('voice-reminder-v1|child|task_reminder_123'), isNull);
    expect(VoiceReminderAction.tryParse('Layla Hassan|2017-04-12'), isNull);
  });
}
