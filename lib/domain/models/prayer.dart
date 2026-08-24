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

  /// Returns the Arabic prayer name for Arabic-first screens and notifications.
  String get arabicDisplayName {
    return switch (this) {
      Prayer.fajr => 'الفجر',
      Prayer.dhuhr => 'الظهر',
      Prayer.asr => 'العصر',
      Prayer.maghrib => 'المغرب',
      Prayer.isha => 'العشاء',
    };
  }
}
