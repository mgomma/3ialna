import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/prayer_service.dart';

class PrayerLockProvider extends ChangeNotifier {
  final PrayerService _prayerService = PrayerService();

  StreamSubscription<bool>? _sub;
  bool _isLocked = false;
  String? _prayerName;
  DateTime? _lockStart;
  DateTime? _lockEnd;

  bool get isLocked => _isLocked;
  String? get prayerName => _prayerName;
  DateTime? get lockStart => _lockStart;
  DateTime? get lockEnd => _lockEnd;

  PrayerLockProvider() {
    _startWatching();
  }

  Future<void> _startWatching() async {
    try {
      final position = await _prayerService.getCurrentLocation();
      final latitude = position?.latitude ?? 24.7136; // Riyadh fallback
      final longitude = position?.longitude ?? 46.6753;

      final stream = _prayerService.lockStateStream(
        latitude: latitude,
        longitude: longitude,
        interval: const Duration(seconds: 30),
      );

      _sub = stream.listen((locked) {
        _isLocked = locked;
        if (locked) {
          // find current prayer to populate name and window
          final prayerTimes = _prayerService.calculatePrayerTimes(
            latitude: latitude,
            longitude: longitude,
            date: DateTime.now(),
          );

          final now = DateTime.now();
          for (final p in prayerTimes) {
            final window = _prayerService.getLockWindow(p.time);
            if (now.isAfter(window['start']!) && now.isBefore(window['end']!)) {
              _prayerName = p.name;
              _lockStart = window['start'];
              _lockEnd = window['end'];
              break;
            }
          }
        } else {
          _prayerName = null;
          _lockStart = null;
          _lockEnd = null;
        }

        notifyListeners();
      });
    } catch (e) {
      // silently ignore; provider won't lock if location/prayer calc fails
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
