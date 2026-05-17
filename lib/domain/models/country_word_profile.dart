class CountryWordProfile {
  const CountryWordProfile({
    required this.country,
    required this.welcomeWord,
    required this.childWord,
    required this.praiseWord,
  });

  final String country;
  final String welcomeWord;
  final String childWord;
  final String praiseWord;

  static const List<String> supportedCountries = <String>[
    'Saudi Arabia',
    'Egypt',
    'UAE',
    'Kuwait',
    'Qatar',
    'Bahrain',
    'Iraq',
    'Lebanon',
    'Jordan',
    'Syria',
    'Sudan',
    'Tunisia',
    'Algeria',
    'Maroc',
  ];

  static CountryWordProfile fromCountry(String country) {
    final String normalized = country.trim();

    switch (normalized) {
      case 'Saudi Arabia':
      case 'UAE':
      case 'Kuwait':
      case 'Qatar':
      case 'Bahrain':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'حياك',
          childWord: 'ولدك',
          praiseWord: 'كفو',
        );
      case 'Egypt':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'اهلا',
          childWord: 'ابنك',
          praiseWord: 'شاطر',
        );
      case 'Iraq':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'مرحبا',
          childWord: 'ولدك',
          praiseWord: 'بطل',
        );
      case 'Lebanon':
      case 'Jordan':
      case 'Syria':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'اهلا',
          childWord: 'ابنك',
          praiseWord: 'كويس',
        );
      case 'Sudan':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'مرحبا',
          childWord: 'ولدك',
          praiseWord: 'كويس',
        );
      case 'Tunisia':
      case 'Algeria':
      case 'Maroc':
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'مرحبا',
          childWord: 'ولدك',
          praiseWord: 'بطل',
        );
      default:
        return CountryWordProfile(
          country: normalized,
          welcomeWord: 'مرحبا',
          childWord: 'ابنك',
          praiseWord: 'شاطر',
        );
    }
  }
}
