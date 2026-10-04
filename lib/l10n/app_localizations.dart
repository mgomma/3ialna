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
      'requestExtraTime': 'Request extra time',
      'requestPending': 'Request pending',
      'reviewExtraTimeRequest': 'Review extra-time request',
      'approve': 'Approve',
      'decline': 'Decline',
      'requestSent': 'Request sent to your parent',
      'requestForChild': 'Request from {child}',
      'pendingRequestCount': '{count} pending extra-time requests',
      'durationMinutes': '{minutes} minutes',
      'tokensAvailable': '{count} Flex Tokens available',
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
      'countryProfileTitle': 'Country profile',
      'countryProfileHint': 'Select your country to personalize words.',
      'countryProfileCountryLabel': 'Country',
      'save': 'Save',
      'countryProfileSaved': 'Words updated for {country}: {word}',
      'countryProfileCardTitle': 'Personalized words',
        'registerTitle': 'Register',
        'registerButton': 'Register',
        'submitReportButton': 'Submit Report',
        'firstNameLabel': 'First name',
        'lastNameLabel': 'Last name',
        'emailLabel': 'Email',
        'passwordLabel': 'Password',
        'phoneLabel': 'Phone',
        'languageLabel': 'Language',
      'settings': 'Settings',
      'languageSettings': 'App language',
      'english': 'English',
      'arabic': 'العربية',
      'languageChanged': 'Language updated',
      'parentalControls': 'Parental Controls',
        'privacyPolicy': 'Privacy policy',
        'privacyAccountTitle': 'Privacy & account',
        'privacyAccountSummary':
          'Review how 3ialna handles your information and manage account deletion requests.',
        'accountDeletionTitle': 'Delete a registered account',
        'accountDeletionBody':
          'To request deletion of your registered account and associated server data, send a request from the email address on the account. Support will verify and process it. This does not erase local app data from this device.',
        'requestAccountDeletion': 'Request account deletion',
        'accountDeletionEmailSubject': '3ialna account and data deletion request',
        'accountDeletionEmailBody':
          'Please delete my registered 3ialna account and associated server-side data. I am sending this request from the email address registered to the account. Please tell me if you need any further verification. I have not included child information.',
        'externalLinkFailed': 'Could not open the link. Please try again.',
          'firstChildSetupTitle': 'Set up your child',
          'firstChildSetupIntro':
            'Enter your child’s details. 3ialna will select the age-matched starting profile; you can review and change every setting.',
          'childName': 'Child name',
          'birthDate': 'Date of birth',
          'gender': 'Gender',
          'chooseBirthDate': 'Choose date of birth',
          'chooseGender': 'Choose gender',
          'boy': 'Boy',
          'girl': 'Girl',
          'unspecified': 'Prefer not to say',
          'recommendedProfile': 'Recommended starting profile',
          'dailyBudget': 'Daily recreational budget',
          'socialBudget': 'Social media',
          'gamesBudget': 'Games',
          'sleepSchedule': 'Sleep schedule',
          'prayerLock': 'Prayer lock',
          'matureContentBlock': 'Block mature content',
          'parentApproval': 'Require parent approval for requests',
          'parentVoiceReminders': 'Parent voice reminders',
          'enabled': 'On',
          'disabled': 'Off',
          'saveChildProfile': 'Save child profile',
          'completeRequiredFields': 'Enter a name, date of birth, and gender to continue.',
      'changePin': 'Change PIN',
      'accessibilitySettings': 'Accessibility Settings',
      'close': 'Close',
      'enabledAppBlocking': 'Enabled - App blocking is active',
      'disabledAppBlocking': 'Disabled - Enable for app blocking',
        'registerSuccess': 'Registration complete and profile linked.',
        'registerFailedLocalMode':
          'Registration is unavailable now. Profile saved locally and app continues normally.',
        'profileSavedLocalOnly':
          'Profile saved locally. You can register later anytime.',
        'reportSubmittedOrQueued':
          'Report submitted (or queued if offline).',
        'reportSavedLocally':
          'Report saved locally. Register later to sync to your account.',
          'registerWithGoogle': 'Continue with Google',
          'registerWithFacebook': 'Continue with Facebook',
          'registerWithApple': 'Continue with Apple',
          'socialSignInFailed':
            'Could not complete social sign-in. Please try again or use email registration.',
          'socialMissingEmail':
            'This social account did not provide email. Please register with email/password.',
          'cancel': 'Cancel',
          'openSettings': 'Open Settings',
          'noThanks': 'No thanks',
          'agree': 'Agree',
          'parentUnlock': 'Parent Unlock',
          'adjustLimit': 'Adjust Limit',
          'adjustDailyLimit': 'Adjust Daily Limit',
          'accessibilityServiceRequired': 'Accessibility Service Required',
          'enableAppBlocking': 'Enable App Blocking',
          'pinUpdated': 'PIN updated successfully',
          'pinsDoNotMatch': 'PINs do not match. Please try again.',
          'incorrectPin': 'Incorrect PIN. Please try again.',
          'pinLockedMinutes': 'Too many attempts. Try again in {value} min.',
          'pinLockedSeconds': 'Too many attempts. Try again in {value}s.',
          'scheduleSaved': 'Schedule saved successfully',
          'scheduleSettings': 'Schedule Settings',
          'enableSchedule': 'Enable Schedule',
          'startTime': 'Start Time',
          'endTime': 'End Time',
          'differentWeekendRules': 'Different Weekend Rules',
          'scheduleEnableSubtitle': 'Restrictions will only apply during scheduled hours',
          'activeDays': 'Active Days',
          'timeRange': 'Time Range',
          'weekendTimeRange': 'Weekend Time Range',
          'weekendRulesSubtitle': 'Use different time restrictions for weekends',
          'restrictionsActive': 'Restrictions Active',
          'restrictionsInactive': 'Restrictions Inactive',
          'restrictionsEnforced': 'App restrictions are currently enforced',
          'restrictionsNotActive': 'App restrictions are not active',
          'dayMon': 'Mon',
          'dayTue': 'Tue',
          'dayWed': 'Wed',
          'dayThu': 'Thu',
          'dayFri': 'Fri',
          'daySat': 'Sat',
          'daySun': 'Sun',
          'country_SA': 'Saudi Arabia',
          'country_EG': 'Egypt',
          'country_AE': 'UAE',
          'country_KW': 'Kuwait',
          'country_QA': 'Qatar',
          'country_BH': 'Bahrain',
          'country_IQ': 'Iraq',
          'country_LB': 'Lebanon',
          'country_JO': 'Jordan',
          'country_SY': 'Syria',
          'country_SD': 'Sudan',
          'country_TN': 'Tunisia',
          'country_DZ': 'Algeria',
          'country_MA': 'Morocco',
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
      'requestExtraTime': 'طلب وقت إضافي',
      'requestPending': 'الطلب قيد المراجعة',
      'reviewExtraTimeRequest': 'مراجعة طلب وقت إضافي',
      'approve': 'موافقة',
      'decline': 'رفض',
      'requestSent': 'تم إرسال الطلب إلى الوالد',
      'requestForChild': 'طلب من {child}',
      'pendingRequestCount': '{count} طلبات وقت إضافي معلقة',
      'durationMinutes': '{minutes} دقائق',
      'tokensAvailable': 'التوكنات المتاحة: {count}',
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
      'countryProfileTitle': 'الملف اللفظي حسب الدولة',
      'countryProfileHint': 'اختر دولتك لتخصيص الكلمات داخل التطبيق.',
      'countryProfileCountryLabel': 'الدولة',
      'save': 'حفظ',
      'countryProfileSaved': 'تم تحديث الكلمات لـ {country}: {word}',
      'countryProfileCardTitle': 'كلمات مخصصة',
        'registerTitle': 'تسجيل',
        'registerButton': 'تسجيل',
        'submitReportButton': 'إرسال التقرير',
        'firstNameLabel': 'الاسم الأول',
        'lastNameLabel': 'اسم العائلة',
        'emailLabel': 'البريد الإلكتروني',
        'passwordLabel': 'كلمة المرور',
        'phoneLabel': 'رقم الهاتف',
        'languageLabel': 'اللغة',
        'settings': 'الإعدادات',
        'languageSettings': 'لغة التطبيق',
        'english': 'English',
        'arabic': 'العربية',
        'languageChanged': 'تم تحديث اللغة',
        'parentalControls': 'الرقابة الأبوية',
        'privacyPolicy': 'سياسة الخصوصية',
        'privacyAccountTitle': 'الخصوصية والحساب',
        'privacyAccountSummary':
          'راجع كيفية تعامل عيالنا مع معلوماتك وقدّم طلب حذف الحساب.',
        'accountDeletionTitle': 'حذف حساب مسجّل',
        'accountDeletionBody':
          'لطلب حذف حسابك المسجّل والبيانات المرتبطة به على الخادم، أرسل الطلب من البريد الإلكتروني المسجّل للحساب. سيتحقق فريق الدعم من الطلب ويعالجه. لا يؤدي ذلك إلى حذف بيانات التطبيق المحلية من هذا الجهاز.',
        'requestAccountDeletion': 'طلب حذف الحساب',
        'accountDeletionEmailSubject': 'طلب حذف حساب وبيانات عيالنا',
        'accountDeletionEmailBody':
          'أرجو حذف حساب عيالنا المسجّل والبيانات المرتبطة به على الخادم. أرسل هذا الطلب من البريد الإلكتروني المسجّل للحساب. يرجى إخباري إذا لزم أي تحقق إضافي. لم أرفق معلومات عن الأطفال.',
        'externalLinkFailed': 'تعذر فتح الرابط. يرجى المحاولة مرة أخرى.',
        'firstChildSetupTitle': 'إعداد ملف الطفل',
        'firstChildSetupIntro':
          'أدخل بيانات طفلك. سيختار عيالنا إعداد البداية المناسب لعمره، ويمكنك مراجعة كل إعداد وتغييره.',
        'childName': 'اسم الطفل',
        'birthDate': 'تاريخ الميلاد',
        'gender': 'النوع',
        'chooseBirthDate': 'اختر تاريخ الميلاد',
        'chooseGender': 'اختر النوع',
        'boy': 'ولد',
        'girl': 'بنت',
        'unspecified': 'أفضل عدم التحديد',
        'recommendedProfile': 'إعداد البداية المقترح',
        'dailyBudget': 'الميزانية الترفيهية اليومية',
        'socialBudget': 'وسائل التواصل الاجتماعي',
        'gamesBudget': 'الألعاب',
        'sleepSchedule': 'جدول النوم',
        'prayerLock': 'قفل الصلاة',
        'matureContentBlock': 'حظر المحتوى غير المناسب',
        'parentApproval': 'طلب موافقة الوالد على الطلبات',
        'parentVoiceReminders': 'تذكيرات بصوت الوالدين',
        'enabled': 'مفعّل',
        'disabled': 'متوقف',
        'saveChildProfile': 'حفظ ملف الطفل',
        'completeRequiredFields': 'أدخل الاسم وتاريخ الميلاد والنوع للمتابعة.',
        'changePin': 'تغيير الرقم السري',
        'accessibilitySettings': 'إعدادات إمكانية الوصول',
        'close': 'إغلاق',
        'enabledAppBlocking': 'مفعّلة - حظر التطبيقات نشط',
        'disabledAppBlocking': 'معطّلة - فعّلها لحظر التطبيقات',
        'registerSuccess': 'تم التسجيل وربط الملف الشخصي بنجاح.',
        'registerFailedLocalMode':
          'التسجيل غير متاح الآن. تم حفظ الملف محليا وسيستمر التطبيق بشكل طبيعي.',
        'profileSavedLocalOnly':
          'تم حفظ الملف محليا. يمكنك التسجيل لاحقا في أي وقت.',
        'reportSubmittedOrQueued':
          'تم إرسال التقرير (أو وضعه في الانتظار عند عدم الاتصال).',
        'reportSavedLocally':
          'تم حفظ التقرير محليا. سجل لاحقا لمزامنته مع حسابك.',
          'registerWithGoogle': 'المتابعة باستخدام Google',
          'registerWithFacebook': 'المتابعة باستخدام Facebook',
          'registerWithApple': 'المتابعة باستخدام Apple',
          'socialSignInFailed':
            'تعذر إكمال تسجيل الدخول الاجتماعي. حاول مرة أخرى أو استخدم التسجيل بالبريد الإلكتروني.',
          'socialMissingEmail':
            'هذا الحساب الاجتماعي لم يزوّد بريدا إلكترونيا. يرجى التسجيل بالبريد وكلمة المرور.',
          'cancel': 'إلغاء',
          'openSettings': 'فتح الإعدادات',
          'noThanks': 'لا، شكرًا',
          'agree': 'موافق',
          'parentUnlock': 'فتح القفل بواسطة الوالد',
          'adjustLimit': 'تعديل الحد',
          'adjustDailyLimit': 'تعديل الحد اليومي',
          'accessibilityServiceRequired': 'مطلوب تفعيل خدمة إمكانية الوصول',
          'enableAppBlocking': 'تفعيل حظر التطبيقات',
          'pinUpdated': 'تم تحديث الرمز السري بنجاح',
          'pinsDoNotMatch': 'الرمزان غير متطابقين. حاول مرة أخرى.',
          'incorrectPin': 'الرمز السري غير صحيح. حاول مرة أخرى.',
          'pinLockedMinutes': 'محاولات كثيرة. أعد المحاولة بعد {value} دقيقة.',
          'pinLockedSeconds': 'محاولات كثيرة. أعد المحاولة بعد {value} ثانية.',
          'scheduleSaved': 'تم حفظ الجدول بنجاح',
          'scheduleSettings': 'إعدادات الجدول',
          'enableSchedule': 'تفعيل الجدول',
          'startTime': 'وقت البداية',
          'endTime': 'وقت النهاية',
          'differentWeekendRules': 'قواعد مختلفة لعطلة نهاية الأسبوع',
          'scheduleEnableSubtitle': 'تُطبّق القيود خلال الساعات المجدولة فقط',
          'activeDays': 'الأيام النشطة',
          'timeRange': 'الفترة الزمنية',
          'weekendTimeRange': 'فترة عطلة نهاية الأسبوع',
          'weekendRulesSubtitle': 'استخدم قيودًا زمنية مختلفة لعطلة نهاية الأسبوع',
          'restrictionsActive': 'القيود مفعّلة',
          'restrictionsInactive': 'القيود غير مفعّلة',
          'restrictionsEnforced': 'قيود التطبيقات مطبّقة الآن',
          'restrictionsNotActive': 'قيود التطبيقات غير نشطة',
          'dayMon': 'الإثنين',
          'dayTue': 'الثلاثاء',
          'dayWed': 'الأربعاء',
          'dayThu': 'الخميس',
          'dayFri': 'الجمعة',
          'daySat': 'السبت',
          'daySun': 'الأحد',
          'country_SA': 'السعودية',
          'country_EG': 'مصر',
          'country_AE': 'الإمارات',
          'country_KW': 'الكويت',
          'country_QA': 'قطر',
          'country_BH': 'البحرين',
          'country_IQ': 'العراق',
          'country_LB': 'لبنان',
          'country_JO': 'الأردن',
          'country_SY': 'سوريا',
          'country_SD': 'السودان',
          'country_TN': 'تونس',
          'country_DZ': 'الجزائر',
          'country_MA': 'المغرب',
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
  String get requestExtraTime => _text('requestExtraTime');
  String get requestPending => _text('requestPending');
  String get reviewExtraTimeRequest => _text('reviewExtraTimeRequest');
  String get approve => _text('approve');
  String get decline => _text('decline');
  String get requestSent => _text('requestSent');
  String requestForChild(String child) => _text('requestForChild').replaceAll('{child}', child);
  String pendingRequestCount(int count) => _text('pendingRequestCount').replaceAll('{count}', '$count');
  String durationMinutes(int minutes) => _text('durationMinutes').replaceAll('{minutes}', '$minutes');
  String tokensAvailable(int count) => _text('tokensAvailable').replaceAll('{count}', '$count');
  String get overlayPermissionTitle =>
      _text('overlayPermissionTitle');
  String get overlayPermissionBody =>
      _text('overlayPermissionBody');
  String get notNow => _text('notNow');
  String get continueLabel => _text('continue');
  String get usageAccessTitle => _text('usageAccessTitle');
  String get usageAccessBody => _text('usageAccessBody');
  String get gotIt => _text('gotIt');
  String get countryProfileTitle => _text('countryProfileTitle');
  String get countryProfileHint => _text('countryProfileHint');
  String get countryProfileCountryLabel => _text('countryProfileCountryLabel');
  String get save => _text('save');
  String get countryProfileCardTitle => _text('countryProfileCardTitle');
  String get registerTitle => _text('registerTitle');
  String get registerButton => _text('registerButton');
  String get submitReportButton => _text('submitReportButton');
  String get firstNameLabel => _text('firstNameLabel');
  String get lastNameLabel => _text('lastNameLabel');
  String get emailLabel => _text('emailLabel');
  String get passwordLabel => _text('passwordLabel');
  String get phoneLabel => _text('phoneLabel');
  String get languageLabel => _text('languageLabel');
  String get settings => _text('settings');
  String get languageSettings => _text('languageSettings');
  String get english => _text('english');
  String get arabic => _text('arabic');
  String get languageChanged => _text('languageChanged');
  String get parentalControls => _text('parentalControls');
  String get privacyPolicy => _text('privacyPolicy');
  String get privacyAccountTitle => _text('privacyAccountTitle');
  String get privacyAccountSummary => _text('privacyAccountSummary');
  String get accountDeletionTitle => _text('accountDeletionTitle');
  String get accountDeletionBody => _text('accountDeletionBody');
  String get requestAccountDeletion => _text('requestAccountDeletion');
  String get accountDeletionEmailSubject =>
      _text('accountDeletionEmailSubject');
  String get accountDeletionEmailBody => _text('accountDeletionEmailBody');
  String get externalLinkFailed => _text('externalLinkFailed');
  String get firstChildSetupTitle => _text('firstChildSetupTitle');
  String get firstChildSetupIntro => _text('firstChildSetupIntro');
  String get childName => _text('childName');
  String get birthDate => _text('birthDate');
  String get gender => _text('gender');
  String get chooseBirthDate => _text('chooseBirthDate');
  String get chooseGender => _text('chooseGender');
  String get boy => _text('boy');
  String get girl => _text('girl');
  String get unspecified => _text('unspecified');
  String get recommendedProfile => _text('recommendedProfile');
  String get dailyBudget => _text('dailyBudget');
  String get socialBudget => _text('socialBudget');
  String get gamesBudget => _text('gamesBudget');
  String get sleepSchedule => _text('sleepSchedule');
  String get prayerLock => _text('prayerLock');
  String get matureContentBlock => _text('matureContentBlock');
  String get parentApproval => _text('parentApproval');
  String get parentVoiceReminders => _text('parentVoiceReminders');
  String get enabled => _text('enabled');
  String get disabled => _text('disabled');
  String get saveChildProfile => _text('saveChildProfile');
  String get completeRequiredFields => _text('completeRequiredFields');
  String get changePin => _text('changePin');
  String get accessibilitySettings => _text('accessibilitySettings');
  String get close => _text('close');
  String get enabledAppBlocking => _text('enabledAppBlocking');
  String get disabledAppBlocking => _text('disabledAppBlocking');
  String get registerSuccess => _text('registerSuccess');
  String get registerFailedLocalMode => _text('registerFailedLocalMode');
  String get profileSavedLocalOnly => _text('profileSavedLocalOnly');
  String get reportSubmittedOrQueued => _text('reportSubmittedOrQueued');
  String get reportSavedLocally => _text('reportSavedLocally');
  String get registerWithGoogle => _text('registerWithGoogle');
  String get registerWithFacebook => _text('registerWithFacebook');
  String get registerWithApple => _text('registerWithApple');
  String get socialSignInFailed => _text('socialSignInFailed');
  String get socialMissingEmail => _text('socialMissingEmail');
  String get cancel => _text('cancel');
  String get openSettings => _text('openSettings');
  String get noThanks => _text('noThanks');
  String get agree => _text('agree');
  String get parentUnlock => _text('parentUnlock');
  String get adjustLimit => _text('adjustLimit');
  String get adjustDailyLimit => _text('adjustDailyLimit');
  String get accessibilityServiceRequired => _text('accessibilityServiceRequired');
  String get enableAppBlocking => _text('enableAppBlocking');
  String get pinUpdated => _text('pinUpdated');
  String get pinsDoNotMatch => _text('pinsDoNotMatch');
  String get incorrectPin => _text('incorrectPin');
  String pinLockedMinutes(int value) => _text('pinLockedMinutes').replaceAll('{value}', '$value');
  String pinLockedSeconds(int value) => _text('pinLockedSeconds').replaceAll('{value}', '$value');
  String get scheduleSaved => _text('scheduleSaved');
  String get scheduleSettings => _text('scheduleSettings');
  String get enableSchedule => _text('enableSchedule');
  String get startTime => _text('startTime');
  String get endTime => _text('endTime');
  String get differentWeekendRules => _text('differentWeekendRules');
  String get scheduleEnableSubtitle => _text('scheduleEnableSubtitle');
  String get activeDays => _text('activeDays');
  String get timeRange => _text('timeRange');
  String get weekendTimeRange => _text('weekendTimeRange');
  String get weekendRulesSubtitle => _text('weekendRulesSubtitle');
  String get restrictionsActive => _text('restrictionsActive');
  String get restrictionsInactive => _text('restrictionsInactive');
  String get restrictionsEnforced => _text('restrictionsEnforced');
  String get restrictionsNotActive => _text('restrictionsNotActive');
  String get dayMon => _text('dayMon');
  String get dayTue => _text('dayTue');
  String get dayWed => _text('dayWed');
  String get dayThu => _text('dayThu');
  String get dayFri => _text('dayFri');
  String get daySat => _text('daySat');
  String get daySun => _text('daySun');
  /// Country codes offered in the registration dialog, in display order.
  static const List<String> countryCodes = <String>[
    'SA', 'EG', 'AE', 'KW', 'QA', 'BH', 'IQ', 'LB', 'JO', 'SY', 'SD', 'TN', 'DZ', 'MA',
  ];

  @visibleForTesting
  static Map<String, String> valuesFor(String languageCode) =>
      Map<String, String>.unmodifiable(_localizedValues[languageCode] ?? const <String, String>{});

  String countryName(String code) => _text('country_$code');

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

  String countryProfileSaved({required String country, required String word}) {
    String template = _text('countryProfileSaved');
    template = template.replaceAll('{country}', country);
    template = template.replaceAll('{word}', word);
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


