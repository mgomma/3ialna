import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/l10n/app_localizations.dart';

/// Keys whose Arabic value is intentionally identical to English. Language
/// names stay in their own script so a parent can find their language in a
/// picker they cannot currently read.
const Set<String> intentionallyShared = <String>{'english', 'arabic'};

void main() {
  final AppLocalizations en = AppLocalizations(const Locale('en'));
  final AppLocalizations ar = AppLocalizations(const Locale('ar'));

  test('every English key has an Arabic translation', () {
    final Map<String, String> english = AppLocalizations.valuesFor('en');
    final Map<String, String> arabic = AppLocalizations.valuesFor('ar');

    final List<String> missing = english.keys
        .where((String key) => !arabic.containsKey(key))
        .toList();

    expect(missing, isEmpty, reason: 'Missing Arabic translations for: $missing');
  });

  test('Arabic values are not left as untranslated English', () {
    final Map<String, String> english = AppLocalizations.valuesFor('en');
    final Map<String, String> arabic = AppLocalizations.valuesFor('ar');

    final List<String> untranslated = <String>[];
    for (final MapEntry<String, String> entry in english.entries) {
      if (intentionallyShared.contains(entry.key)) continue;
      if (arabic[entry.key] == entry.value) untranslated.add(entry.key);
    }

    expect(untranslated, isEmpty,
        reason: 'These keys still show English in Arabic mode: $untranslated');
  });

  test('Arabic values contain Arabic script', () {
    final RegExp arabicScript = RegExp(r'[\u0600-\u06FF]');
    final Map<String, String> arabic = AppLocalizations.valuesFor('ar');

    final List<String> suspicious = <String>[];
    for (final MapEntry<String, String> entry in arabic.entries) {
      if (intentionallyShared.contains(entry.key)) continue;
      if (!arabicScript.hasMatch(entry.value)) suspicious.add(entry.key);
    }

    expect(suspicious, isEmpty,
        reason: 'Arabic entries without Arabic script: $suspicious');
  });

  test('screens resolve newly localized strings in both locales', () {
    expect(en.scheduleSettings, 'Schedule Settings');
    expect(ar.scheduleSettings, isNot(en.scheduleSettings));
    expect(en.cancel, 'Cancel');
    expect(ar.cancel, isNot(en.cancel));
    expect(ar.countryName('SA'), isNot(en.countryName('SA')));
    expect(ar.pinLockedMinutes(3), contains('3'));
  });

  test('every offered country code has a name in both locales', () {
    for (final String code in AppLocalizations.countryCodes) {
      expect(en.countryName(code), isNotEmpty, reason: 'missing en for $code');
      expect(ar.countryName(code), isNotEmpty, reason: 'missing ar for $code');
      expect(ar.countryName(code), isNot(startsWith('country_')),
          reason: '$code falls back to the raw key');
    }
  });
}
