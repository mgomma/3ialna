/// Model representing a schedule for app restrictions.
class Schedule {
  final bool enabled;
  final String startTime; // Format: "HH:mm" (e.g., "09:00")
  final String endTime; // Format: "HH:mm" (e.g., "21:00")
  final List<int> activeDays; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final bool differentWeekendRules;
  final String? weekendStartTime;
  final String? weekendEndTime;

  const Schedule({
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    this.differentWeekendRules = false,
    this.weekendStartTime,
    this.weekendEndTime,
  });

  /// Checks if restrictions should be active right now.
  bool isActiveNow() {
    if (!enabled) return false;

    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0-6 format
    final isWeekend = currentDay == 0 || currentDay == 6;

    // Check if current day is in active days
    if (!activeDays.contains(currentDay)) return false;

    String start;
    String end;

    if (differentWeekendRules && isWeekend) {
      start = weekendStartTime ?? startTime;
      end = weekendEndTime ?? endTime;
    } else {
      start = startTime;
      end = endTime;
    }

    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return _isTimeBetween(currentTime, start, end);
  }

  /// Checks if a time string is between two time strings.
  bool _isTimeBetween(String time, String start, String end) {
    final timeMinutes = _timeToMinutes(time);
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);

    if (startMinutes <= endMinutes) {
      // Normal case: start < end (e.g., 09:00 to 21:00)
      return timeMinutes >= startMinutes && timeMinutes < endMinutes;
    } else {
      // Overnight case: start > end (e.g., 22:00 to 06:00)
      return timeMinutes >= startMinutes || timeMinutes < endMinutes;
    }
  }

  /// Converts time string (HH:mm) to minutes since midnight.
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      // A missing field is an incomplete/older record, not a parent opt-out.
      // Explicit false remains preserved.
      enabled: map['enabled'] as bool? ?? true,
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '21:00',
      activeDays: (map['activeDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 0], // All days by default
      differentWeekendRules: map['differentWeekendRules'] as bool? ?? false,
      weekendStartTime: map['weekendStartTime'] as String?,
      weekendEndTime: map['weekendEndTime'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'startTime': startTime,
      'endTime': endTime,
      'activeDays': activeDays,
      'differentWeekendRules': differentWeekendRules,
      'weekendStartTime': weekendStartTime,
      'weekendEndTime': weekendEndTime,
    };
  }

  Schedule copyWith({
    bool? enabled,
    String? startTime,
    String? endTime,
    List<int>? activeDays,
    bool? differentWeekendRules,
    String? weekendStartTime,
    String? weekendEndTime,
  }) {
    return Schedule(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeDays: activeDays ?? this.activeDays,
      differentWeekendRules: differentWeekendRules ?? this.differentWeekendRules,
      weekendStartTime: weekendStartTime ?? this.weekendStartTime,
      weekendEndTime: weekendEndTime ?? this.weekendEndTime,
    );
  }
}
