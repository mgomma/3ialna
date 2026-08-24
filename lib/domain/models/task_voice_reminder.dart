/// A parent-managed, local reminder. Its label is intentionally retained only
/// on device; notifications use generic text to avoid exposing the task on a
/// child device's lock screen.
class TaskVoiceReminder {
  const TaskVoiceReminder({
    required this.id,
    required this.notificationSlot,
    required this.label,
    required this.repeatHours,
    required this.enabled,
    required this.hasVoiceNote,
  });

  final String id;
  final int notificationSlot;
  final String label;
  final int repeatHours;
  final bool enabled;
  final bool hasVoiceNote;

  bool get hasSupportedRepeatInterval => repeatHours == 1 || repeatHours == 2;

  TaskVoiceReminder copyWith({
    String? label,
    int? repeatHours,
    bool? enabled,
    bool? hasVoiceNote,
  }) {
    return TaskVoiceReminder(
      id: id,
      notificationSlot: notificationSlot,
      label: label ?? this.label,
      repeatHours: repeatHours ?? this.repeatHours,
      enabled: enabled ?? this.enabled,
      hasVoiceNote: hasVoiceNote ?? this.hasVoiceNote,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'notificationSlot': notificationSlot,
        'label': label,
        'repeatHours': repeatHours,
        'enabled': enabled,
        'hasVoiceNote': hasVoiceNote,
      };

  factory TaskVoiceReminder.fromJson(Map<String, dynamic> json) {
    final int repeatHours = json['repeatHours'] as int? ?? 1;
    return TaskVoiceReminder(
      id: json['id'] as String,
      notificationSlot: json['notificationSlot'] as int? ?? 0,
      label: (json['label'] as String? ?? '').trim(),
      repeatHours: repeatHours == 2 ? 2 : 1,
      enabled: json['enabled'] as bool? ?? false,
      hasVoiceNote: json['hasVoiceNote'] as bool? ?? false,
    );
  }
}
