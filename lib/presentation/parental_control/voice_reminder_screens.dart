import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../data/local/locale_controller.dart';
import '../../data/system/error_report_service.dart';
import '../../data/system/parent_voice_notification_service.dart';

class VoiceReminderRecordingScreen extends StatefulWidget {
  const VoiceReminderRecordingScreen({
    required this.recordingKey,
    required this.title,
    required this.description,
    super.key,
  });

  final String recordingKey;
  final String title;
  final String description;

  @override
  State<VoiceReminderRecordingScreen> createState() =>
      _VoiceReminderRecordingScreenState();
}

class _VoiceReminderRecordingScreenState extends State<VoiceReminderRecordingScreen> {
  late final ParentVoiceNotificationService _voiceService =
      ParentVoiceNotificationService(recordingKey: widget.recordingKey);
  File? _recording;
  bool _recordingNow = false;
  bool _playing = false;
  Timer? _iosLimit;

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final File? recording = await _voiceService.getRecording();
    if (mounted) setState(() => _recording = recording);
  }

  Future<void> _toggleRecord() async {
    try {
      if (_recordingNow) {
        _iosLimit?.cancel();
        await _voiceService.stopRecording();
        await _load();
        if (mounted) setState(() => _recordingNow = false);
      } else {
        await _voiceService.startRecording();
        if (mounted) setState(() => _recordingNow = true);
        if (Platform.isIOS) {
          _iosLimit = Timer(const Duration(seconds: 30), () {
            if (_recordingNow) _toggleRecord();
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ar ? 'تعذر بدء التسجيل. تحقّق من إذن الميكروفون.' : 'Recording could not start. Check microphone permission.')),
      );
    }
  }

  Future<void> _play() async {
    if (_recording == null) return;
    if (_playing) {
      await _voiceService.stopPlayback();
      if (mounted) setState(() => _playing = false);
      return;
    }
    if (mounted) setState(() => _playing = true);
    await _voiceService.playRecording();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _delete() async {
    await _voiceService.deleteRecording();
    if (mounted) setState(() => _recording = null);
  }

  @override
  void dispose() {
    _iosLimit?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          TextButton(
            onPressed: _recording == null ? null : () => Navigator.of(context).pop(true),
            child: Text(_ar ? 'تم' : 'Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Icon(Icons.mic_none_rounded, size: 72),
          const SizedBox(height: 16),
          Text(widget.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _ar
                ? 'يبقى الصوت على هذا الجهاز. يفتح الإشعار عيالنا ليشغّل التسجيل؛ لا يعمل تلقائيًا في الخلفية.'
                : 'The voice note stays on this device. A notification opens 3ialna to play it; it never auto-plays in the background.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _toggleRecord,
            icon: Icon(_recordingNow ? Icons.stop : Icons.mic),
            label: Text(_recordingNow ? (_ar ? 'إيقاف التسجيل' : 'Stop recording') : (_ar ? 'بدء التسجيل' : 'Start recording')),
          ),
          if (_recording != null) ...<Widget>[
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: Text(_ar ? 'تسجيل محلي جاهز' : 'Local recording ready'),
              subtitle: Text(_ar ? 'يمكنك الاستماع أو الاستبدال أو الحذف.' : 'You can preview, replace, or delete it.'),
              trailing: Wrap(
                children: <Widget>[
                  IconButton(onPressed: _play, icon: Icon(_playing ? Icons.stop : Icons.play_arrow)),
                  IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VoiceReminderPlaybackScreen extends StatefulWidget {
  const VoiceReminderPlaybackScreen({
    required this.recordingKey,
    required this.kind,
    super.key,
  });

  final String recordingKey;
  final String kind;

  @override
  State<VoiceReminderPlaybackScreen> createState() => _VoiceReminderPlaybackScreenState();
}

class _VoiceReminderPlaybackScreenState extends State<VoiceReminderPlaybackScreen> {
  late final ParentVoiceNotificationService _voiceService =
      ParentVoiceNotificationService(recordingKey: widget.recordingKey);
  bool _available = false;
  bool _playing = false;

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _loadAndPlay();
  }

  Future<void> _loadAndPlay() async {
    try {
      final bool available = await _voiceService.getRecording() != null;
      if (!mounted) return;
      setState(() => _available = available);
      if (!available) {
        await ErrorReportService.recordEvent(
          source: 'voice_playback',
          event: 'voice_playback_unavailable',
        );
        return;
      }
      await _play();
    } catch (error, stackTrace) {
      await ErrorReportService.recordHandled(
        source: 'voice_playback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _play() async {
    if (!_available) return;
    try {
      if (mounted) setState(() => _playing = true);
      await ErrorReportService.recordEvent(
        source: 'voice_playback',
        event: 'voice_playback_started',
      );
      await _voiceService.playRecording();
    } catch (error, stackTrace) {
      await ErrorReportService.recordHandled(
        source: 'voice_playback',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool prayer = widget.kind == 'prayer';
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'تذكير بصوت الوالدين' : 'Parent voice reminder')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(prayer ? Icons.mosque_outlined : Icons.task_alt, size: 72),
              const SizedBox(height: 18),
              Text(
                _available
                    ? (_ar ? 'يتم تشغيل تسجيل الوالدين المحلي.' : 'Playing the local parent recording.')
                    : (_ar ? 'لم يعد تسجيل الوالدين متاحًا لهذا التذكير.' : 'The local parent recording is no longer available for this reminder.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_available) ...<Widget>[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _playing ? null : _play,
                  icon: Icon(_playing ? Icons.volume_up : Icons.replay),
                  label: Text(_playing ? (_ar ? 'قيد التشغيل' : 'Playing') : (_ar ? 'تشغيل مرة أخرى' : 'Play again')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
