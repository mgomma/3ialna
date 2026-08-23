/// Location-aware defaults for prayer calculation settings.
///
/// This policy uses country codes when the host platform provides one and
/// otherwise uses conservative coordinate regions. It never stores location
/// data itself; callers decide whether and how to persist coordinates.
class PrayerCalculationMethodPolicy {
  const PrayerCalculationMethodPolicy._();

  static const String ummAlQura = 'makkah';
  static const String northAmerica = 'isna';
  static const String fallback = ummAlQura;

  static const Set<String> _middleEastCountryCodes = <String>{
    'BH', 'IQ', 'JO', 'KW', 'LB', 'OM', 'PS', 'QA', 'SA', 'SY', 'AE', 'YE',
  };

  static const Set<String> _northAmericaCountryCodes = <String>{
    'CA', 'US', 'MX',
  };

  /// Returns the default method for a country code and/or coordinates.
  ///
  /// Umm al-Qura is selected for the Middle East. ISNA is selected for
  /// Canada, the United States, and Mexico. If a country code is unavailable,
  /// broad coordinate regions provide a best-effort local default.
  static String forLocation({String? countryCode, double? latitude, double? longitude}) {
    final String? normalizedCountry = countryCode?.trim().toUpperCase();
    if (normalizedCountry != null && _middleEastCountryCodes.contains(normalizedCountry)) {
      return ummAlQura;
    }
    if (normalizedCountry != null && _northAmericaCountryCodes.contains(normalizedCountry)) {
      return northAmerica;
    }

    if (latitude != null && longitude != null) {
      if (_isMiddleEast(latitude, longitude)) return ummAlQura;
      if (_isNorthAmerica(latitude, longitude)) return northAmerica;
    }
    return fallback;
  }

  static bool _isMiddleEast(double latitude, double longitude) {
    return latitude >= 12 && latitude <= 38 && longitude >= 25 && longitude <= 63;
  }

  static bool _isNorthAmerica(double latitude, double longitude) {
    return latitude >= 14 && latitude <= 72 && longitude >= -170 && longitude <= -50;
  }
}
