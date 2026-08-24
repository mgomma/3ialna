/// Validates a mobile number against the calling code and mobile-number shape
/// of a country supported by 3ialna's country profile.
class CountryMobilePhoneValidation {
  const CountryMobilePhoneValidation._({
    required this.e164,
    required this.error,
  });

  const CountryMobilePhoneValidation.valid(String e164)
      : this._(e164: e164, error: null);

  const CountryMobilePhoneValidation.invalid(String error)
      : this._(e164: null, error: error);

  final String? e164;
  final String? error;

  bool get isValid => e164 != null;
}

class CountryMobilePhoneValidator {
  CountryMobilePhoneValidator._();

  static final Map<String, _CountryMobileRule> _rules =
      <String, _CountryMobileRule>{
    'Saudi Arabia': _CountryMobileRule('966', RegExp(r'^5\d{8}$'), 'السعودية'),
    'Egypt': _CountryMobileRule('20', RegExp(r'^1\d{9}$'), 'مصر'),
    'UAE': _CountryMobileRule('971', RegExp(r'^5\d{8}$'), 'الإمارات'),
    'Kuwait': _CountryMobileRule('965', RegExp(r'^[4569]\d{7}$'), 'الكويت'),
    'Qatar': _CountryMobileRule('974', RegExp(r'^[3567]\d{7}$'), 'قطر'),
    'Bahrain': _CountryMobileRule('973', RegExp(r'^[36]\d{7}$'), 'البحرين'),
    'Iraq': _CountryMobileRule('964', RegExp(r'^7\d{9}$'), 'العراق'),
    'Lebanon': _CountryMobileRule('961', RegExp(r'^[378]\d{6,7}$'), 'لبنان'),
    'Jordan': _CountryMobileRule('962', RegExp(r'^7\d{8}$'), 'الأردن'),
    'Syria': _CountryMobileRule('963', RegExp(r'^9\d{8}$'), 'سوريا'),
    'Sudan': _CountryMobileRule('249', RegExp(r'^9\d{8}$'), 'السودان'),
    'Tunisia': _CountryMobileRule('216', RegExp(r'^[2459]\d{7}$'), 'تونس'),
    'Algeria': _CountryMobileRule('213', RegExp(r'^[567]\d{8}$'), 'الجزائر'),
    'Maroc': _CountryMobileRule('212', RegExp(r'^[67]\d{8}$'), 'المغرب'),
  };

  static const Map<String, String> _countryAliases = <String, String>{
    'SA': 'Saudi Arabia',
    'EG': 'Egypt',
    'AE': 'UAE',
    'KW': 'Kuwait',
    'QA': 'Qatar',
    'BH': 'Bahrain',
    'IQ': 'Iraq',
    'LB': 'Lebanon',
    'JO': 'Jordan',
    'SY': 'Syria',
    'SD': 'Sudan',
    'TN': 'Tunisia',
    'DZ': 'Algeria',
    'MA': 'Maroc',
  };

  static String canonicalCountry(String? country) {
    final String trimmed = country?.trim() ?? '';
    return _rules.containsKey(trimmed)
        ? trimmed
        : _countryAliases[trimmed.toUpperCase()] ?? 'Saudi Arabia';
  }

  static String callingCodeFor(String? country) =>
      '+${_rules[canonicalCountry(country)]!.callingCode}';

  static String countryNameFor(String? country, {required bool isArabic}) {
    final String canonical = canonicalCountry(country);
    return isArabic ? _rules[canonical]!.arabicName : canonical;
  }

  static CountryMobilePhoneValidation validate({
    required String country,
    required String input,
  }) {
    final String canonical = canonicalCountry(country);
    final _CountryMobileRule rule = _rules[canonical]!;
    final String normalized = _normalizeInput(input);

    if (normalized.isEmpty || normalized == '+') {
      return const CountryMobilePhoneValidation.invalid('missing');
    }

    String nationalNumber;
    if (normalized.startsWith('+')) {
      final String internationalNumber = normalized.substring(1);
      if (!internationalNumber.startsWith(rule.callingCode)) {
        return const CountryMobilePhoneValidation.invalid('countryCode');
      }
      nationalNumber = internationalNumber.substring(rule.callingCode.length);
    } else {
      nationalNumber = normalized;
      if (nationalNumber.startsWith('00')) {
        return const CountryMobilePhoneValidation.invalid('countryCode');
      }
      if (nationalNumber.startsWith('0')) {
        nationalNumber = nationalNumber.substring(1);
      }
    }

    if (!rule.mobilePattern.hasMatch(nationalNumber)) {
      return const CountryMobilePhoneValidation.invalid('mobile');
    }

    return CountryMobilePhoneValidation.valid(
      '+${rule.callingCode}$nationalNumber',
    );
  }

  static String _normalizeInput(String input) {
    const Map<String, String> localizedDigits = <String, String>{
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    String value = input.trim();
    localizedDigits.forEach((String localized, String ascii) {
      value = value.replaceAll(localized, ascii);
    });
    value = value.replaceAll(RegExp(r'[\s\-().]'), '');
    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }
    if (!RegExp(r'^\+?\d+$').hasMatch(value)) {
      return '';
    }
    return value;
  }
}

class _CountryMobileRule {
  const _CountryMobileRule(this.callingCode, this.mobilePattern, this.arabicName);

  final String callingCode;
  final RegExp mobilePattern;
  final String arabicName;
}
