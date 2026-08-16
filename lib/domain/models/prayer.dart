/// Enumeration of the five daily prayers.
enum Prayer {
  /// Fajr (dawn prayer).
  fajr,

  /// Dhuhr (midday prayer).
  dhuhr,

  /// Asr (afternoon prayer).
  asr,

  /// Maghrib (sunset prayer).
  maghrib,

  /// Isha (night prayer).
  isha;

  /// Returns a human-readable name for the prayer.
  String get displayName {
    return switch (this) {
      Prayer.fajr => 'Fajr',
      Prayer.dhuhr => 'Dhuhr',
      Prayer.asr => 'Asr',
      Prayer.maghrib => 'Maghrib',
      Prayer.isha => 'Isha',
    };
  }
}

