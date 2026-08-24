import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/locale_controller.dart';
import '../../data/local/task_voice_reminder_service.dart';
import '../../data/system/notification_service.dart';
import '../../data/system/parent_voice_notification_service.dart';
import '../../domain/models/task_voice_reminder.dart';
import 'voice_reminder_screens.dart';

class TaskVoiceReminderScreen extends StatefulWidget {
  const TaskVoiceReminderScreen({super.key});

  @override
  State<TaskVoiceReminderScreen> createState() => _TaskVoiceReminderScreenState();
}

class _TaskVoiceReminderScreenState extends State<TaskVoiceReminderScreen> {
  TaskVoiceReminderService? _service;
  List<TaskVoiceReminder> _reminders = const <TaskVoiceReminder>[];

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final TaskVoiceReminderService service = TaskVoiceReminderService(preferences);
    if (mounted) setState(() { _service = service; _reminders = service.load(); });
  }

  int get _scheduledCount => _reminders.where((TaskVoiceReminder item) => item.enabled).fold<int>(0, (int total, TaskVoiceReminder item) => total + 24 ~/ item.repeatHours);

  Future<void> _edit(TaskVoiceReminder reminder) async {
    final TaskVoiceReminder? updated = await Navigator.of(context).push<TaskVoiceReminder>(
      MaterialPageRoute(
        builder: (_) => _TaskVoiceReminderEditor(
          reminder: reminder,
          existingScheduledCount: _scheduledCount - (reminder.enabled ? 24 ~/ reminder.repeatHours : 0),
        ),
      ),
    );
    if (updated == null || _service == null) return;
    final List<TaskVoiceReminder> next = _reminders.where((TaskVoiceReminder item) => item.id != updated.id).toList()..add(updated);
    await _service!.save(next);
    if (updated.enabled) {
      await NotificationService().scheduleVoiceReminder(
        notificationSlot: updated.notificationSlot,
        repeatHours: updated.repeatHours,
        action: VoiceReminderAction(
          kind: 'task',
          recordingKey: ParentVoiceNotificationService.taskRecordingKey(updated.id),
        ),
      );
    } else {
      await NotificationService().cancelVoiceReminder(updated.notificationSlot);
    }
    if (mounted) setState(() => _reminders = next);
  }

  Future<void> _add() async {
    if (_service == null) return;
    try {
      await _edit(_service!.createDraft());
    } on StateError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar ? 'احذف تذكيرًا غير مستخدم قبل إضافة تذكير جديد.' : 'Delete an unused reminder before adding another one.')));
      }
    }
  }

  Future<void> _delete(TaskVoiceReminder reminder) async {
    if (_service == null) return;
    await NotificationService().cancelVoiceReminder(reminder.notificationSlot);
    await ParentVoiceNotificationService(recordingKey: ParentVoiceNotificationService.taskRecordingKey(reminder.id)).deleteRecording();
    final List<TaskVoiceReminder> next = _reminders.where((TaskVoiceReminder item) => item.id != reminder.id).toList();
    await _service!.save(next);
    if (mounted) setState(() => _reminders = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'مهام وتذكيرات الطفل' : 'Child tasks and reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(_ar ? 'تذكير جديد' : 'New reminder'),
      ),
      body: _service == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  _ar
                      ? 'سجّل تذكيرًا مثل «اشرب الماء» أو «تناول الغداء». يظهر إشعار دوري، ثم يفتح عيالنا لتشغيل الصوت المحلي.'
                      : 'Record reminders such as “drink water” or “have lunch.” A repeating notification opens 3ialna to play the local voice note.',
                ),
                const SizedBox(height: 8),
                Text(
                  _ar ? 'لا يظهر اسم المهمة في شاشة القفل ولا يُرفع الصوت إلى خادم.' : 'The task label is not shown on the lock screen, and no voice note is uploaded.'),
                const SizedBox(height: 18),
                if (_reminders.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_ar ? 'لا توجد تذكيرات بعد.' : 'No reminders yet.')))
                else
                  ..._reminders.map((TaskVoiceReminder reminder) => Card(
                        child: ListTile(
                          leading: Icon(reminder.enabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
                          title: Text(reminder.label.isEmpty ? (_ar ? 'تذكير صوتي' : 'Voice reminder') : reminder.label),
                          subtitle: Text(
                            '${reminder.repeatHours == 1 ? (_ar ? 'كل ساعة' : 'Every hour') : (_ar ? 'كل ساعتين' : 'Every two hours')} · ${reminder.hasVoiceNote ? (_ar ? 'صوت محلي جاهز' : 'Local voice ready') : (_ar ? 'سجّل صوتًا قبل التفعيل' : 'Record voice before enabling')}',
                          ),
                          onTap: () => _edit(reminder),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(reminder),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _TaskVoiceReminderEditor extends StatefulWidget {
  const _TaskVoiceReminderEditor({required this.reminder, required this.existingScheduledCount});

  final TaskVoiceReminder reminder;
  final int existingScheduledCount;

  @override
  State<_TaskVoiceReminderEditor> createState() => _TaskVoiceReminderEditorState();
}

class _TaskVoiceReminderEditorState extends State<_TaskVoiceReminderEditor> {
  late final TextEditingController _label = TextEditingController(text: widget.reminder.label);
  late int _repeatHours = widget.reminder.repeatHours;
  late bool _enabled = widget.reminder.enabled;
  late bool _hasVoiceNote = widget.reminder.hasVoiceNote;

  bool get _ar => LocaleController.instance.isArabic;

  Future<void> _record() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VoiceReminderRecordingScreen(
          recordingKey: ParentVoiceNotificationService.taskRecordingKey(widget.reminder.id),
          title: _ar ? 'صوت تذكير المهمة' : 'Task reminder voice',
          description: _ar ? 'سجّل ما تريد أن يسمعه الطفل عند فتح التذكير.' : 'Record what the child should hear after opening the reminder.',
        ),
      ),
    );
    if (saved == true && mounted) setState(() => _hasVoiceNote = true);
  }

  void _save() {
    if (_enabled && !_hasVoiceNote) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar ? 'سجّل صوت الوالدين قبل تفعيل التذكير.' : 'Record a parent voice note before enabling this reminder.')));
      return;
    }
    final int newCount = widget.existingScheduledCount + (_enabled ? 24 ~/ _repeatHours : 0);
    if (newCount > 60) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar ? 'قلّل التذكيرات النشطة. يدعم iPhone حتى 60 إشعار تذكير محفوظًا.' : 'Reduce active reminders. iPhone supports up to 60 saved reminder notifications.')));
      return;
    }
    Navigator.of(context).pop(widget.reminder.copyWith(
      label: _label.text.trim(),
      repeatHours: _repeatHours,
      enabled: _enabled,
      hasVoiceNote: _hasVoiceNote,
    ));
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'إعداد تذكير' : 'Set up reminder')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: _ar ? 'اسم داخلي للوالد' : 'Private parent label', hintText: _ar ? 'مثل: شرب الماء' : 'For example: Drink water'),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<int>(
            initialValue: _repeatHours,
            decoration: InputDecoration(labelText: _ar ? 'التكرار' : 'Repeat'),
            items: <DropdownMenuItem<int>>[
              DropdownMenuItem(value: 1, child: Text(_ar ? 'كل ساعة' : 'Every hour')),
              DropdownMenuItem(value: 2, child: Text(_ar ? 'كل ساعتين' : 'Every two hours')),
            ],
            onChanged: (int? value) => setState(() => _repeatHours = value ?? 1),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: Icon(_hasVoiceNote ? Icons.mic : Icons.mic_none),
            title: Text(_hasVoiceNote ? (_ar ? 'الصوت المحلي جاهز' : 'Local voice ready') : (_ar ? 'سجّل صوت الوالدين' : 'Record parent voice')),
            subtitle: Text(_ar ? 'يمكن الاستبدال أو الحذف من شاشة التسجيل.' : 'You can replace or delete it from the recording screen.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _record,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (bool value) => setState(() => _enabled = value),
            title: Text(_ar ? 'تفعيل التذكير' : 'Enable reminder'),
            subtitle: Text(_ar ? 'الإشعار يفتح عيالنا لتشغيل الصوت، ولا يعمل الصوت تلقائيًا.' : 'The notification opens 3ialna to play the voice; it does not autoplay.'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: Text(_ar ? 'حفظ التذكير' : 'Save reminder')),
        ],
      ),
    );
  }
}
