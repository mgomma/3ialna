import 'package:flutter/widgets.dart';

/// Simple localizations class for English and Arabic.
///
/// This keeps things small and explicit without relying on code generation.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        ) ??
        AppLocalizations(const Locale('en'));
  }

  static final Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
    'en': <String, String>{
      'appTitle': '3ialna',
      'dailyTimeLimit': 'Daily Time Limit',
      'minutesSuffix': 'minutes',
      'startMonitoring': 'Start Monitoring',
      'stopMonitoring': 'Stop Monitoring',
      'noUsageTitle': 'No usage data yet',
      'noUsageSubtitle':
          'Start monitoring to track your social media usage.',
      'timeLimitReachedTitle': 'Time Limit Reached!',
      'timeLimitReachedMessage':
          'You have used {appName} for {used} minutes today, '
              'which exceeds your limit of {limit} minutes.',
      'takeABreak': 'Take a Break',
      'overlayPermissionTitle':
          'Overlay permission required',
      'overlayPermissionBody':
          'To block social media apps when you exceed your '
              'limit, the app needs permission to show a screen '
              'on top of other apps.\n\n'
              'Do you want to continue to the system settings '
              'to grant this permission?',
      'notNow': 'Not now',
      'continue': 'Continue',
      'usageAccessTitle': 'Usage data access needed',
      'usageAccessBody':
          'To monitor your social media time, the app needs '
              'access to your usage data.\n\n'
              'You can enable this by going to:\n'
              'Settings → Apps → Special access → Usage access, '
              'then choosing this app and turning access on.',
      'gotIt': 'Got it',
    },
    'ar': <String, String>{
      'appTitle': 'عيالنا',
      'dailyTimeLimit': 'الحد اليومي للوقت',
      'minutesSuffix': 'دقيقة',
      'startMonitoring': 'بدء المراقبة',
      'stopMonitoring': 'إيقاف المراقبة',
      'noUsageTitle': 'لا توجد بيانات استخدام بعد',
      'noUsageSubtitle':
          'ابدأ المراقبة لتتبع وقتك على تطبيقات التواصل الاجتماعي.',
      'timeLimitReachedTitle': 'تم تجاوز الحد الزمني!',
      'timeLimitReachedMessage':
          'لقد استخدمت {appName} لمدة {used} دقيقة اليوم، '
              'وذلك يتجاوز حدك البالغ {limit} دقيقة.',
      'takeABreak': 'خذ استراحة',
      'overlayPermissionTitle':
          'مطلوب إذن الظهور فوق التطبيقات',
      'overlayPermissionBody':
          'لمنع استخدام تطبيقات التواصل عند تجاوز الحد، يحتاج '
              'التطبيق إلى إذن للظهور فوق التطبيقات الأخرى.\n\n'
              'هل تريد المتابعة إلى إعدادات النظام لمنح هذا الإذن؟',
      'notNow': 'لاحقًا',
      'continue': 'متابعة',
      'usageAccessTitle': 'مطلوب إذن بيانات الاستخدام',
      'usageAccessBody':
          'لمراقبة وقتك على تطبيقات التواصل، يحتاج التطبيق إلى '
              'الوصول إلى بيانات الاستخدام.\n\n'
              'يمكنك تفعيل ذلك من خلال:\n'
              'الإعدادات → التطبيقات → وصول خاص → الوصول إلى '
              'الاستخدام، ثم اختيار هذا التطبيق وتفعيل الوصول.',
      'gotIt': 'حسنًا',
    },
  };

  String _text(String key) {
    final String languageCode = supportedLocales
            .map((Locale l) => l.languageCode)
            .contains(locale.languageCode)
        ? locale.languageCode
        : 'en';
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get appTitle => _text('appTitle');
  String get dailyTimeLimit => _text('dailyTimeLimit');
  String get minutesSuffix => _text('minutesSuffix');
  String get startMonitoring => _text('startMonitoring');
  String get stopMonitoring => _text('stopMonitoring');
  String get noUsageTitle => _text('noUsageTitle');
  String get noUsageSubtitle => _text('noUsageSubtitle');
  String get timeLimitReachedTitle =>
      _text('timeLimitReachedTitle');
  String get takeABreak => _text('takeABreak');
  String get overlayPermissionTitle =>
      _text('overlayPermissionTitle');
  String get overlayPermissionBody =>
      _text('overlayPermissionBody');
  String get notNow => _text('notNow');
  String get continueLabel => _text('continue');
  String get usageAccessTitle => _text('usageAccessTitle');
  String get usageAccessBody => _text('usageAccessBody');
  String get gotIt => _text('gotIt');

  String timeLimitReachedMessage({
    required String appName,
    required int usedMinutes,
    required int limitMinutes,
  }) {
    String template =
        _text('timeLimitReachedMessage');
    template = template.replaceAll(
      '{appName}',
      appName,
    );
    template = template.replaceAll(
      '{used}',
      '$usedMinutes',
    );
    template = template.replaceAll(
      '{limit}',
      '$limitMinutes',
    );
    return template;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return <String>['en', 'ar']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this);
}


