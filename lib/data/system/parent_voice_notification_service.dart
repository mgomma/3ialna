import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ParentVoiceNotificationService {
  ParentVoiceNotificationService({
    AudioRecorder? recorder,
    String recordingKey = defaultRecordingKey,
  })  : _recorder = recorder ?? AudioRecorder(),
        _recordingKey = recordingKey;

  static const String defaultRecordingKey = 'parent_voice_notification';
  static const String prayerReminderRecordingKey = 'prayer_reminder_voice';

  static String taskRecordingKey(String taskId) => 'task_reminder_$taskId';

  final AudioRecorder _recorder;
  final AudioPlayer _player = AudioPlayer();
  final String _recordingKey;
  String get fileName => Platform.isIOS ? '$_recordingKey.wav' : '$_recordingKey.m4a';
  static const MethodChannel _backgroundChannel = MethodChannel('parent_voice_notifications');

  Future<String> get _filePath async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission is required.');
    }
    await _recorder.start(
      RecordConfig(encoder: Platform.isIOS ? AudioEncoder.wav : AudioEncoder.aacLc),
      path: await _filePath,
    );
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<bool> get isRecording => _recorder.isRecording();

  Future<File?> getRecording() async {
    final File file = File(await _filePath);
    return file.existsSync() ? file : null;
  }

  Future<void> playRecording() async {
    final File? file = await getRecording();
    if (file == null) return;
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> stopPlayback() => _player.stop();

  Future<bool> scheduleBackgroundPlayback(DateTime scheduledAt) async {
    final File? file = await getRecording();
    if (file == null || scheduledAt.isBefore(DateTime.now())) return false;
    return await _backgroundChannel.invokeMethod<bool>('scheduleVoicePlayback', <String, Object>{
          'path': file.path,
          'atMillis': scheduledAt.millisecondsSinceEpoch,
        }) ??
        false;
  }

  /// Schedules background playback for every upcoming prayer reminder. Native
  /// code owns delivery while Flutter is suspended or the device is locked.
  Future<bool> schedulePrayerBackgroundPlayback(
    Iterable<DateTime> scheduledTimes,
  ) async {
    final File? file = await getRecording();
    final List<int> times = scheduledTimes
        .where((DateTime value) => value.isAfter(DateTime.now()))
        .map((DateTime value) => value.millisecondsSinceEpoch)
        .toSet()
        .toList()
      ..sort();
    if (file == null || times.isEmpty) return false;

    return await _backgroundChannel.invokeMethod<bool>(
          'schedulePrayerVoicePlayback',
          <String, Object>{
            'path': file.path,
            'atMillisList': times,
          },
        ) ??
        false;
  }

  Future<void> cancelBackgroundPlayback() => _backgroundChannel.invokeMethod<void>('cancelVoicePlayback');

  Future<void> cancelPrayerBackgroundPlayback() =>
      _backgroundChannel.invokeMethod<void>('cancelPrayerVoicePlayback');

  Future<bool> isBackgroundPlaybackScheduled() async {
    return await _backgroundChannel.invokeMethod<bool>('isVoicePlaybackScheduled') ?? false;
  }

  Future<bool> canScheduleExactAlarms() async {
    return await _backgroundChannel.invokeMethod<bool>('canScheduleExactAlarms') ??
        true;
  }

  Future<void> requestExactAlarmPermission() => _backgroundChannel.invokeMethod<void>('requestExactAlarmPermission');

  Future<bool> requestVoiceNotificationPermission() async {
    return await _backgroundChannel.invokeMethod<bool>('requestVoiceNotificationPermission') ?? false;
  }

  Future<void> deleteRecording() async {
    final File file = File(await _filePath);
    if (file.existsSync()) await file.delete();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _recorder.dispose();
  }
}
