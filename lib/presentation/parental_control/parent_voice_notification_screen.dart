import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/local/locale_controller.dart';
import '../../data/system/parent_voice_notification_service.dart';

class ParentVoiceNotificationScreen extends StatefulWidget {
  const ParentVoiceNotificationScreen({super.key});

  @override
  State<ParentVoiceNotificationScreen> createState() => _ParentVoiceNotificationScreenState();
}

class _ParentVoiceNotificationScreenState extends State<ParentVoiceNotificationScreen> {
  final ParentVoiceNotificationService _voiceService = ParentVoiceNotificationService();
  final AudioPlayer _player = AudioPlayer();
  File? _recording;
  bool _recordingNow = false;
  bool _playing = false;

  bool get _ar => LocaleController.instance.isArabic;

  @override
  void initState() {
    super.initState();
    _loadRecording();
  }

  Future<void> _loadRecording() async {
    final File? file = await _voiceService.getRecording();
    if (mounted) setState(() => _recording = file);
  }

  Future<void> _toggleRecording() async {
    try {
      if (_recordingNow) {
        await _voiceService.stopRecording();
        await _loadRecording();
        setState(() => _recordingNow = false);
      } else {
        await _voiceService.startRecording();
        setState(() => _recordingNow = true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ar ? 'تعذر الوصول إلى الميكروفون.' : 'Microphone access could not be started.')));
    }
  }

  Future<void> _play() async {
    if (_recording == null) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.setFilePath(_recording!.path);
    setState(() => _playing = true);
    await _player.play();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _delete() async {
    await _player.stop();
    await _voiceService.deleteRecording();
    if (mounted) setState(() { _recording = null; _playing = false; });
  }

  @override
  void dispose() {
    _player.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ar ? 'صوت الوالدين' : 'Parent voice message')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.record_voice_over, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            _ar ? 'سجّل رسالة بصوتك لتُستخدم في التنبيهات الصوتية.' : 'Record a message in your voice for the app’s voice notifications.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            _ar ? 'يُحفظ التسجيل على هذا الجهاز فقط. لا يتم رفعه أو تحليل محتواه.' : 'The recording stays on this device. It is not uploaded or analyzed.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _toggleRecording,
            icon: Icon(_recordingNow ? Icons.stop : Icons.mic),
            label: Text(_recordingNow ? (_ar ? 'إيقاف التسجيل' : 'Stop recording') : (_ar ? 'بدء التسجيل' : 'Start recording')),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _voiceService.requestExactAlarmPermission,
              icon: const Icon(Icons.alarm),
              label: Text(_ar ? 'السماح بالتنبيه في الخلفية' : 'Allow background alarm playback'),
            ),
          ],
          if (Platform.isIOS) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _voiceService.requestVoiceNotificationPermission,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(_ar ? 'السماح بالتنبيه الصوتي' : 'Allow voice notification'),
            ),
          ],
          if (_recording != null) ...[
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.audio_file),
              title: Text(_ar ? 'التسجيل الحالي' : 'Current recording'),
              subtitle: Text(_ar ? 'جاهز للاستخدام في التنبيهات' : 'Ready for notification playback'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(onPressed: _play, icon: Icon(_playing ? Icons.stop : Icons.play_arrow)),
                  IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            _ar ? 'ملاحظة: سيظل النص المكتوب ظاهرًا في الإشعار، ويمكن استخدام التسجيل عند بدء روتين التنبيه.' : 'The written notification remains visible, and this recording can be used when the notification routine starts.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
