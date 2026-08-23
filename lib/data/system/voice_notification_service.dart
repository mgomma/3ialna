import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';

/// Speaks the same user-authored text used by prayer notifications.
class VoiceNotificationService {
  VoiceNotificationService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _configure(String text) async {
    if (!_configured) {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      _configured = true;
    }

    final bool containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    try {
      await _tts.setLanguage(containsArabic ? 'ar-SA' : 'en-US');
    } catch (error, stackTrace) {
      developer.log(
        'Requested TTS language is unavailable; using the device default voice',
        name: 'prayer_lock.voice_notification',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> speak(String text) async {
    final String message = text.trim();
    if (message.isEmpty) return;

    try {
      await _configure(message);
      await _tts.stop();
      await _tts.speak(message);
    } catch (error, stackTrace) {
      // Voice playback must never prevent the prayer lock or notification.
      developer.log(
        'Voice notification playback failed',
        name: 'prayer_lock.voice_notification',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (error, stackTrace) {
      developer.log(
        'Voice notification stop failed',
        name: 'prayer_lock.voice_notification',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
